// Label enum, warna, dan format angka/waktu. Sumber: SRS dasbor bagian 8.

// Warna kelas sumbatan = aplikasi mobile (mobile/lib/widgets/sumbatan_style.dart)
export const KELAS = {
  bersih: { label: 'Bersih', warna: '#43A047' },
  ringan: { label: 'Sumbatan ringan', warna: '#9E9D24' },
  sedang: { label: 'Sumbatan sedang', warna: '#F57C00' },
  berat: { label: 'Sumbatan berat', warna: '#D32F2F' },
  tidak_terlihat: { label: 'Tidak terlihat', warna: '#607D8B' },
}

export const LEVEL = {
  aman: { label: 'Aman', warna: '#43A047', isi: 0.3, ikon: 'cek' },
  waspada: { label: 'Waspada', warna: '#F57C00', isi: 0.35, ikon: 'seru' },
  risiko_tinggi: { label: 'Risiko tinggi', warna: '#D32F2F', isi: 0.4, ikon: 'segitiga' },
}
export const BELUM_ADA_DATA = { label: 'Belum ada data', warna: '#9E9E9E', isi: 0.15, ikon: 'tanya' }

export const WARNA_DITUGASKAN = '#1E63D6'

export const JENIS = {
  terbuka: 'Saluran terbuka',
  gorong_gorong: 'Gorong-gorong',
  inlet_jalan: 'Inlet jalan',
}

export const PENYEBAB = {
  plastik: 'Plastik',
  sedimen: 'Sedimen',
  daun_ranting: 'Daun & ranting',
  puing: 'Puing',
}

export const KEYAKINAN = { rendah: 'Rendah', sedang: 'Sedang', tinggi: 'Tinggi' }

export const STATUS_TUGAS = { baru: 'Baru', dikerjakan: 'Dikerjakan', selesai: 'Selesai' }

export const STATUS_LAPORAN = {
  dikirim: 'Belum ditugaskan',
  ditugaskan: 'Ditugaskan',
  ditangani: 'Sudah ditangani',
  cek_manual: 'Perlu cek manual',
}

export const SUMBER_HUJAN = {
  open_meteo: 'Open-Meteo',
  cache: 'Open-Meteo (data tersimpan)',
  tidak_tersedia: 'Prakiraan tidak tersedia',
  simulasi_demo: 'Simulasi demo',
}

/** Info level RW, termasuk "belum ada data" bila sumbatan belum punya laporan. */
export function infoLevel(props) {
  if (props?.komponen?.sumbatan?.data_cukup === false) return BELUM_ADA_DATA
  return LEVEL[props?.level] ?? BELUM_ADA_DATA
}

// ---------- Angka ----------
const fmt2 = new Intl.NumberFormat('id-ID', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
export const angka2 = (n) => (n == null || Number.isNaN(n) ? '-' : fmt2.format(n))
export const bobot = (n) => new Intl.NumberFormat('id-ID', { maximumFractionDigits: 2 }).format(n)
export const mm = (n) => `${Math.round(n ?? 0)} mm`

// ---------- Waktu (WIB) ----------
const fmtJam = new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', hour: '2-digit', minute: '2-digit' })
const fmtTanggal = new Intl.DateTimeFormat('id-ID', {
  timeZone: 'Asia/Jakarta',
  day: 'numeric',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
})
export const jamWib = (iso) => (iso ? `${fmtJam.format(new Date(iso)).replace(':', '.')} WIB` : '-')
export const tanggalWib = (iso) => (iso ? `${fmtTanggal.format(new Date(iso)).replace(':', '.')} WIB` : '-')

export function umur(iso, sekarang = Date.now()) {
  if (!iso) return ''
  const detik = Math.max(0, (sekarang - new Date(iso).getTime()) / 1000)
  if (detik < 60) return 'baru saja'
  const menit = Math.floor(detik / 60)
  if (menit < 60) return `${menit} menit lalu`
  const jam = Math.floor(menit / 60)
  if (jam < 24) return `${jam} jam lalu`
  return `${Math.floor(jam / 24)} hari lalu`
}
