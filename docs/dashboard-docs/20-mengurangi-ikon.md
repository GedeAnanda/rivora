# Mengurangi ikon yang berlebihan

**Waktu:** 2026-11-08 14:45

**Apa yang diubah**
Permintaan Wildan: kurangi ikon (dia menyebutnya emoji) yang berlebihan, pakai hanya yang membantu.

**Aturan yang dipakai**
Ikon dipertahankan bila ia tombol atau peringatan yang perlu ditangkap cepat. Ikon yang hanya mengulang teks di sebelahnya dihapus.

**Dipertahankan**
| Ikon | Tempat | Alasan |
|---|---|---|
| Tetes air | Logo di kepala dasbor dan login | Identitas |
| Keluar, Kembali, lihat password, putar balik simulasi, tutup dialog | Tombol | Menunjukkan aksi |
| Awan putus, tanda seru, segitiga | Banner "Tidak terhubung", "Sebagian data gagal", "SIMULASI DEMO" | Peringatan yang harus terlihat |
| Kamera | Kotak "Foto tidak tersedia" | Menjelaskan kotak kosong |
| Panah kanan | Baris saluran di panel RW | Menunjukkan baris bisa diklik |

**Dihapus**
| Ikon | Tempat |
|---|---|
| Centang, tanda seru, segitiga | Lencana level RW dan legenda (teks "Aman/Waspada/Risiko tinggi" sudah ada, NFR-04 tetap terpenuhi) |
| Awan hujan, segitiga | Kartu hujan di kepala |
| Segitiga, info | Judul daftar "Bersihkan sebelum hujan" |
| Mata tertutup | Judul tab Cek langsung |
| Orang | Status tugas dan kartu tugas |
| Centang | Subjudul "Bukti pembersihan" |
| Semua ikon toast | Toast |
| Info | Petunjuk "Klik wilayah RW di peta" |
| Emoji navigasi, emoji hujan, simbol ▲ ✓ ! | Halaman contoh `public/contoh-ui/index.html` |

**File**
`dashboard/src/components/` Legend, Lencana, RainCard, PriorityList, ManualCheckList, TaskList, SaluranDetail, Toast; `dashboard/src/pages/Dashboard.jsx`; `dashboard/public/contoh-ui/index.html`. Impor `Ikon` yang tidak terpakai ikut dihapus. Kartu tugas sekarang menulis "Petugas: nama" dan "Dibuat ..." di dua baris.

**Cara cek**
Masuk dengan `lurah` di http://localhost:5173, tekan Ctrl+Shift+R.
Sudah dicek lewat tangkapan layar 1440x900: tab Perlu dibersihkan dan Tugas petugas. `npm run build` sukses, lint tanpa peringatan baru.
