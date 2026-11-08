// FR-BE-14 POST /tasks (lurah) · FR-BE-15 FCM · GET /tasks · FR-BE-17 POST /tasks/:id/verify (petugas).
// Bentuk objek tugas: API 7.9 (src/tugas.js). Verify: API 7.10.
const fs = require('fs');
const path = require('path');
const express = require('express');
const db = require('../db');
const { httpError, ambilId } = require('../errors');
const { wajibLogin } = require('../auth');
const { cariTugas } = require('../tugas');
const { kirimTugasBaru } = require('../notify/fcm');
const { lokasiDemoDiminta, cadanganDemo } = require('../demo');
const { terimaFoto, cekLokasiWaktu, UPLOAD_DIR } = require('./reports');

const router = express.Router();

const STATUS_TUGAS = ['baru', 'dikerjakan', 'selesai'];
const KELAS = ['bersih', 'ringan', 'sedang', 'berat', 'tidak_terlihat'];
const KEYAKINAN = ['rendah', 'sedang', 'tinggi'];
const RADIUS_VERIFIKASI_M = 30;

const idBulat = (v) => (Number.isInteger(Number(v)) && Number(v) > 0 && String(v).trim() !== '' ? Number(v) : null);

// ---------- POST /tasks (FR-BE-14/15) ----------
router.post('/', wajibLogin('lurah'), async (req, res) => {
  const body = req.body || {};
  const saluranId = idBulat(body.saluran_id);
  const petugasId = idBulat(body.petugas_id);
  if (!saluranId || !petugasId) throw httpError(400, 'saluran_id dan petugas_id wajib berupa id angka');
  if (body.catatan != null && (typeof body.catatan !== 'string' || body.catatan.length > 500)) {
    throw httpError(400, 'catatan harus teks maksimal 500 karakter');
  }
  const catatan = body.catatan && body.catatan.trim() ? body.catatan.trim() : null;

  const p = await db.query("SELECT id FROM pengguna WHERE id = $1 AND role = 'petugas'", [petugasId]);
  if (!p.rows[0]) throw httpError(400, 'petugas_id bukan akun petugas');

  const s = await db.query('SELECT id FROM saluran WHERE id = $1', [saluranId]);
  if (!s.rows[0]) throw httpError(404, 'Saluran tidak ditemukan');

  // Laporan warga/petugas terbaru di saluran ini = "foto sebelum"
  const l = await db.query(
    `SELECT id FROM laporan WHERE saluran_id = $1 AND sumber = 'laporan'
     ORDER BY captured_at DESC, id DESC LIMIT 1`,
    [saluranId]
  );
  if (!l.rows[0]) throw httpError(400, 'Saluran ini belum punya laporan');
  const laporanId = l.rows[0].id;

  let tugasId;
  try {
    const ins = await db.query(
      `INSERT INTO tugas (saluran_id, laporan_id, petugas_id, ditugaskan_oleh, catatan)
       VALUES ($1, $2, $3, $4, $5) RETURNING id`,
      [saluranId, laporanId, petugasId, req.user.id, catatan]
    );
    tugasId = ins.rows[0].id;
  } catch (err) {
    // index unik tugas_aktif_per_saluran
    if (err.code === '23505') throw httpError(409, 'Saluran ini sudah punya tugas yang belum selesai');
    throw err;
  }
  await db.query(
    "UPDATE laporan SET status = 'ditugaskan' WHERE id = $1 AND status IN ('dikirim', 'cek_manual')",
    [laporanId]
  );

  const [tugas] = await cariTugas('WHERE t.id = $1', [tugasId]);
  let notifikasi;
  try {
    notifikasi = await kirimTugasBaru(petugasId, tugas);
  } catch (err) {
    console.error('Notifikasi gagal:', err.message);
    notifikasi = 'gagal';
  }
  res.status(201).json({ tugas, notifikasi });
});

// ---------- GET /tasks ----------
// Petugas: tugas miliknya. Lurah: semua tugas di kelurahannya. ?status=baru|dikerjakan|selesai (opsional)
router.get('/', wajibLogin('lurah', 'petugas'), async (req, res) => {
  const syarat = [];
  const params = [];
  if (req.user.role === 'petugas') {
    params.push(req.user.id);
    syarat.push(`t.petugas_id = $${params.length}`);
  } else if (req.user.kelurahan_id) {
    params.push(req.user.kelurahan_id);
    syarat.push(`(rw.kelurahan_id = $${params.length} OR rw.id IS NULL)`);
  }
  if (req.query.status != null) {
    if (!STATUS_TUGAS.includes(req.query.status)) throw httpError(400, 'status harus baru, dikerjakan, atau selesai');
    params.push(req.query.status);
    syarat.push(`t.status = $${params.length}`);
  }
  res.json(await cariTugas(syarat.length ? `WHERE ${syarat.join(' AND ')}` : '', params));
});

// ---------- POST /tasks/:id/verify (FR-BE-17) ----------
// Multipart: foto (sesudah), lat, lng, captured_at. [ASUMSI] lat/lng/captured_at wajib seperti POST /reports
// (dibutuhkan untuk radius 30 m). lokasi_demo=true + DEMO_MODE → radius dilewati (FR-BE-21).

async function nilaiVerifikasi(fotoSebelumUrl, fileSesudah) {
  let hasil;
  try {
    const ai = require('../ai');
    if (typeof ai.verifyCleaning !== 'function') throw new Error('verifyCleaning tidak ada');
    // foto_url absolut → file lokal di uploads/
    const namaFile = path.basename(new URL(fotoSebelumUrl).pathname);
    let fotoSebelum;
    try {
      fotoSebelum = await fs.promises.readFile(path.join(UPLOAD_DIR, namaFile));
    } catch (e) {
      // file tidak ada di server ini (mis. laporan dibuat dari laptop) → ambil lewat URL
      const r = await fetch(fotoSebelumUrl, { signal: AbortSignal.timeout(10000) });
      if (!r.ok) throw new Error(`foto sebelum tidak bisa diambil (${r.status})`);
      fotoSebelum = Buffer.from(await r.arrayBuffer());
    }
    const fotoSesudah = await fs.promises.readFile(fileSesudah.path);
    hasil = await ai.verifyCleaning({ fotoSebelum, fotoSesudah, mimeType: fileSesudah.mimetype });
  } catch (err) {
    console.error('AI verifikasi error:', err.message);
    hasil = { ok: false, alasan: 'error' };
  }
  return cadanganDemo(hasil, 'verifikasi'); // FR-BE-19
}

// Hasil AI → objek verifikasi API 7.10 + kolom laporan verifikasi
function dariHasilVerifikasi(hasil) {
  const gagal = (alasan) => ({
    ok: false,
    ai_sumber: 'gagal',
    ai_json: { alasan: alasan || 'gagal' },
    verifikasi: {
      sudah_bersih: false,
      kelas_sesudah: 'tidak_terlihat',
      skor_sumbatan_sesudah: null,
      keyakinan: 'rendah',
      catatan: 'Penilaian AI gagal, perlu dicek manual oleh lurah',
    },
  });
  if (!hasil || !hasil.ok || !hasil.result) return gagal(hasil && hasil.alasan);
  const r = hasil.result;
  const kelas = KELAS.includes(r.kelas_sesudah) ? r.kelas_sesudah : 'tidak_terlihat';
  let skor = null;
  if (kelas !== 'tidak_terlihat') {
    skor = Number(r.skor_sumbatan_sesudah);
    if (r.skor_sumbatan_sesudah == null || !Number.isFinite(skor)) return gagal('skor_tidak_valid');
    skor = Math.min(Math.max(skor, 0), 1);
  }
  return {
    ok: true,
    ai_sumber: hasil.sumber === 'demo' ? 'demo' : 'model',
    ai_json: r,
    verifikasi: {
      // tidak_terlihat tidak pernah dianggap bersih
      sudah_bersih: kelas !== 'tidak_terlihat' && r.sudah_bersih === true,
      kelas_sesudah: kelas,
      skor_sumbatan_sesudah: skor,
      keyakinan: KEYAKINAN.includes(r.keyakinan) ? r.keyakinan : 'rendah',
      catatan: typeof r.catatan === 'string' ? r.catatan : '',
    },
  };
}

router.post('/:id/verify', wajibLogin('petugas'), terimaFoto, async (req, res) => {
  const tolak = async (status, pesan) => {
    if (req.file) await fs.promises.unlink(req.file.path).catch(() => {});
    throw httpError(status, pesan);
  };
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) await tolak(400, 'id tidak valid');
  if (!req.file) await tolak(400, 'Foto sesudah wajib dikirim (field "foto")');
  const salah = cekLokasiWaktu(req.body);
  if (salah) await tolak(400, salah);

  const lat = Number(req.body.lat);
  const lng = Number(req.body.lng);
  const { rows } = await db.query(
    `SELECT t.id, t.status, t.petugas_id, t.laporan_id, t.saluran_id, s.jenis, l.foto_url AS foto_sebelum,
       ST_Distance(s.geom, ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography) AS jarak_m
     FROM tugas t JOIN saluran s ON s.id = t.saluran_id JOIN laporan l ON l.id = t.laporan_id
     WHERE t.id = $1`,
    [id, lng, lat]
  );
  const t = rows[0];
  if (!t) await tolak(404, 'Tugas tidak ditemukan');
  if (t.petugas_id !== req.user.id) await tolak(403, 'Tugas ini bukan milikmu');
  if (t.status === 'selesai') await tolak(409, 'Tugas ini sudah selesai');

  const lokasiDemo = lokasiDemoDiminta(req.body);
  if (!lokasiDemo && t.jarak_m > RADIUS_VERIFIKASI_M) {
    await tolak(400, `Kamu berjarak ${Math.round(t.jarak_m)} m dari saluran. Dekati saluran (maks ${RADIUS_VERIFIKASI_M} m) lalu foto ulang`);
  }

  const v = dariHasilVerifikasi(await nilaiVerifikasi(t.foto_sebelum, req.file));
  const fotoUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;

  // Kondisi baru saluran = laporan sumber 'verifikasi' → skor RW ikut turun
  const lv = await db.query(
    `INSERT INTO laporan (saluran_id, pelapor_id, sumber, jenis_saluran, foto_url, geom, lokasi_demo, captured_at,
       ai_json, ai_sumber, kelas, skor_sumbatan, keyakinan, status)
     VALUES ($1, $2, 'verifikasi', $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326)::geography, $7, $8,
       $9, $10, $11, $12, $13, $14)
     RETURNING id`,
    [t.saluran_id, req.user.id, t.jenis, fotoUrl, lng, lat, lokasiDemo, new Date(req.body.captured_at).toISOString(),
      v.ai_json, v.ai_sumber, v.verifikasi.kelas_sesudah, v.verifikasi.skor_sumbatan_sesudah,
      v.verifikasi.keyakinan, v.ok ? 'ditangani' : 'cek_manual']
  );

  // [ASUMSI] belum bersih / AI gagal → tugas tetap aktif (status dikerjakan), petugas bisa verifikasi ulang
  const selesai = v.verifikasi.sudah_bersih;
  const upd = await db.query(
    `UPDATE tugas SET status = $2, foto_sesudah_url = $3, ai_verifikasi_json = $4, laporan_verifikasi_id = $5,
       selesai_at = CASE WHEN $2 = 'selesai' THEN now() ELSE NULL END
     WHERE id = $1 AND status <> 'selesai' RETURNING id`,
    [id, selesai ? 'selesai' : 'dikerjakan', fotoUrl, { ...v.verifikasi, ai_sumber: v.ai_sumber }, lv.rows[0].id]
  );
  if (!upd.rows[0]) throw httpError(409, 'Tugas ini sudah selesai'); // verifikasi ganda bersamaan
  if (selesai) await db.query("UPDATE laporan SET status = 'ditangani' WHERE id = $1", [t.laporan_id]);

  const [tugas] = await cariTugas('WHERE t.id = $1', [id]);
  res.json({ tugas, verifikasi: v.verifikasi, ai_sumber: v.ai_sumber });
});

module.exports = router;
