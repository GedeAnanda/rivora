// Data contoh dasbor (VITE_USE_MOCK=1). Deterministik: hasilnya sama setiap dimuat.
// Poligon RW = ILUSTRASI berupa grid di sekitar Gedebage, bukan batas resmi.
// Mengikuti isi seed backend (SRS backend FR-BE-18): ~20 saluran, ~30 laporan, 2 tidak terlihat,
// satu RW demo dengan 1 saluran, satu RW tanpa laporan.

function acak(seed) {
  return () => {
    seed |= 0
    seed = (seed + 0x6d2b79f5) | 0
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
const r = acak(20261108)
const antara = (a, b) => a + (b - a) * r()

export const KELURAHAN = { id: 1, nama: 'Rancabolang', kecamatan: 'Gedebage' }

export const TITIK_GENANGAN = [
  { nama: 'Jl. Rancabolang', lat: -6.9508, lng: 107.6978 },
  { nama: 'Pasar Induk Gedebage', lat: -6.9468, lng: 107.7002 },
]

const PUSAT = [-6.9455, 107.6905]
const KOLOM = 4
const BARIS = 3
const SEL = 0.0042

const simpul = []
for (let b = 0; b <= BARIS; b++) {
  simpul.push([])
  for (let k = 0; k <= KOLOM; k++) {
    const tepi = b === 0 || b === BARIS || k === 0 || k === KOLOM
    const geser = tepi ? 0.0004 : 0.0011
    simpul[b].push([
      PUSAT[0] + (BARIS / 2 - b) * SEL + antara(-geser, geser),
      PUSAT[1] + (k - KOLOM / 2) * SEL + antara(-geser, geser),
    ])
  }
}

function titikDalamSel(b, k) {
  const u = antara(0.2, 0.8)
  const v = antara(0.2, 0.8)
  const [a, bb, c, d] = [simpul[b][k], simpul[b][k + 1], simpul[b + 1][k + 1], simpul[b + 1][k]]
  return [
    (1 - v) * ((1 - u) * a[0] + u * bb[0]) + v * ((1 - u) * d[0] + u * c[0]),
    (1 - v) * ((1 - u) * a[1] + u * bb[1]) + v * ((1 - u) * d[1] + u * c[1]),
  ]
}

// Jarak meter sederhana (equirectangular), cukup untuk skala kelurahan
function jarakM([lat1, lng1], [lat2, lng2]) {
  const x = ((lng2 - lng1) * Math.PI) / 180 * Math.cos((((lat1 + lat2) / 2) * Math.PI) / 180)
  const y = ((lat2 - lat1) * Math.PI) / 180
  return Math.sqrt(x * x + y * y) * 6371000
}

// elevasi_relatif per RW (1 = paling rendah di kelurahan), makin ke tenggara makin rendah
const ELEVASI = [0.1, 0.2, 0.3, 0.4, 0.3, 0.5, 0.6, 0.7, 0.6, 0.8, 0.9, 1.0]

// Laporan per RW: tiap saluran = daftar kelas dari yang terlama ke terbaru.
// RW 03 dibiarkan tanpa saluran (belum ada data). RW 12 = RW demo, 1 saluran.
const RENCANA = [
  [['bersih'], ['bersih']],
  [['ringan', 'bersih'], ['sedang']],
  [],
  [['tidak_terlihat'], ['ringan']],
  [['sedang', 'berat'], ['ringan']],
  [['sedang'], ['ringan', 'ringan']],
  [['berat'], ['sedang', 'berat']],
  [['bersih'], ['ringan']],
  [['berat'], ['tidak_terlihat']],
  [['sedang', 'berat'], ['sedang']],
  [['berat'], ['berat', 'sedang']],
  [['sedang', 'berat']],
]

const RENTANG = { bersih: [0.03, 0.12], ringan: [0.18, 0.36], sedang: [0.45, 0.66], berat: [0.74, 0.92] }
const CATATAN = {
  bersih: 'Aliran terlihat lancar, tidak ada sampah berarti',
  ringan: 'Ada sedikit sampah di tepi saluran, aliran masih lancar',
  sedang: 'Sampah menutupi sekitar separuh lebar saluran',
  berat: 'Sampah menutupi sebagian besar lebar saluran',
  tidak_terlihat: 'Saluran tertutup beton, kondisi di dalam tidak terlihat',
}
const PENYEBAB = { bersih: [], ringan: ['daun_ranting'], sedang: ['plastik'], berat: ['plastik', 'sedimen'], tidak_terlihat: [] }

export const PETUGAS = [
  { id: 2, nama: 'Asep Saepudin' },
  { id: 3, nama: 'Dedi Kurniawan' },
  { id: 4, nama: 'Euis Rahmawati' },
]

const SEKARANG = Date.now()
const lalu = (jam) => new Date(SEKARANG - jam * 3600_000).toISOString()

export function buatSeed() {
  const rw = []
  const saluran = []
  const laporan = []
  const tugas = []
  let idSaluran = 1
  let idLaporan = 1

  for (let b = 0; b < BARIS; b++) {
    for (let k = 0; k < KOLOM; k++) {
      const i = b * KOLOM + k
      const ring = [simpul[b][k], simpul[b][k + 1], simpul[b + 1][k + 1], simpul[b + 1][k], simpul[b][k]]
      const pusat = [(ring[0][0] + ring[2][0]) / 2, (ring[0][1] + ring[2][1]) / 2]
      const terdekat = TITIK_GENANGAN.map((g) => ({ g, m: jarakM(pusat, [g.lat, g.lng]) })).sort((x, y) => x.m - y.m)[0]
      // SRS backend 9.2: kedekatan = 1 - min(jarak/1000, 1); K = 0,5 elevasi + 0,5 kedekatan
      const kedekatan = 1 - Math.min(terdekat.m / 1000, 1)
      rw.push({
        id: i + 1,
        nama: `RW ${String(i + 1).padStart(2, '0')}`,
        coordinates: [ring.map(([lat, lng]) => [lng, lat])],
        elevasi_relatif: ELEVASI[i],
        jarak_genangan_m: Math.round(terdekat.m / 10) * 10,
        genangan_terdekat: terdekat.g.nama,
        kerentanan: Math.round((0.5 * ELEVASI[i] + 0.5 * kedekatan) * 100) / 100,
      })

      for (const riwayat of RENCANA[i]) {
        const [lat, lng] = titikDalamSel(b, k)
        const s = { id: idSaluran++, rw_id: i + 1, jenis: riwayat[0] === 'tidak_terlihat' ? 'gorong_gorong' : 'terbuka', lat, lng }
        if (r() < 0.25 && s.jenis === 'terbuka') s.jenis = 'inlet_jalan'
        saluran.push(s)
        let jam = antara(60, 160)
        for (const kelas of riwayat) {
          const terlihat = kelas !== 'tidak_terlihat'
          laporan.push({
            id: idLaporan++,
            saluran_id: s.id,
            sumber: 'laporan',
            jenis_saluran: s.jenis,
            kelas,
            skor_sumbatan: terlihat ? Math.round(antara(...RENTANG[kelas]) * 100) / 100 : null,
            keyakinan: !terlihat ? 'rendah' : r() < 0.7 ? 'tinggi' : r() < 0.6 ? 'sedang' : 'rendah',
            penyebab: PENYEBAB[kelas],
            catatan: CATATAN[kelas],
            foto_url: null,
            captured_at: lalu(jam),
            ai_sumber: 'model',
            lokasi_demo: false,
            status: terlihat ? 'dikirim' : 'cek_manual',
          })
          jam = Math.max(1, jam - antara(20, 60))
        }
      }
    }
  }

  // Satu laporan berasal dari mode demo AI, supaya label "contoh demo" bisa dicek
  laporan.find((l) => l.kelas === 'sedang').ai_sumber = 'demo'

  // Satu tugas berjalan
  const salTugas = saluran.find((s) => s.rw_id === 7)
  const lapTugas = laporan.filter((l) => l.saluran_id === salTugas.id).at(-1)
  lapTugas.status = 'ditugaskan'
  tugas.push({
    id: 1,
    saluran_id: salTugas.id,
    laporan_id: lapTugas.id,
    petugas_id: 2,
    status: 'dikerjakan',
    catatan: 'Prioritas sebelum hujan sore',
    foto_sesudah_url: null,
    verifikasi: null,
    dibuat_at: lalu(3),
    selesai_at: null,
  })

  // Satu tugas selesai di RW 05: laporan "berat" lalu verifikasi "bersih"
  const salSelesai = saluran.find((s) => s.rw_id === 5)
  const lapSebelum = laporan.filter((l) => l.saluran_id === salSelesai.id).at(-1)
  lapSebelum.status = 'ditangani'
  const verifikasi = {
    sudah_bersih: true,
    kelas_sesudah: 'bersih',
    skor_sumbatan_sesudah: 0.08,
    keyakinan: 'tinggi',
    catatan: 'Sampah plastik sudah terangkat, aliran terlihat lancar',
  }
  laporan.push({
    id: idLaporan++,
    saluran_id: salSelesai.id,
    sumber: 'verifikasi',
    jenis_saluran: salSelesai.jenis,
    kelas: 'bersih',
    skor_sumbatan: 0.08,
    keyakinan: 'tinggi',
    penyebab: [],
    catatan: verifikasi.catatan,
    foto_url: null,
    captured_at: lalu(0.5),
    ai_sumber: 'model',
    lokasi_demo: false,
    status: 'ditangani',
  })
  tugas.push({
    id: 2,
    saluran_id: salSelesai.id,
    laporan_id: lapSebelum.id,
    petugas_id: 3,
    status: 'selesai',
    catatan: null,
    foto_sesudah_url: null,
    verifikasi,
    dibuat_at: lalu(5),
    selesai_at: lalu(0.5),
  })

  return { rw, saluran, laporan, tugas, idLaporan, idTugas: 3 }
}
