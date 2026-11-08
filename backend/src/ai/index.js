// Modul AI vision RIVORA. Pemilik: C (AI dan dasbor). Antarmuka: SRS backend bagian 10.
//
// analyzeReport / verifyCleaning memanggil Claude (Anthropic API) dengan keluaran JSON terstruktur,
// lalu memvalidasinya (validasi.js). Batas 20 detik per panggilan, ulang 1 kali bila gagal.
// Gagal dua kali: DEMO_MODE=1 -> hasil contoh bergiliran (sumber 'demo', FR-BE-19),
// selain itu { ok: false, alasan } supaya backend menandai laporan cek_manual (FR-BE-06).
//
// Env: AI_API_KEY (kunci Anthropic), AI_MODEL (bawaan claude-opus-5-5), DEMO_MODE.

const sdk = require('@anthropic-ai/sdk')
const { validasiLaporan, validasiVerifikasi, JENIS, KELAS, PENYEBAB, KEYAKINAN } = require('./validasi')
const { contohLaporan, contohVerifikasi } = require('./contoh')

const Anthropic = sdk.default ?? sdk
const BATAS_MS = 20_000
const PERCOBAAN = 2

const SKEMA_LAPORAN = {
  type: 'object',
  properties: {
    jenis_saluran: { type: 'string', enum: JENIS },
    saluran_terlihat: { type: 'boolean' },
    kelas_sumbatan: { type: 'string', enum: KELAS },
    skor_sumbatan: { anyOf: [{ type: 'number' }, { type: 'null' }] },
    penyebab: { type: 'array', items: { type: 'string', enum: PENYEBAB } },
    keyakinan: { type: 'string', enum: KEYAKINAN },
    catatan: { type: 'string' },
  },
  required: ['jenis_saluran', 'saluran_terlihat', 'kelas_sumbatan', 'skor_sumbatan', 'penyebab', 'keyakinan', 'catatan'],
  additionalProperties: false,
}

const SKEMA_VERIFIKASI = {
  type: 'object',
  properties: {
    sudah_bersih: { type: 'boolean' },
    kelas_sesudah: { type: 'string', enum: KELAS },
    skor_sumbatan_sesudah: { anyOf: [{ type: 'number' }, { type: 'null' }] },
    keyakinan: { type: 'string', enum: KEYAKINAN },
    catatan: { type: 'string' },
  },
  required: ['sudah_bersih', 'kelas_sesudah', 'skor_sumbatan_sesudah', 'keyakinan', 'catatan'],
  additionalProperties: false,
}

const SKALA = `Kelas sumbatan dan rentang skor_sumbatan (0 sampai 1, makin besar makin tersumbat):
- bersih: 0 sampai 0,15. Aliran lancar, tidak ada sampah berarti.
- ringan: 0,15 sampai 0,40. Sedikit sampah atau endapan, aliran masih lancar.
- sedang: 0,40 sampai 0,70. Sekitar separuh lebar saluran tertutup.
- berat: 0,70 sampai 1. Sebagian besar saluran tertutup, air tertahan.
- tidak_terlihat: isi saluran tidak tampak (tertutup beton, gelap, foto buram, atau bukan foto saluran). skor_sumbatan null, penyebab kosong.
penyebab hanya dari: plastik, sedimen, daun_ranting, puing. Kosongkan bila bersih.
keyakinan: tinggi bila foto jelas, sedang bila sebagian terhalang, rendah bila ragu.
catatan: satu kalimat bahasa Indonesia untuk lurah, sebut yang terlihat.`

const PROMPT_LAPOR = (jenis) => `Kamu menilai foto saluran drainase permukiman di Kota Bandung untuk aplikasi pencegahan genangan RIVORA.
Pelapor memilih jenis saluran: ${jenis}. Isi jenis_saluran sesuai yang terlihat di foto (terbuka, gorong_gorong, atau inlet_jalan).

${SKALA}

Nilai hanya dari yang terlihat. Jangan menebak isi bagian yang tidak tampak.`

const PROMPT_VERIFIKASI = `Kamu memverifikasi pembersihan saluran drainase untuk aplikasi RIVORA.
Gambar pertama adalah foto SEBELUM dibersihkan, gambar kedua foto SESUDAH dibersihkan oleh petugas.
Nilai kondisi pada foto SESUDAH. Pastikan kedua foto memperlihatkan saluran yang sama; bila jelas berbeda tempat, sudah_bersih false dan jelaskan di catatan.
sudah_bersih true hanya bila kelas_sesudah bersih atau ringan.
Isi kelas_sesudah dan skor_sumbatan_sesudah dengan skala berikut (nilai foto SESUDAH).

${SKALA}`

let klien = null
function ambilKlien() {
  if (module.exports._klien) return module.exports._klien // celah untuk ai.test.js
  if (!process.env.AI_API_KEY) return null
  klien ??= new Anthropic({ apiKey: process.env.AI_API_KEY, timeout: BATAS_MS, maxRetries: 0 })
  return klien
}

const gambar = (buf, mimeType) => ({
  type: 'image',
  source: { type: 'base64', media_type: mimeType || 'image/jpeg', data: buf.toString('base64') },
})

/** Satu panggilan model + validasi. Melempar Error bila gagal supaya bisa diulang. */
async function panggil(isi, skema, validasi) {
  const res = await ambilKlien().messages.create({
    model: process.env.AI_MODEL || 'claude-opus-5-5',
    max_tokens: 4000,
    output_config: { effort: 'low', format: { type: 'json_schema', schema: skema } },
    messages: [{ role: 'user', content: isi }],
  })
  if (res.stop_reason === 'refusal') throw new Error(`model menolak (${res.stop_details?.category ?? 'tanpa kategori'})`)
  if (res.stop_reason === 'max_tokens') throw new Error('keluaran terpotong (max_tokens)')
  const teks = res.content.find((b) => b.type === 'text')?.text
  if (!teks) throw new Error('model tidak mengembalikan teks')
  let data
  try {
    data = JSON.parse(teks)
  } catch {
    throw new Error('JSON tidak valid')
  }
  const v = validasi(data)
  if (!v.ok) throw new Error(`validasi gagal: ${v.alasan}`)
  return v.result
}

async function jalankan(nama, isi, skema, validasi, contoh) {
  const mulai = Date.now()
  let alasan = 'AI_API_KEY belum diisi'
  if (ambilKlien()) {
    for (let i = 1; i <= PERCOBAAN; i++) {
      try {
        const result = await panggil(isi, skema, validasi)
        console.log(`[ai] ${nama} sumber=model percobaan=${i} durasi=${Date.now() - mulai}ms`)
        return { ok: true, sumber: 'model', result }
      } catch (e) {
        alasan = e instanceof Anthropic.APIError ? `API ${e.status ?? 'koneksi'}: ${e.message}` : e.message
        console.warn(`[ai] ${nama} percobaan=${i} gagal: ${alasan}`)
      }
    }
  }
  if (process.env.DEMO_MODE === '1') {
    console.log(`[ai] ${nama} sumber=demo (${alasan}) durasi=${Date.now() - mulai}ms`)
    return { ok: true, sumber: 'demo', result: contoh() }
  }
  console.log(`[ai] ${nama} gagal (${alasan}) durasi=${Date.now() - mulai}ms`)
  return { ok: false, alasan }
}

/**
 * Menilai tingkat sumbatan dari foto saluran.
 * @param {{ foto: Buffer, mimeType: string, jenisSaluran: 'terbuka'|'gorong_gorong'|'inlet_jalan' }} input
 * @returns {Promise<{ ok: true, sumber: 'model'|'demo', result: object } | { ok: false, alasan: string }>}
 */
async function analyzeReport({ foto, mimeType, jenisSaluran }) {
  const isi = [gambar(foto, mimeType), { type: 'text', text: PROMPT_LAPOR(jenisSaluran) }]
  return jalankan('analyzeReport', isi, SKEMA_LAPORAN, validasiLaporan, () => contohLaporan(jenisSaluran))
}

/**
 * Membandingkan foto sebelum dan sesudah dibersihkan.
 * @param {{ fotoSebelum: Buffer, fotoSesudah: Buffer, mimeType: string }} input
 * @returns {Promise<{ ok: true, sumber: 'model'|'demo', result: object } | { ok: false, alasan: string }>}
 */
async function verifyCleaning({ fotoSebelum, fotoSesudah, mimeType }) {
  const isi = [
    { type: 'text', text: 'Foto SEBELUM:' },
    gambar(fotoSebelum, mimeType),
    { type: 'text', text: 'Foto SESUDAH:' },
    gambar(fotoSesudah, mimeType),
    { type: 'text', text: PROMPT_VERIFIKASI },
  ]
  return jalankan('verifyCleaning', isi, SKEMA_VERIFIKASI, validasiVerifikasi, contohVerifikasi)
}

module.exports = { analyzeReport, verifyCleaning, _klien: null }
