// Fitur [DEMO] (FR-BE-19/20/21). Semua hanya aktif bila DEMO_MODE=1 dan wajib dilabeli di UI.
// FR-BE-19 [ASUMSI]: AI gagal → pakai hasil contoh (ai_sumber 'demo') agar demo tidak macet.
// FR-BE-21 [ASUMSI]: klien kirim lokasi_demo=true → laporan/verifikasi dipasang ke saluran DEMO_SALURAN_ID
//   (posisi asli HP tetap disimpan di laporan.geom, kolom lokasi_demo = true, radius 30 m dilewati).
const db = require('./db');
const { httpError } = require('./errors');

const demoAktif = () => process.env.DEMO_MODE === '1';

const BENAR = ['true', '1', 'yes'];
const lokasiDemoDiminta = (body) =>
  demoAktif() && BENAR.includes(String((body && body.lokasi_demo) ?? '').toLowerCase());

async function saluranDemo() {
  const id = Number(process.env.DEMO_SALURAN_ID);
  if (!Number.isInteger(id) || id <= 0) throw httpError(500, 'DEMO_SALURAN_ID belum diisi di server');
  const { rows } = await db.query('SELECT id FROM saluran WHERE id = $1', [id]);
  if (!rows[0]) throw httpError(500, 'DEMO_SALURAN_ID tidak ada di database');
  return rows[0].id;
}

// FR-BE-19: dipanggil sesudah AI. Hasil gagal + DEMO_MODE → contoh dari modul C.
function cadanganDemo(hasil, jenis) {
  if ((hasil && hasil.ok) || !demoAktif()) return hasil;
  const contoh = require('./ai/contoh');
  const result = jenis === 'verifikasi' ? contoh.contohVerifikasi() : contoh.contohLaporan(jenis);
  console.warn(`[demo] AI gagal (${hasil && hasil.alasan}), pakai hasil contoh`);
  return { ok: true, sumber: 'demo', result };
}

module.exports = { demoAktif, lokasiDemoDiminta, saluranDemo, cadanganDemo };
