# Foto di tiga kartu fitur halaman login

**Waktu:** 2026-11-08 13:25

**Apa yang diubah**
Tiga kartu di bawah hero login sekarang berisi foto, bukan ikon. Gayanya mengikuti referensi: foto yang sama diburamkan dan digelapkan menjadi latar kartu, foto tajam bersudut membulat di dalamnya, lalu caption putih di bawah. Isi foto disesuaikan dengan caption masing-masing.

**File**
| File | Isi |
|---|---|
| `dashboard/public/login/kartu-1.jpg` | Selokan penuh sampah dekat sekolah (Bali), 323 KB |
| `dashboard/public/login/kartu-2.jpg` | Jalan basah dan genangan saat hujan sore (Babakan Raden), 169 KB |
| `dashboard/public/login/kartu-3.jpg` | Petugas membersihkan saluran tersumbat botol plastik (Agbara, Lagos), 446 KB |
| `dashboard/src/pages/Login.jsx` | `FITUR` memakai `foto` + `posisi` (titik fokus potongan). Daftar `KREDIT_FOTO` dan baris kredit di kaki halaman |
| `dashboard/src/index.css` | `.fitur-kartu::before` (latar foto buram, `blur(18px)`, `brightness(0.55)`), `.fitur-foto` (rasio 280:320, `object-fit: cover`), `.kaki-kredit`. Aturan `.fitur-gambar` dihapus |

**Pasangan caption dan foto**
| Caption | Foto | Alasan |
|---|---|---|
| Petugas dan warga memotret saluran, AI menilai sumbatannya | Selokan penuh sampah | Saluran yang dipotret dan dinilai AI. Fokus digeser ke kanan bawah supaya selokan yang menonjol |
| Daftar saluran yang perlu dibersihkan sebelum hujan turun | Jalan basah saat hujan | Hujan dan genangan yang ingin dicegah |
| Bukti foto sebelum dan sesudah pembersihan | Petugas membersihkan saluran | Pembersihan yang dibuktikan dengan foto |

**Sumber foto (Wikimedia Commons, wajib dikreditkan)**
| File | Pembuat | Lisensi |
|---|---|---|
| Waste_in_rain_gutter_near_school_Bali.jpg | DayakSibiriak | CC BY-SA 4.0 |
| Cuaca_hukan_sore_hari_jalan_baru_babakan_raden_2014-01-18_17-49.jpg | Komarudin0412 | CC BY-SA 3.0 |
| Man_cleaning_drainage_in_Agbara,_Lagos_Badagry_Expressway.jpg | Macdanpets | CC BY-SA 4.0 |

Kredit keempat foto (termasuk foto hero dari entri 13) tampil di kaki halaman login dengan tautan ke halaman masing-masing. Jangan dihapus.

**Cara cek**
Keluar dari dasbor, buka http://localhost:5173, gulir ke bawah hero. Tekan Ctrl+Shift+R bila masih tampilan lama.
Sudah dicek lewat tangkapan layar Chrome headless 1440 px: tiga kartu berisi foto, latar buram, caption terbaca, kredit tampil di kaki. `npm run build` sukses.

**Belum dikerjakan**
- Foto kartu 3 berasal dari Nigeria, bukan Indonesia. Belum ketemu foto pembersihan saluran di Indonesia dengan lisensi bebas. Bisa diganti foto tim sendiri saat uji coba lapangan.
- Foto belum dikompres. Total folder `public/login/` sekitar 1,9 MB.
