# Halaman login layar penuh dengan animasi

**Waktu:** 2026-11-08 14:00

**Apa yang diubah**
Permintaan Wildan: halaman login masih terlalu kecil dan tidak layar penuh, tiga foto di bawah tampak jelek karena terpotong, perlu animasi sederhana, dan tulisan "Dasbor kelurahan" di kanan atas dihapus. Diminta juga memakai skill UI agar hasilnya tidak terlihat generik.

**Skill yang dipasang** (di `~/.claude/skills/`, bukan di repo)
- `ui-ux-pro-max` dari github.com/nextlevelbuilder/ui-ux-pro-max-skill (lisensi MIT). Isinya data CSV dan skrip pencarian lokal, sudah diperiksa: tanpa akses jaringan. Folder tes skrip tidak ikut dipasang. Skrip pencariannya tidak dijalankan karena diblokir mode otomatis Claude Code; yang dipakai panduan dan aturannya.
- `frontend-design` dari github.com/anthropics/skills.

**Rencana desain**
- Subjek: pintu masuk alat kerja lurah untuk mencegah genangan di Bandung.
- Satu elemen yang menonjol: foto relawan membersihkan Sungai Cikapundung menutup layar penuh, judul besar di atasnya.
- Huruf: Plus Jakarta Sans (karya desainer Indonesia), dimuat dari Google Fonts. Hanya untuk halaman login.
- Warna: teal RIVORA `#127a6c`, air gelap `#0b2b28` untuk lapisan di atas foto, putih.
- Gerak: satu urutan saat halaman dimuat, bukan efek di tiap bagian. Mati otomatis bila sistem meminta gerak dikurangi.

**File**
| File | Isi |
|---|---|
| `dashboard/src/pages/Login.jsx` | Nav (logo saja) di atas foto. Hero dua kolom: judul + paragraf di kiri, kartu masuk di kanan. Isian punya label terlihat, bukan cuma placeholder. Pesan galat `role="alert"`. Posisi potong foto (`posisi`) dihapus |
| `dashboard/src/index.css` | Bagian Login ditulis ulang: hero `100vh` tanpa margin, lapisan gelap di atas foto, judul `clamp(44px, 6.2vw, 92px)`, kartu 460px dengan isian 56px, kartu foto bingkai 4:3 `object-fit: contain`, kaki selebar layar, susunan satu kolom di bawah 900px. Aturan login lama yang sempat tersisa dihapus |
| `dashboard/index.html` | Memuat Plus Jakarta Sans dari Google Fonts |

**Animasi**
- Foto hero mengecil pelan dari 112% ke 100% selama 2,4 detik.
- Judul, paragraf, lalu kartu masuk muncul berurutan (jeda 0,35, 0,5, dan 0,65 detik), naik 18px sambil memudar.
- Fokus isian: garis teal dan cincin tipis. Tombol Masuk sedikit mengecil saat ditekan.
- Semua animasi dimatikan untuk `prefers-reduced-motion: reduce`.

**Tiga foto tidak terpotong lagi**
Bingkai foto 4:3 dengan `object-fit: contain`. Foto mendatar (kartu 1 dan 2) mengisi penuh. Foto tegak (kartu 3) tampil utuh, dan sisi kiri-kanannya diisi versi buram foto yang sama di latar kartu.

**Cara cek**
Keluar dari dasbor, buka http://localhost:5173, tekan Ctrl+Shift+R.
Sudah dicek lewat tangkapan layar Chrome headless di 1440x900 (hero, kartu foto, kaki) dan 390x844 (ponsel): tidak ada luapan horizontal. `npm run build` sukses.

**Belum dikerjakan**
- Tanpa internet, huruf jatuh ke Inter atau huruf sistem.
- Klik Masuk di halaman baru belum diuji ulang. Logika login tidak diubah.
