// Hasil contoh untuk stub dan DEMO_MODE (docs SRS backend FR-BE-19).
// Bergiliran berat -> sedang -> bersih, mirip MockApiClient di aplikasi mobile.

const CONTOH_LAPORAN = [
  {
    jenis_saluran: 'terbuka',
    saluran_terlihat: true,
    kelas_sumbatan: 'berat',
    skor_sumbatan: 0.85,
    penyebab: ['plastik', 'sedimen'],
    keyakinan: 'tinggi',
    catatan: 'Sampah plastik menutupi sebagian besar lebar saluran',
  },
  {
    jenis_saluran: 'terbuka',
    saluran_terlihat: true,
    kelas_sumbatan: 'sedang',
    skor_sumbatan: 0.55,
    penyebab: ['daun_ranting'],
    keyakinan: 'sedang',
    catatan: 'Daun dan ranting menutupi sekitar separuh lebar saluran',
  },
  {
    jenis_saluran: 'terbuka',
    saluran_terlihat: true,
    kelas_sumbatan: 'bersih',
    skor_sumbatan: 0.08,
    penyebab: [],
    keyakinan: 'tinggi',
    catatan: 'Aliran terlihat lancar, tidak ada sampah berarti',
  },
]

const CONTOH_VERIFIKASI = {
  sudah_bersih: true,
  kelas_sesudah: 'bersih',
  skor_sumbatan_sesudah: 0.08,
  keyakinan: 'tinggi',
  catatan: 'Sampah plastik sudah terangkat, aliran terlihat lancar',
}

let giliran = 0

/** Contoh analisis berikutnya. jenis_saluran mengikuti pilihan pelapor. */
function contohLaporan(jenisSaluran) {
  const hasil = CONTOH_LAPORAN[giliran % CONTOH_LAPORAN.length]
  giliran += 1
  return { ...hasil, penyebab: [...hasil.penyebab], jenis_saluran: jenisSaluran || hasil.jenis_saluran }
}

function contohVerifikasi() {
  return { ...CONTOH_VERIFIKASI }
}

module.exports = { contohLaporan, contohVerifikasi }
