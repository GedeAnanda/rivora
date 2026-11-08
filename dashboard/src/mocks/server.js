// Tiruan backend in-memory. Bentuk respons persis SRS backend bagian 7, rumus persis bagian 9.
// Dipakai saat VITE_USE_MOCK=1. Skor di sini hanya meniru backend; dasbor sendiri tidak menghitung skor.
import { KELURAHAN, PETUGAS, buatSeed } from './seed'

const BOBOT = { hujan: 0.4, sumbatan: 0.4, kerentanan: 0.2 }
const BOBOT_KEYAKINAN = { tinggi: 1, sedang: 0.6, rendah: 0.3 }
const HUJAN_OPEN_METEO_MM = 62 // [DEMO] nilai contoh prakiraan

const db = buatSeed()
let demoHujanMm = null
const diambilAt = new Date().toISOString()

class GalatApi extends Error {
  constructor(status, pesan) {
    super(pesan)
    this.status = status
  }
}

const tunda = (hasil) => new Promise((ok) => setTimeout(() => ok(structuredClone(hasil)), 150))
const gagal = (status, pesan) => new Promise((_, no) => setTimeout(() => no(new GalatApi(status, pesan)), 150))
const bulat = (n) => (n == null ? null : Math.round(n * 100) / 100)
const urutWaktu = (a, b) => b.captured_at.localeCompare(a.captured_at) || b.id - a.id

// ---------- Inti perhitungan (SRS backend bagian 9) ----------
function hujanSekarang() {
  const sim = demoHujanMm != null
  const totalMm = sim ? demoHujanMm : HUJAN_OPEN_METEO_MM
  return {
    hujan_24j_mm: totalMm,
    hujan_sumber: sim ? 'simulasi_demo' : 'open_meteo',
    hujan_diambil_at: diambilAt,
    hujan_lebat_diprediksi: totalMm >= 50,
    H: Math.min(totalMm / 100, 1),
  }
}

const laporanSaluran = (id) => db.laporan.filter((l) => l.saluran_id === id).sort(urutWaktu)
const kondisiTerkini = (id) => laporanSaluran(id).find((l) => l.kelas !== 'tidak_terlihat' && l.ai_sumber !== 'gagal') ?? null
function perluCekManual(id) {
  const terbaru = laporanSaluran(id)[0]
  return !!terbaru && (terbaru.kelas === 'tidak_terlihat' || terbaru.ai_sumber === 'gagal')
}
const tugasAktif = (id) => db.tugas.find((t) => t.saluran_id === id && t.status !== 'selesai') ?? null
const petugas = (id) => PETUGAS.find((p) => p.id === id)
const rwById = (id) => db.rw.find((x) => x.id === id)

const level = (skor) => (skor >= 0.7 ? 'risiko_tinggi' : skor >= 0.4 ? 'waspada' : 'aman')
const LABEL_LEVEL = { aman: 'Aman', waspada: 'Waspada', risiko_tinggi: 'Risiko tinggi' }
const lokasi = (e) => (e >= 0.67 ? 'lokasi rendah' : e >= 0.34 ? 'lokasi sedang' : 'lokasi relatif tinggi')

function hitungRw(rw, hujan) {
  const salRw = db.saluran.filter((s) => s.rw_id === rw.id)
  let total = 0
  let w = 0
  let berat = 0
  let dinilai = 0
  for (const s of salRw) {
    const k = kondisiTerkini(s.id)
    if (!k) continue
    dinilai++
    if (k.kelas === 'sedang' || k.kelas === 'berat') berat++
    total += BOBOT_KEYAKINAN[k.keyakinan] * k.skor_sumbatan
    w += BOBOT_KEYAKINAN[k.keyakinan]
  }
  const S = w ? total / w : 0
  const dataCukup = w > 0
  const skor = BOBOT.hujan * hujan.H + BOBOT.sumbatan * S + BOBOT.kerentanan * rw.kerentanan
  const lv = level(skor)
  const sim = hujan.hujan_sumber === 'simulasi_demo' ? ' (hujan simulasi demo)' : ''
  const alasan = dataCukup
    ? `${LABEL_LEVEL[lv]}: prakiraan hujan ${Math.round(hujan.hujan_24j_mm)} mm dalam 24 jam, ${berat} dari ${dinilai} saluran tersumbat sedang atau berat, ${lokasi(rw.elevasi_relatif)} dan ${rw.jarak_genangan_m} m dari titik genangan ${rw.genangan_terdekat}.${sim}`
    : `Belum ada laporan saluran di RW ini, skor sumbatan belum bisa dihitung.${sim}`
  return {
    rw_id: rw.id,
    nama: rw.nama,
    skor: bulat(skor),
    level: lv,
    komponen: {
      hujan: { nilai: bulat(hujan.H), bobot: BOBOT.hujan, kontribusi: bulat(BOBOT.hujan * hujan.H), mm: hujan.hujan_24j_mm },
      sumbatan: {
        nilai: bulat(S),
        bobot: BOBOT.sumbatan,
        kontribusi: bulat(BOBOT.sumbatan * S),
        jumlah_saluran: salRw.length,
        jumlah_cek_manual: salRw.filter((s) => perluCekManual(s.id)).length,
        data_cukup: dataCukup,
      },
      kerentanan: {
        nilai: rw.kerentanan,
        bobot: BOBOT.kerentanan,
        kontribusi: bulat(BOBOT.kerentanan * rw.kerentanan),
        elevasi_relatif: rw.elevasi_relatif,
        jarak_genangan_m: rw.jarak_genangan_m,
        genangan_terdekat: rw.genangan_terdekat,
      },
    },
    alasan,
  }
}

function ringkasTugasAktif(s) {
  const t = tugasAktif(s.id)
  return t ? { id: t.id, status: t.status, petugas_nama: petugas(t.petugas_id).nama } : null
}

function objekTugas(t) {
  const s = db.saluran.find((x) => x.id === t.saluran_id)
  const sebelum = db.laporan.find((l) => l.id === t.laporan_id)
  return {
    id: t.id,
    status: t.status,
    saluran: { id: s.id, jenis: s.jenis, rw_nama: rwById(s.rw_id).nama, lat: s.lat, lng: s.lng },
    petugas: { id: t.petugas_id, nama: petugas(t.petugas_id).nama },
    laporan_id: t.laporan_id,
    foto_sebelum_url: sebelum.foto_url,
    kelas_sebelum: sebelum.kelas,
    skor_sebelum: sebelum.skor_sumbatan,
    foto_sesudah_url: t.foto_sesudah_url,
    verifikasi: t.verifikasi,
    catatan: t.catatan,
    dibuat_at: t.dibuat_at,
    selesai_at: t.selesai_at,
  }
}

// ---------- Endpoint ----------
export const mock = {
  async login({ username, password }) {
    if (!password) return gagal(400, 'Password wajib diisi')
    const role = username === 'lurah' ? 'lurah' : username?.startsWith('petugas') ? 'petugas' : username === 'warga' ? 'warga' : null
    if (!role) return gagal(401, 'Username atau password salah')
    return tunda({ token: `mock-${role}`, role, pengguna: { id: 1, nama: 'Lurah Rancabolang', kelurahan_id: 1 } })
  },

  async health() {
    return tunda({ ok: true, demo_mode: true, ai_siap: true, db: 'ok' })
  },

  async rwRisk() {
    const hujan = hujanSekarang()
    // eslint-disable-next-line no-unused-vars
    const { H, ...metaHujan } = hujan
    return tunda({
      type: 'FeatureCollection',
      meta: { kelurahan: { id: KELURAHAN.id, nama: KELURAHAN.nama }, ...metaHujan, bobot: BOBOT, dihitung_at: new Date().toISOString() },
      features: db.rw.map((rw) => ({
        type: 'Feature',
        geometry: { type: 'Polygon', coordinates: rw.coordinates },
        properties: hitungRw(rw, hujan),
      })),
    })
  },

  async saluran() {
    return tunda({
      type: 'FeatureCollection',
      features: db.saluran.map((s) => {
        const k = kondisiTerkini(s.id)
        return {
          type: 'Feature',
          geometry: { type: 'Point', coordinates: [s.lng, s.lat] },
          properties: {
            saluran_id: s.id,
            jenis: s.jenis,
            rw_id: s.rw_id,
            rw_nama: rwById(s.rw_id).nama,
            kondisi: k && {
              laporan_id: k.id,
              kelas: k.kelas,
              skor_sumbatan: k.skor_sumbatan,
              keyakinan: k.keyakinan,
              foto_url: k.foto_url,
              captured_at: k.captured_at,
            },
            perlu_cek_manual: perluCekManual(s.id),
            tugas_aktif: ringkasTugasAktif(s),
          },
        }
      }),
    })
  },

  async saluranDetail(id) {
    const s = db.saluran.find((x) => x.id === Number(id))
    if (!s) return gagal(404, 'Saluran tidak ditemukan')
    return tunda({
      saluran_id: s.id,
      jenis: s.jenis,
      rw_id: s.rw_id,
      rw_nama: rwById(s.rw_id).nama,
      lat: s.lat,
      lng: s.lng,
      riwayat: laporanSaluran(s.id).map((l) => ({
        laporan_id: l.id,
        sumber: l.sumber,
        kelas: l.kelas,
        skor_sumbatan: l.skor_sumbatan,
        keyakinan: l.keyakinan,
        penyebab: l.penyebab,
        foto_url: l.foto_url,
        captured_at: l.captured_at,
        status: l.status,
        ai_sumber: l.ai_sumber,
        lokasi_demo: l.lokasi_demo,
        catatan: l.catatan,
      })),
      tugas: db.tugas.filter((t) => t.saluran_id === s.id).sort((a, b) => b.id - a.id).map(objekTugas),
    })
  },

  async priorities() {
    const hujan = hujanSekarang()
    const prioritas = []
    const cekManual = []
    for (const s of db.saluran) {
      const rw = rwById(s.rw_id)
      if (perluCekManual(s.id)) {
        const l = laporanSaluran(s.id)[0]
        cekManual.push({
          saluran_id: s.id,
          jenis: s.jenis,
          rw_nama: rw.nama,
          foto_url: l.foto_url,
          captured_at: l.captured_at,
          catatan: l.catatan,
          tugas_aktif: ringkasTugasAktif(s),
        })
        continue
      }
      const k = kondisiTerkini(s.id)
      if (!k || k.kelas === 'bersih') continue
      prioritas.push({
        saluran_id: s.id,
        jenis: s.jenis,
        rw_id: rw.id,
        rw_nama: rw.nama,
        lat: s.lat,
        lng: s.lng,
        kelas: k.kelas,
        skor_sumbatan: k.skor_sumbatan,
        keyakinan: k.keyakinan,
        foto_url: k.foto_url,
        captured_at: k.captured_at,
        skor_prioritas: bulat(BOBOT.hujan * hujan.H + BOBOT.sumbatan * k.skor_sumbatan + BOBOT.kerentanan * rw.kerentanan),
        komponen: { hujan: bulat(hujan.H), sumbatan: k.skor_sumbatan, kerentanan: rw.kerentanan },
        tugas_aktif: ringkasTugasAktif(s),
      })
    }
    prioritas.sort((a, b) => b.skor_prioritas - a.skor_prioritas || b.captured_at.localeCompare(a.captured_at))
    prioritas.forEach((p, i) => (p.peringkat = i + 1))
    // eslint-disable-next-line no-unused-vars
    const { H, hujan_diambil_at, ...meta } = hujan
    return tunda({ meta: { ...meta, dihitung_at: new Date().toISOString() }, prioritas, cek_manual: cekManual })
  },

  async petugas() {
    return tunda(PETUGAS.map((p) => ({ ...p, tugas_aktif: db.tugas.filter((t) => t.petugas_id === p.id && t.status !== 'selesai').length })))
  },

  async tasks() {
    return tunda(db.tugas.map(objekTugas).sort((a, b) => b.dibuat_at.localeCompare(a.dibuat_at)))
  },

  async createTask({ saluran_id, petugas_id, catatan }) {
    const s = db.saluran.find((x) => x.id === saluran_id)
    if (!s) return gagal(404, 'Saluran tidak ditemukan')
    if (tugasAktif(s.id)) return gagal(409, 'Saluran ini sudah punya tugas aktif')
    const terbaru = laporanSaluran(s.id)[0]
    for (const l of db.laporan) if (l.saluran_id === s.id && l.status === 'dikirim') l.status = 'ditugaskan'
    const t = {
      id: db.idTugas++,
      saluran_id: s.id,
      laporan_id: terbaru.id,
      petugas_id,
      status: 'baru',
      catatan: catatan || null,
      foto_sesudah_url: null,
      verifikasi: null,
      dibuat_at: new Date().toISOString(),
      selesai_at: null,
    }
    db.tugas.push(t)
    // [DEMO] mock tidak punya FCM; petugas 4 dianggap belum punya token supaya pesan "tanpa_token" bisa dicoba
    return tunda({ tugas: objekTugas(t), notifikasi: petugas_id === 4 ? 'tanpa_token' : 'terkirim' })
  },

  async demoHujan(mmBaru) {
    demoHujanMm = mmBaru
    return tunda({ mm: mmBaru })
  },
}

// ---------- Alat bantu uji di konsol (hanya mode data contoh) ----------
// window.__rivoraMock.verifikasi(idTugas)  -> anggap petugas mengirim foto bersih
// window.__rivoraMock.lapor(idSaluran, 'berat') -> anggap ada laporan baru dari HP
export const alatUji = {
  verifikasi(idTugas) {
    const t = db.tugas.find((x) => x.id === idTugas)
    if (!t || t.status === 'selesai') return 'tugas tidak ada atau sudah selesai'
    const s = db.saluran.find((x) => x.id === t.saluran_id)
    const v = { sudah_bersih: true, kelas_sesudah: 'bersih', skor_sumbatan_sesudah: 0.08, keyakinan: 'tinggi', catatan: 'Saluran sudah bersih, aliran lancar' }
    Object.assign(t, { status: 'selesai', verifikasi: v, foto_sesudah_url: '/contoh-saluran/bersih.jpg', selesai_at: new Date().toISOString() })
    for (const l of db.laporan) if (l.saluran_id === s.id && ['dikirim', 'ditugaskan'].includes(l.status)) l.status = 'ditangani'
    db.laporan.push({
      id: db.idLaporan++, saluran_id: s.id, sumber: 'verifikasi', jenis_saluran: s.jenis, kelas: 'bersih', skor_sumbatan: 0.08,
      keyakinan: 'tinggi', penyebab: [], catatan: v.catatan, foto_url: '/contoh-saluran/bersih.jpg', captured_at: new Date().toISOString(),
      ai_sumber: 'model', lokasi_demo: false, status: 'ditangani',
    })
    return 'ok'
  },
  lapor(idSaluran, kelas = 'berat') {
    const s = db.saluran.find((x) => x.id === idSaluran)
    if (!s) return 'saluran tidak ada'
    const skor = { bersih: 0.08, ringan: 0.3, sedang: 0.55, berat: 0.88 }[kelas] ?? null
    db.laporan.push({
      id: db.idLaporan++, saluran_id: s.id, sumber: 'laporan', jenis_saluran: s.jenis, kelas, skor_sumbatan: skor,
      keyakinan: 'tinggi', penyebab: kelas === 'berat' ? ['plastik', 'sedimen'] : [], catatan: 'Laporan uji dari konsol',
      foto_url: `/contoh-saluran/${kelas}.jpg`, captured_at: new Date().toISOString(), ai_sumber: 'model', lokasi_demo: false,
      status: kelas === 'tidak_terlihat' ? 'cek_manual' : tugasAktif(s.id) ? 'ditugaskan' : 'dikirim',
    })
    return 'ok'
  },
}

export { GalatApi }
