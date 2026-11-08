// Modul AI vision RIVORA. Pemilik: C (AI dan dasbor). Antarmuka: SRS backend bagian 10.
//
// STATUS: STUB. Belum memanggil model. Kedua fungsi langsung mengembalikan hasil contoh
// (format Lampiran C) dengan sumber: 'demo', supaya backend bisa menyelesaikan
// POST /reports dan POST /tasks/:id/verify tanpa menunggu modul asli.
// Antarmuka ini tidak akan berubah saat modul asli dipasang.

const { contohLaporan, contohVerifikasi } = require('./contoh')

/**
 * Menilai tingkat sumbatan dari foto saluran.
 * @param {{ foto: Buffer, mimeType: string, jenisSaluran: 'terbuka'|'gorong_gorong'|'inlet_jalan' }} input
 * @returns {Promise<{ ok: true, sumber: 'model'|'demo', result: object } | { ok: false, alasan: string }>}
 */
async function analyzeReport(input) {
  const mulai = Date.now()
  const result = contohLaporan(input?.jenisSaluran)
  console.log(`[ai] analyzeReport sumber=demo (stub) durasi=${Date.now() - mulai}ms`)
  return { ok: true, sumber: 'demo', result }
}

/**
 * Membandingkan foto sebelum dan sesudah dibersihkan.
 * @param {{ fotoSebelum: Buffer, fotoSesudah: Buffer, mimeType: string }} input
 * @returns {Promise<{ ok: true, sumber: 'model'|'demo', result: object } | { ok: false, alasan: string }>}
 */
// eslint-disable-next-line no-unused-vars
async function verifyCleaning(input) {
  const mulai = Date.now()
  const result = contohVerifikasi()
  console.log(`[ai] verifyCleaning sumber=demo (stub) durasi=${Date.now() - mulai}ms`)
  return { ok: true, sumber: 'demo', result }
}

module.exports = { analyzeReport, verifyCleaning }
