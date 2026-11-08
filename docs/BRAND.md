# RIVORA · Identitas Visual

**Halaman panduan (visual):** `brand/brand-sheet.html` (buka di browser) · **File logo:** `brand/logo/` (SVG) dan `brand/png/` (PNG transparan) · **Token warna:** `brand/tokens.css`, `brand/tokens.json`

Logo dan palet ini berlaku untuk aplikasi pelapor, dasbor kelurahan, PPT pitching, video demo, dan laporan pengembangan. Proposal tidak menetapkan logo atau warna, jadi seluruh identitas ini adalah keputusan tim saat hackathon **[ASUMSI]**. Isinya tetap mengacu ke proposal: tagline, siklus Lapor → Prediksi → Bertindak → Verifikasi (3.2), dan tiga level risiko aman, waspada, risiko tinggi (3.2).

## 1. Konsep logo: Mata Air

Simbol RIVORA adalah **mata yang irisnya berisi air**. Bentuk ini membawa tagline *"See The Flood Before You See The Water."*

| Bagian | Arti |
|---|---|
| Kelopak mata (Malam) | Mata petugas kebersihan, siskamling, dan warga yang memotret saluran (pengguna, proposal 3.1) |
| Iris dengan garis air (Arus + Bening) | Muka air di iris = level genangan yang diprediksi dari hujan, sumbatan, dan kerentanan (skor risiko, 3.2) |
| Kilau berbentuk tetes (putih) | Pantulan cahaya pada mata dibuat berupa tetes air = AI vision yang menilai foto saluran (3.3) |

Permainan kata untuk pitching: dalam bahasa Indonesia **"mata air"** berarti sumber air, dan kata-katanya sendiri berbunyi "mata" + "air", persis yang digambar simbol ini.

**Wordmark** digambar khusus dari garis lurus, lingkaran, dan diagonal dengan tebal sama (17% tinggi huruf). Tidak memakai font, jadi tidak ada masalah lisensi dan tidak boleh diketik ulang.

## 2. Versi logo

| File | Pakai untuk |
|---|---|
| `rivora-logo-horizontal.svg` | **Versi utama.** Header dasbor, slide judul, kop laporan |
| `rivora-logo-horizontal-reverse.svg` | Versi utama di latar gelap (Malam, foto gelap) |
| `rivora-logo-stacked.svg` / `-reverse` | Ruang tegak: splash screen, sampul laporan, poster |
| `rivora-mark.svg` / `-reverse` | Simbol saja: avatar, favicon, ikon kecil, penanda di peta |
| `rivora-mark-mono-malam.svg` / `-putih` | Satu warna: stempel, cetak hitam-putih, watermark |
| `rivora-logo-horizontal-mono.svg` | Logo horizontal satu warna |
| `rivora-wordmark.svg` / `-putih` | Nama saja, saat simbol sudah tampil terpisah |
| `rivora-app-icon.svg` | Ikon aplikasi 1024 px (sudut membulat), slide demo |
| `favicon.svg` | Favicon dasbor (`<link rel="icon" href="/favicon.svg">`) |

PNG transparan (lebar 2000 px untuk logo horizontal, 1200 px untuk lainnya) ada di `brand/png/`, siap ditempel ke PPT atau Canva.

## 3. Palet warna

Lima warna inti diambil dari dunia air dan hujan. Nilainya **sama persis** dengan tema Flutter yang sudah jalan (`mobile/lib/theme/app_theme.dart`, lihat `docs/mobile/00-design-system.md`), jadi app, dasbor, dan slide tampil seragam.

| Nama | Hex | Arti | Pakai untuk | Kontras |
|---|---|---|---|---|
| **Malam** | `#0B1F2A` | Langit malam saat hujan | Teks utama, badan logo, latar gelap | 16,9:1 di putih |
| **Arus** | `#0B6E79` | Aliran di saluran | Warna utama: tombol, tautan, tab aktif | 6,0:1 di putih |
| **Bening** | `#5FC3CF` | Air jernih, saluran bersih | Aksen air, warna utama mode gelap | 8,2:1 di Malam |
| **Embun** | `#D3ECEE` | Lapisan tipis | Latar elemen terpilih, kontainer | Malam 13,7:1 |
| **Kabut** | `#F3F6F5` | Udara sesudah hujan | Latar halaman | Malam 15,5:1 |

Kontras dihitung dengan rumus WCAG 2.1. Arus di putih (6,0:1) aman untuk teks biasa. Bening **jangan** dipakai untuk teks di latar terang (1,9:1); di latar gelap aman.

### Ramp Arus (OKLCH, hue 207)

`50 #EAFBFD · 100 #D3ECEE (Embun) · 200 #A9E3EC · 300 #5FC3CF (Bening) · 400 #39B1C0 · 500 #028C9A · 600 #0B6E79 (Arus) · 700 #055763 · 800 #04414A · 900 #022C33`

Pakai 700 untuk hover dan tombol ditekan. 500 ke bawah (lebih terang) hanya untuk ikon, grafik, atau teks besar.

### Netral Batu

`50 #F8FAF9 · 100 #F3F6F5 (Kabut) · 200 #EDF1F0 · 300 #DCE3E1 · 500 #7A8B90 · 700 #46575D · 900 #0B1F2A (Malam)`

300 untuk garis pembatas, 500 untuk garis input dan ikon non-aktif (3,5:1), 700 untuk teks sekunder (7,6:1).

### Level risiko RW (dasbor, peta)

Batas skor mengikuti `docs/RENCANA_FINAL.md` bagian 4 **[ASUMSI]**.

| Level | Skor | Solid (peta) | Teks chip | Latar chip | Kontras chip |
|---|---|---|---|---|---|
| Aman | < 0,40 | `#2E9E6B` | `#17663F` | `#E3F3EA` | 6,1:1 |
| Waspada | 0,40–0,69 | `#E9A23B` | `#8A4A00` | `#FCEFD6` | 6,0:1 |
| Risiko tinggi | ≥ 0,70 | `#C8372D` | `#A51C14` | `#FBE4E1` | 6,2:1 |

- Poligon RW di Leaflet: `fillColor` = solid, `fillOpacity: 0.32`, `color` = solid, `weight: 1.6`.
- Hijau dan merah sulit dibedakan pengguna buta warna. Risiko tinggi sengaja dibuat lebih gelap dari aman, dan **selalu tampilkan label teks** di legenda, popup, dan daftar prioritas.

### Kelas sumbatan AI (Lampiran C)

Sama dengan `RivoraColors.light` di aplikasi: bersih `#17663F/#E3F3EA`, ringan `#5C6B0A/#F1F4DC`, sedang `#9A4A06/#FCEBD9`, berat `#A51C14/#FBE4E1`, tidak terlihat `#4A5A62/#E7ECEE` (teks/latar).

## 4. Tipografi

- **Atkinson Hyperlegible** (Regular 400, Bold 700, OFL) untuk semua teks: aplikasi, dasbor, slide. Dibuat Braille Institute untuk keterbacaan tinggi, cocok dengan petugas di lapangan. Dasbor: muat dari Google Fonts (`family=Atkinson+Hyperlegible:wght@400;700`).
- Logo memakai wordmark khusus, bukan font.

## 5. Aturan pakai

- **Area aman:** sisakan ruang kosong minimal **x** di semua sisi logo, dengan x = jari-jari iris.
- **Ukuran minimum:** simbol 24 px (8 mm cetak), logo horizontal 96 px (30 mm cetak).
- **Di atas foto:** taruh logo di pelat Malam atau Kabut.
- **Jangan:** menarik/memipihkan, mengganti warna iris dan air, memutar, memberi bayangan/efek, atau mengetik ulang wordmark.

## 6. Pakai di dasbor (React)

```js
// main.jsx
import '../../brand/tokens.css' // atau salin ke dashboard/src/
```

```css
.btn-primary { background: var(--rv-arus); color: var(--rv-putih); }
.btn-primary:hover { background: var(--rv-arus-700); }
.chip-tinggi { background: var(--rv-tinggi-latar); color: var(--rv-tinggi-teks); }
```

Salin `brand/logo/favicon.svg` dan `rivora-logo-horizontal.svg` ke `dashboard/public/`.

## 7. Membuat ulang file

Semua SVG dihasilkan dari satu skrip (geometri dihitung, tanpa clipPath/mask supaya aman di Flutter, Figma, Canva, PPT, dan Android VectorDrawable):

```bash
python3 brand/tools/build_logo.py brand/logo
```

PNG diekspor dari SVG dengan Chrome headless (latar transparan) lalu diperkecil dengan `sips`.
