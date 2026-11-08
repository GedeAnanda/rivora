# RIVORA · Identitas Visual

**Halaman panduan (visual):** `brand/brand-sheet.html` (buka di browser) · **File logo:** `brand/logo/` (SVG) dan `brand/png/` (PNG transparan) · **Token warna:** `brand/tokens.css`, `brand/tokens.json`

Logo dan palet ini berlaku untuk aplikasi pelapor, dasbor kelurahan, PPT pitching, video demo, dan laporan pengembangan. Proposal tidak menetapkan logo atau warna, jadi seluruh identitas ini adalah keputusan tim saat hackathon **[ASUMSI]**. Isinya tetap mengacu ke proposal: tagline, siklus Lapor → Prediksi → Bertindak → Verifikasi (3.2), dan tiga level risiko aman, waspada, risiko tinggi (3.2).

**Riwayat:** 8 November 2026 logo pertama "Mata Air" (mata berisi air, palet teal) diganti logo **Ombak** dengan palet biru air atas permintaan tim. Logo dipilih dari empat konsep: Ombak, Pin Tetes, R Arus, Tetes Isi.

## 1. Konsep logo: Ombak

Simbol RIVORA adalah **ombak yang menggulung di dalam lingkaran**: air sudah naik dan akan pecah, tapi belum sampai. Bentuk ini membawa tagline *"See The Flood Before You See The Water."*

| Bagian | Arti |
|---|---|
| Lingkaran biru Laut | Wilayah yang dipantau: RW, kelurahan, kota (peta risiko per RW, proposal 3.2) |
| Ombak Tirta yang naik | Muka air yang diprediksi naik dari hujan, sumbatan, dan kerentanan (skor risiko, 3.2) |
| Gulungan (tabung) di puncak ombak | Momen sebelum ombak pecah = peringatan dini: warga dan petugas bertindak sebelum genangan terjadi (3.2) |

**Wordmark** digambar khusus dari garis membulat dengan tebal sama (18% tinggi huruf): ujung bulat terasa ramah dan cair, cocok dengan ombak. Tidak memakai font, jadi tidak ada masalah lisensi dan tidak boleh diketik ulang.

## 2. Versi logo

| File | Pakai untuk |
|---|---|
| `rivora-logo-horizontal.svg` | **Versi utama.** Header dasbor, slide judul, kop laporan |
| `rivora-logo-horizontal-reverse.svg` | Versi utama di latar gelap (Samudra, foto gelap) |
| `rivora-logo-stacked.svg` / `-reverse` | Ruang tegak: splash screen, sampul laporan, poster |
| `rivora-mark.svg` | Simbol saja: avatar, favicon, ikon kecil, penanda di peta. Terbaca di latar terang dan gelap |
| `rivora-mark-reverse.svg` | Simbol berlingkaran putih, untuk latar gelap yang ramai (foto, video) |
| `rivora-mark-mono.svg` / `-mono-putih` | Satu warna: stempel, cetak hitam-putih, watermark. Langit dan air dipisah garis celah |
| `rivora-logo-horizontal-mono.svg` | Logo horizontal satu warna |
| `rivora-wordmark.svg` / `-putih` | Nama saja, saat simbol sudah tampil terpisah |
| `rivora-app-icon.svg` | Ikon aplikasi (sudut membulat): gradien biru dengan ombak putih memenuhi ikon |
| `rivora-app-icon-square.svg` | Ikon tanpa sudut membulat (sumber `apple-touch-icon`, avatar media sosial) |
| `favicon.svg` | Favicon dasbor (`<link rel="icon" href="/favicon.svg">`) |

PNG transparan (lebar 2000 px untuk logo horizontal, 1200 px untuk lainnya, ikon 1024/512/180 px) ada di `brand/png/`, siap ditempel ke PPT atau Canva.

## 3. Palet warna: biru air

Lima warna inti diambil dari laut dan air. Nilainya **sama persis** dengan tema Flutter (`mobile/lib/theme/app_theme.dart`, lihat `docs/mobile/00-design-system.md`), jadi app, dasbor, dan slide tampil seragam.

| Nama | Hex | Arti | Pakai untuk | Kontras |
|---|---|---|---|---|
| **Samudra** | `#04214B` | Laut dalam | Teks utama, wordmark, latar gelap | 15,9:1 di putih |
| **Laut** | `#0361C3` | Air laut | Warna utama: tombol, tautan, tab aktif, lingkaran logo | 6,0:1 di putih |
| **Tirta** | `#35C1F4` | Air (bahasa Bali/Sanskerta) | Ombak di logo, aksen, warna utama mode gelap | 7,6:1 di Samudra |
| **Buih** | `#DFF2FE` | Buih ombak | Latar elemen terpilih, kontainer | Samudra 13,8:1 |
| **Kabut** | `#F4FAFE` | Udara sesudah hujan | Latar halaman | Samudra 15,1:1 |

Kontras dihitung dengan rumus WCAG 2.1. Laut di putih (6,0:1) aman untuk teks biasa. Tirta **jangan** dipakai untuk teks di latar terang (2,1:1); di latar gelap aman.

**Gradien ikon:** `#22B2F2` → `#0347A8` (135°). Hanya untuk ikon aplikasi dan bidang besar seperti hero slide, bukan untuk tombol atau teks.

### Ramp Laut (OKLCH, hue ~256)

`50 #F0F8FE · 100 #DFF2FE (Buih) · 200 #C4E2FE · 300 #9CCCFE · 400 #68ADFC · 500 #3787EB · 600 #0361C3 (Laut) · 700 #024D9D · 800 #003A79 · 900 #012858 · 950 #011839`

Pakai 700 untuk hover dan tombol ditekan, serta kartu biru gelap dengan teks putih (8,2:1). 500 ke bawah (lebih terang) hanya untuk ikon, grafik, atau teks besar. 900 untuk teks di atas Buih (12,6:1).

### Ramp Tirta (aksen air)

`100 #D1F1FF · 200 #A9E5FE · 300 #6ED6FF · 400 #35C1F4 (Tirta) · 500 #00A8D5 · 600 #0587AC · 700 #066784`

Untuk grafik, ilustrasi air, dan garis pindai AI. Kalau butuh teks berwarna aksen di latar terang, pakai 700 (6,4:1).

### Netral Batu (abu kebiruan)

`50 #F4FAFE (Kabut) · 100 #F0F7FD · 200 #E8F0F9 · 300 #D6E0EB · 500 #6E7D91 · 700 #47566C · 900 #04214B (Samudra)`

300 untuk garis pembatas, 500 untuk garis input dan ikon non-aktif (4,2:1), 700 untuk teks sekunder (7,5:1).

### Level risiko RW (dasbor, peta)

Batas skor mengikuti `docs/RENCANA_FINAL.md` bagian 4 **[ASUMSI]**. Warna risiko sengaja tetap hijau/kuning/merah (bukan biru) supaya tidak tertukar dengan warna merek.

| Level | Skor | Solid (peta) | Teks chip | Latar chip | Kontras chip |
|---|---|---|---|---|---|
| Aman | < 0,40 | `#2E9E6B` | `#17663F` | `#E3F3EA` | 6,1:1 |
| Waspada | 0,40–0,69 | `#E9A23B` | `#8A4A00` | `#FCEFD6` | 6,0:1 |
| Risiko tinggi | ≥ 0,70 | `#C8372D` | `#A51C14` | `#FBE4E1` | 6,2:1 |

- Poligon RW di Leaflet: `fillColor` = solid, `fillOpacity: 0.32`, `color` = solid, `weight: 1.6`.
- Hijau dan merah sulit dibedakan pengguna buta warna. Risiko tinggi sengaja dibuat lebih gelap dari aman, dan **selalu tampilkan label teks** di legenda, popup, dan daftar prioritas.

### Kelas sumbatan AI (Lampiran C)

Sama dengan `RivoraColors.light` di aplikasi: bersih `#17663F/#E3F3EA`, ringan `#5C6B0A/#F1F4DC`, sedang `#9A4A06/#FCEBD9`, berat `#A51C14/#FBE4E1`, tidak terlihat `#47566C/#E8EDF3` (teks/latar).

## 4. Tipografi

- **Atkinson Hyperlegible** (Regular 400, Bold 700, OFL) untuk semua teks: aplikasi, dasbor, slide. Dibuat Braille Institute untuk keterbacaan tinggi, cocok dengan petugas di lapangan. Dasbor: muat dari Google Fonts (`family=Atkinson+Hyperlegible:wght@400;700`).
- Logo memakai wordmark khusus, bukan font.

## 5. Aturan pakai

- **Area aman:** sisakan ruang kosong minimal **x** di semua sisi logo, dengan x = seperempat diameter lingkaran simbol.
- **Ukuran minimum:** simbol 20 px (6 mm cetak), logo horizontal 96 px (30 mm cetak). Di bawah 20 px pakai ikon aplikasi.
- **Di atas foto:** pakai `rivora-mark-reverse.svg` atau taruh logo di pelat Samudra atau Kabut.
- **Jangan:** menarik/memipihkan, mengganti warna lingkaran dan ombak, membalik arah ombak, memutar, memberi bayangan/efek, atau mengetik ulang wordmark.

## 6. Pakai di dasbor (React)

```js
// main.jsx
import '../../brand/tokens.css' // atau salin ke dashboard/src/
```

```css
.btn-primary { background: var(--rv-laut); color: var(--rv-putih); }
.btn-primary:hover { background: var(--rv-laut-700); }
.chip-tinggi { background: var(--rv-tinggi-latar); color: var(--rv-tinggi-teks); }
```

Salin `brand/logo/favicon.svg` dan `rivora-logo-horizontal.svg` ke `dashboard/public/`.

## 7. Membuat ulang file

Semua SVG dihasilkan dari satu skrip. Geometri dihitung tanpa clipPath/mask, supaya aman di Flutter, Figma, Canva, PPT, dan Android VectorDrawable:

```bash
python3 brand/tools/build_logo.py brand/logo --android mobile/android/app/src/main/res
```

- `--android` menulis vector drawable ikon launcher (background, foreground, monochrome).
- `--dart` mencetak path untuk `mobile/lib/widgets/rivora_mark.dart`.
- PNG diekspor dari SVG dengan Chrome headless (latar transparan) lalu diperkecil dengan `sips`.
