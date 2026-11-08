// FR-BE-02: POST /reports (multipart: foto, jenis_saluran, lat, lng, captured_at). Token opsional (FR-BE-01 menyusul).
// Validasi lengkap (umur foto, lokasi palsu) = FR-BE-03, menyusul.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const express = require('express');
const multer = require('multer');
const db = require('../db');
const { httpError } = require('../errors');
const { cariAtauBuatSaluran } = require('../saluran');

const router = express.Router();

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const JENIS = ['terbuka', 'gorong_gorong', 'inlet_jalan'];
const KELAS = ['bersih', 'ringan', 'sedang', 'berat', 'tidak_terlihat'];
const KEYAKINAN = ['rendah', 'sedang', 'tinggi'];
const EKSTENSI = { 'image/jpeg': '.jpg', 'image/png': '.png' };

const upload = multer({
  storage: multer.diskStorage({
    destination: UPLOAD_DIR,
    filename: (req, file, cb) =>
      cb(null, `${Date.now()}-${crypto.randomBytes(4).toString('hex')}${EKSTENSI[file.mimetype]}`),
  }),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) =>
    EKSTENSI[file.mimetype] ? cb(null, true) : cb(httpError(400, 'Foto harus JPEG atau PNG')),
});

function terimaFoto(req, res, next) {
  upload.single('foto')(req, res, (err) => {
    if (!err) return next();
    if (err.code === 'LIMIT_FILE_SIZE') return next(httpError(400, 'Ukuran foto maksimal 10 MB'));
    if (err instanceof multer.MulterError) return next(httpError(400, 'Unggahan foto tidak valid'));
    next(err);
  });
}

// Pakai modul AI milik C (backend/src/ai). Kalau belum ada → stub demo agar alur tetap jalan.
function stubAi() {
  return {
    ok: true,
    sumber: 'demo',
    result: { saluran_terlihat: true, kelas_sumbatan: 'berat', skor_sumbatan: 0.85, keyakinan: 'tinggi', penyebab: ['plastik'], catatan: 'STUB backend (modul AI belum ada)' },
  };
}

async function nilaiFoto(filePath, mimeType, jenisSaluran) {
  let ai;
  try {
    ai = require('../ai');
  } catch (err) {
    if (err.code !== 'MODULE_NOT_FOUND') console.error('Modul AI gagal dimuat:', err.message);
    return stubAi();
  }
  if (typeof ai.analyzeReport !== 'function') return stubAi();
  try {
    const foto = await fs.promises.readFile(filePath);
    return await ai.analyzeReport({ foto, mimeType, jenisSaluran });
  } catch (err) {
    console.error('AI error:', err.message);
    return { ok: false, alasan: 'error' };
  }
}

// Hasil AI → kolom laporan. AI gagal → laporan tetap disimpan, status cek_manual.
function dariHasilAi(hasil) {
  const gagal = (alasan) => ({
    ai_json: { alasan: alasan || 'gagal' },
    ai_sumber: 'gagal',
    kelas: 'tidak_terlihat',
    skor_sumbatan: null,
    keyakinan: 'rendah',
    status: 'cek_manual',
  });
  if (!hasil || !hasil.ok || !hasil.result) return gagal(hasil && hasil.alasan);

  const r = hasil.result;
  // Keluaran AI (docs/API.md): kelas_sumbatan + saluran_terlihat
  const kelasAi = r.kelas_sumbatan ?? r.kelas;
  const kelas = r.saluran_terlihat === false || !KELAS.includes(kelasAi) ? 'tidak_terlihat' : kelasAi;
  let skor = null;
  if (kelas !== 'tidak_terlihat') {
    skor = Number(r.skor_sumbatan);
    if (r.skor_sumbatan == null || !Number.isFinite(skor)) return gagal('skor_tidak_valid');
    skor = Math.min(Math.max(skor, 0), 1);
  }
  return {
    ai_json: r,
    ai_sumber: hasil.sumber === 'demo' ? 'demo' : 'model',
    kelas,
    skor_sumbatan: skor,
    keyakinan: KEYAKINAN.includes(r.keyakinan) ? r.keyakinan : 'rendah',
    status: kelas === 'tidak_terlihat' ? 'cek_manual' : 'dikirim',
  };
}

router.post('/', terimaFoto, async (req, res) => {
  if (!req.file) throw httpError(400, 'Foto wajib dikirim (field "foto")');
  const hapusFoto = () => fs.promises.unlink(req.file.path).catch(() => {});

  const jenis = req.body.jenis_saluran;
  const lat = Number(req.body.lat);
  const lng = Number(req.body.lng);
  const capturedAt = req.body.captured_at ? new Date(req.body.captured_at) : new Date();

  let salah = null;
  if (!JENIS.includes(jenis)) salah = 'jenis_saluran harus terbuka, gorong_gorong, atau inlet_jalan';
  else if (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng < -180 || lng > 180)
    salah = 'lat/lng tidak valid';
  else if (Number.isNaN(capturedAt.getTime())) salah = 'captured_at harus waktu ISO 8601';
  if (salah) {
    await hapusFoto();
    throw httpError(400, salah);
  }

  const saluran = await cariAtauBuatSaluran({ lat, lng, jenis });
  const ai = dariHasilAi(await nilaiFoto(req.file.path, req.file.mimetype, jenis));
  const fotoUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
  const pelaporId = req.user ? req.user.id : null; // diisi setelah middleware auth (FR-BE-01)

  const { rows } = await db.query(
    `INSERT INTO laporan (saluran_id, pelapor_id, jenis_saluran, foto_url, geom, captured_at,
       ai_json, ai_sumber, kelas, skor_sumbatan, keyakinan, status)
     VALUES ($1, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $6), 4326)::geography, $7, $8, $9, $10, $11, $12, $13)
     RETURNING id, created_at`,
    [saluran.id, pelaporId, jenis, fotoUrl, lng, lat, capturedAt.toISOString(),
      ai.ai_json, ai.ai_sumber, ai.kelas, ai.skor_sumbatan, ai.keyakinan, ai.status]
  );

  res.status(201).json({
    id: rows[0].id,
    saluran_id: saluran.id,
    saluran_baru: saluran.baru,
    rw_id: saluran.rw_id,
    jenis_saluran: jenis,
    foto_url: fotoUrl,
    lokasi: { type: 'Point', coordinates: [lng, lat] },
    captured_at: capturedAt.toISOString(),
    kelas: ai.kelas,
    skor_sumbatan: ai.skor_sumbatan,
    keyakinan: ai.keyakinan,
    penyebab: Array.isArray(ai.ai_json.penyebab) ? ai.ai_json.penyebab : [],
    ai_sumber: ai.ai_sumber,
    status: ai.status,
    created_at: rows[0].created_at,
  });
});

module.exports = router;
