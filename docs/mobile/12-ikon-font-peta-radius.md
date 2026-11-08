# 12 · Ikon Lucide, Font Plus Jakarta Sans, Peta RW Radius

**Tanggal:** 8 November 2026 · **Branch:** `feature/mobile`
**Permintaan:** ganti ikon ke library Flutter lain, ganti font (angka 0 bergaris miring di Atkinson Hyperlegible dinilai jelek), dan ubah area RW di peta dari kotak ke gaya radius.

## Keputusan dan referensi

| Bagian | Sebelum | Sesudah | Alasan |
|---|---|---|---|
| Ikon | Phosphor (font yang dipasang manual) + piktogram jenis saluran dan cuaca yang digambar sendiri | **Lucide** lewat paket [`lucide_icons_flutter`](https://pub.dev/packages/lucide_icons_flutter) 4.0.2 (ISC), ±1.600 ikon | Satu keluarga untuk semua ikon, garis 2 px di grid 24 px dengan ujung membulat. Pustaka ikon bawaan shadcn/ui. Paket ini memakai `IconData` biasa, jadi bisa dikompilasi di Flutter 3.47 (`phosphor_flutter` tidak bisa, lihat [05](05-audit-qa.md)) |
| Font | Atkinson Hyperlegible | **Plus Jakarta Sans** 2.7.1 (Tokotype, OFL), bobot 400/500/600/700/800 | Dibuat untuk identitas kota Jakarta (+Jakarta City of Collaboration), jadi cocok untuk layanan publik kota di Indonesia. Angka 0 tanpa garis miring, dan punya angka tabular (`tnum`) |
| Area RW di peta | Poligon kotak (batas sel dari seed) berisi warna rata + garis tepi | **Lingkaran radius** di pusat RW, warnanya makin pekat ke tengah, garis tepi tipis, label kapsul di tepi bawah | Kotak terlihat kaku dan seperti tabel. Lingkaran bergradasi lebih mudah dibaca sebagai "wilayah sekitar", mirip lingkaran akurasi lokasi di aplikasi peta |

## Ikon

`lib/theme/rivora_icons.dart` (`RIcons`) masih jadi satu-satunya pintu ikon, sehingga nama ikon di seluruh layar tidak berubah.

| Pakai | Ikon Lucide |
|---|---|
| Tab (tidak aktif / aktif) | `house`, `map`, `clipboardList`, `listChecks`. Tab aktif memakai **bobot 600** (`LucideIcons600`) karena Lucide tidak punya versi isi; latar indikator Material 3 tetap menandai tab aktif |
| Jenis saluran | Terbuka `waves`, gorong-gorong `cylinder` diputar 90° (jadi pipa mendatar), inlet jalan `grid3x3` |
| Cuaca di kartu hujan | `sun`, `cloudDrizzle`, `cloudRain`, `cloudLightning` dengan **bobot 300** supaya tidak berat di ukuran 72 px |
| Faktor risiko | Hujan `cloudRain`, sumbatan `trash2`, daerah tergenang `wavesArrowUp` (air naik) |
| Lainnya | `camera`, `send`, `navigation`, `badgeCheck`, `brushCleaning`, `locateFixed`, `sparkles`, `hardHat`, `triangleAlert`, `circleCheck`, `eyeOff`, `cloudOff`, `flaskConical`, dll. |

Piktogram buatan sendiri (`CustomPainter`) di `pictogram.dart` dan `rain_card.dart` dihapus. Ukurannya disesuaikan dengan garis Lucide: kartu tugas 22, form 32, placeholder foto 44/28.

## Font

- `pubspec.yaml`: keluarga `PlusJakartaSans` (5 bobot); Atkinson Hyperlegible dan Phosphor dihapus dari aset.
- `app_theme.dart`: semua gaya teks memakai `FontFeature.tabularFigures()`, jadi skor, jam, jarak, dan jumlah tidak bergeser saat berubah. Jarak huruf: judul besar dirapatkan (−1 sampai −0,2), teks isi 0, label kecil +0,1 sampai +0,3.
- Paket `cupertino_icons` yang tidak dipakai ikut dihapus (−116 KB di APK).

## Peta: lingkaran radius

`RwRisk` (model) mendapat tiga turunan dari poligon server:

| Turunan | Isi |
|---|---|
| `pusat` | Rata-rata titik sudut poligon |
| `radiusMeter` | 0,62 × jarak rata-rata pusat ke sudut. Untuk RW persegi = ±0,44 × lebarnya, jadi ada celah tipis antar-RW tetangga |
| `titikLabel` | Tepi selatan lingkaran. Badan pin menjulur ke atas dari titiknya, jadi label di bawah tidak tertimpa pin di dalam RW yang sama |

`RivoraMap` menggambar 14 `CircleMarker` sepusat per RW (jari-jari 100 % → 26 %, alpha 0,03 per lapis). Hasilnya gradasi radial: tengah ±35 %, tepi 3 %, tanpa cincin yang terlihat. Ditambah satu garis tepi 1 px (alpha 0,5). Warnanya ikut tema (`context.rivora`), jadi lebih terang di mode gelap. Label: kapsul putih dengan titik warna level dan nama RW. Legenda "Risiko RW" memakai lingkaran bergradasi yang sama.

Data dan logika tidak berubah. `berisi()` (titik di dalam poligon) tetap memakai poligon asli untuk "Di RW 05" di form, dan skor/level tetap dari server.

## Hasil uji

| Uji | Hasil |
|---|---|
| `flutter analyze` | **No issues found** |
| `flutter test` | **65/65 lulus** (+7 di `test/tahap12_test.dart`: pusat dan jari-jari lingkaran RW, label di tepi selatan, RW tanpa poligon, ikon satu keluarga Lucide + bobot, ikon cuaca per kategori, gorong-gorong diputar, font + angka tabular) |
| Emulator Pixel 8, backend lokal, `petugas1` | Beranda, peta (zoom 15 dan 16), pratinjau peta di beranda, daftar tugas, detail tugas, kamera, form lapor, Laporan saya: light dan dark |
| APK release arm64 (`--split-per-abi`) | **21,9 MB** (doc 09: 19,9 MB, sebelum FCM ditambahkan) |

Catatan ukuran: paket Lucide mendaftarkan 7 file font. Font yang dipakai (reguler, 300, 600) dipangkas otomatis jadi 2–17 KB, tapi 4 bobot yang tidak dipakai (100, 200, 400, 500) ikut terbawa utuh, ±0,95 MB terkompresi. Kalau ukuran APK jadi masalah, font Lucide bisa dipasang manual seperti Phosphor dulu.

| Peta sebelum (kotak, doc 10) | Peta sesudah (radius) | Zoom 16 | Mode gelap |
|---|---|---|---|
| ![Kotak](img/10-peta-server.png) | ![Radius](img/12-peta-radius.png) | ![Dekat](img/12-peta-radius-dekat.png) | ![Gelap](img/12-peta-radius-gelap.png) |

| Beranda (font + ikon cuaca) | Pratinjau peta di beranda | Form: ikon jenis saluran | Daftar tugas (gelap) |
|---|---|---|---|
| ![Beranda](img/12-beranda.png) | ![Pratinjau](img/12-beranda-peta.png) | ![Form](img/12-form-jenis.png) | ![Tugas](img/12-tugas-gelap.png) |


## Sisa

- Di zoom 15, label RW baris atas bisa tertutup pin dari RW di bawahnya. Pin sengaja tetap di atas label karena pin bisa diketuk. Di zoom 16 tidak terjadi.
