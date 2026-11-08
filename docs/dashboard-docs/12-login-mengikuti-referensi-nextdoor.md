# Halaman login mengikuti tata letak referensi

**Waktu:** 2026-11-08

**Apa yang diubah**
Halaman login dasbor ditata ulang mengikuti tangkapan layar referensi dari Wildan (halaman masuk Nextdoor). Yang ditiru tata letaknya saja: nav atas, hero besar bersudut dengan kartu formulir di tengah, tiga kartu fitur, ajakan, dan kaki abu-abu. Nama, logo, foto, dan teks tetap milik RIVORA.

**File**
| File | Isi |
|---|---|
| `dashboard/src/pages/Login.jsx` | Nav (logo RIVORA + label "Dasbor kelurahan"), hero, kartu formulir, kartu kedua "Petugas atau warga? Pakai aplikasi RIVORA di Android", tiga kartu fitur, ajakan "Masuk ke dasbor", kaki berisi produk, sumber data, dan nama tim |
| `dashboard/src/components/Ikon.jsx` | Ikon `mata` untuk tombol tampilkan password |
| `dashboard/src/index.css` | Bagian Login diganti: hero 640px, kartu putih 400px, isian 56px, tombol pill, grid fitur 3 kolom, kaki 4 kolom |
| `dashboard/.oxlintrc.json` | `ignorePatterns` untuk `public/**` dan `dist/**`, supaya lint tidak memindai `public/contoh-ui/leaflet.js` |

**Keputusan**
- Latar hero = peta risiko RW asli dari `GET /rw/risk` (endpoint terbuka tanpa login, SRS backend FR-BE-01), tidak bisa digeser atau diklik. Repo belum punya foto, dan peta lebih menggambarkan RIVORA daripada foto taman. Bila gagal dimuat, latarnya teal polos.
- Tombol "Continue with Google" dan "Continue with Apple" tidak dipakai. Login di SRS hanya username dan password akun lurah (FR-DB-01).
- Tiga kartu fitur memakai ikon besar di atas warna gelap sebagai pengganti foto. Isinya tiga langkah RIVORA: lapor foto, prioritas sebelum hujan, bukti sebelum dan sesudah.
- Aturan login tidak berubah: hanya role `lurah`, pesan galat sama, token tetap di `localStorage`.

**Cara cek**
Keluar dari dasbor (tombol di kanan atas) atau hapus `rivora_token` di localStorage, lalu buka http://localhost:5173.
Sudah dicek lewat tangkapan layar Chrome headless 1440 px: semua bagian tampil, peta RW berwarna di latar hero. `npm run build` sukses, lint tinggal 1 peringatan lama di `DemoRainSlider.jsx`.

**Belum dikerjakan**
- Belum dicek di lebar kecil. SRS menargetkan desktop, dan grid fitur tidak dilipat di layar sempit.
- Kartu fitur belum memakai foto asli. Bisa diganti foto saluran dari seed backend (`db/seed/foto/`) begitu tersedia.
- Login sungguhan (klik Masuk) di halaman baru ini belum diuji ulang. Logikanya tidak diubah.
