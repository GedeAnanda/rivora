# RIVORA Brand Kit: untuk dasbor kelurahan

Logo **Ombak** + palet **biru air**. Dipakai juga di aplikasi mobile, PPT, dan video demo, jadi dasbor tolong ikut supaya semuanya seragam.

Buka **`panduan/brand-sheet.html`** di browser untuk lihat semuanya secara visual.

## Isi paket

| Folder | Isi |
|---|---|
| `siap-tempel-dasbor/public/` | **Langsung timpa ke `dashboard/public/`.** Nama file sama dengan yang sudah ada di dasbor |
| `token/dasbor-palet.css` | Nilai warna baru untuk variabel yang sudah dipakai `index.css` (`--navy`, `--teal`, …) |
| `token/tokens.css`, `tokens.json` | Token lengkap: ramp Laut/Tirta/Batu, warna risiko, kelas sumbatan, mode gelap |
| `logo/svg/`, `logo/png/` | Semua versi logo (horizontal, bertumpuk, simbol, satu warna, ikon app). PNG transparan |
| `panduan/` | `brand-sheet.html` (visual) dan `BRAND.md` (aturan lengkap) |

## Pasang di dasbor (3 langkah)

1. **Logo + favicon:** salin isi `siap-tempel-dasbor/public/` ke `dashboard/public/` dan timpa file lama. Halaman logo lama (`public/brand/opsi-logo.html`, `logo-rivora.html`) boleh dihapus.

   | File di dasbor | Diisi dengan |
   |---|---|
   | `favicon.svg` | Simbol Ombak |
   | `brand/rivora-logo.svg` / `-2100.png` | Logo horizontal, latar terang |
   | `brand/rivora-logo-putih.svg` / `-2100.png` | Logo horizontal, latar gelap |
   | `brand/rivora-mark.svg` / `-1024.png` | Simbol (lingkaran biru + ombak) |
   | `brand/rivora-mark-putih.svg` / `-1024.png` | Simbol berlingkaran putih, untuk latar gelap/foto |
   | `brand/rivora-mark-mono.svg` | Simbol satu warna |
   | `brand/rivora-ikon-app.svg` / `-1024.png` | Ikon aplikasi (gradien biru + ombak putih) |

2. **Warna:** di `dashboard/src/index.css`, ganti nilai `--navy`, `--navy-2`, `--teal`, `--teal-gelap`, `--teal-muda` dengan isi `token/dasbor-palet.css`. Nama variabel tidak berubah, jadi komponen tidak perlu disentuh. Komentar "teal merek RIVORA" di atas file bisa diganti "biru Laut".
3. **Cek:** `npm run dev`, lihat header/login, tombol utama, chip terpilih, dan favicon di tab.

## Warna inti

| Nama | Hex | Pakai untuk |
|---|---|---|
| Samudra | `#04214B` | Teks judul, header, latar gelap |
| Laut | `#0361C3` | Aksi utama: tombol, tautan, tab aktif |
| Tirta | `#35C1F4` | Aksen air, grafik. **Jangan untuk teks di latar terang** (2,1:1) |
| Buih | `#DFF2FE` | Latar terpilih, kontainer |
| Kabut | `#F4FAFE` | Latar halaman (opsional di dasbor) |

Gradien `#22B2F2 → #0347A8` hanya untuk ikon app atau bidang besar (hero login), bukan tombol.

**Warna risiko RW dan kelas sumbatan tidak ikut berubah.** Tetap hijau/kuning/merah supaya tidak tertukar dengan warna merek. Pakai yang sudah disepakati di SRS dasbor. Nilai versi aplikasi mobile ada di `tokens.css` kalau mau disamakan.

## Aturan logo

- **Jangan diketik ulang** pakai font. Wordmark digambar khusus, pakai file SVG/PNG.
- **Area aman:** ruang kosong minimal seperempat diameter lingkaran simbol di semua sisi.
- **Ukuran minimum:** simbol 20 px, logo horizontal 96 px.
- **Jangan:** ditarik/dipipihkan, ganti warna, balik arah ombak, diputar, diberi bayangan.
- Di latar gelap pakai `rivora-logo-putih.svg`. Di atas foto pakai `rivora-mark-putih.svg`.

## Font

Aplikasi mobile dan slide memakai **Atkinson Hyperlegible** (Google Fonts, OFL). Dasbor sekarang memakai Inter. Ganti kalau mau seragam, tapi tidak wajib.

```css
@import url('https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible:wght@400;700&display=swap');
:root { font-family: 'Atkinson Hyperlegible', system-ui, sans-serif; }
```

Sumber semua file: repo `RIVORA`, folder `brand/` (generator: `brand/tools/build_logo.py`).
