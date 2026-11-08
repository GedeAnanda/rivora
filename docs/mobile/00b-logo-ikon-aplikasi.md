# 00b · Logo, Ikon Aplikasi, dan Palet Biru

**Panduan lengkap logo + palet:** [../BRAND.md](../BRAND.md) · **Diperbarui:** 8 November 2026
**Kode:** `mobile/android/app/src/main/res/`, `mobile/lib/widgets/rivora_mark.dart`, `mobile/lib/theme/app_theme.dart`
**Sumber logo:** `brand/tools/build_logo.py` (menghasilkan SVG, vector drawable Android, dan path Flutter)

## Riwayat

| Versi | Logo | Palet | Status |
|---|---|---|---|
| 1 | "Mata Air": mata dengan iris berisi air | Teal (`#0B6E79`) | Diganti: menurut tim kurang cocok, warnanya biasa |
| 2 | **"Ombak"**: ombak menggulung di dalam lingkaran | **Biru air** (Laut `#0361C3`, Tirta `#35C1F4`, Samudra `#04214B`) | Dipakai |

Versi 2 dipilih tim dari empat konsep (Ombak, Pin Tetes, R Arus, Tetes Isi).

## Yang diubah

### Ikon launcher Android

| File | Isi |
|---|---|
| `mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon: background + foreground + monochrome (tidak berubah) |
| `drawable/ic_launcher_background.xml` | Vektor gradien biru `#22B2F2` → `#0347A8` |
| `drawable/ic_launcher_foreground.xml` | Ombak putih memenuhi ikon. Desain 100 unit dipetakan ke 72 dp tengah dari kanvas 108 dp, gulungan ombak di dalam zona aman 66 dp |
| `drawable/ic_launcher_monochrome.xml` | Bentuk ombak yang sama untuk ikon bertema Android 13+ (diwarnai ulang oleh launcher) |
| `mipmap-{mdpi…xxxhdpi}/ic_launcher.png` | PNG 48/72/96/144/192 px untuk launcher lama, dari `brand/png/rivora-app-icon-1024.png` |

`AndroidManifest.xml` tidak diubah.

### Logo di dalam aplikasi

`lib/widgets/rivora_mark.dart`:

- `MataAirPainter` diganti `OmbakPainter`: simbol lingkaran Laut dengan ombak Tirta. `reverse: true` membuat lingkaran putih untuk latar gelap.
- `RivoraAppIcon` sekarang menggambar gradien biru dan ombak putih, sama dengan ikon launcher. Dipakai `RivoraMark` di Beranda.
- Path diambil dari `build_logo.py --dart`, digambar tanpa dependensi SVG.

### Tema biru

`lib/theme/app_theme.dart` memakai palet biru (tabel lengkap dan rasio kontras di [00-design-system.md](00-design-system.md#warna)):

- Primary Laut `#0361C3`, teks Samudra `#04214B`, kontainer Buih `#DFF2FE`, latar Kabut `#F4FAFE`.
- Mode gelap: latar `#070F19`, primary `#63C6FF`.

Hex langsung di luar tema yang ikut diganti:

| File | Dulu | Sekarang |
|---|---|---|
| `widgets/rain_card.dart` | Kartu hujan tidak/ringan teal `#0A5C66` | Laut 700 `#024D9D` |
| `widgets/motion.dart` | Garis pindai AI Bening `#5FC3CF` | Tirta `#35C1F4` |
| `widgets/sumbatan_visual.dart` | Air Bening `#5FC3CF` | Tirta `#35C1F4` |
| `widgets/before_after.dart` | Pegangan geser teal `#0B6E79` | Laut `#0361C3` |
| `screens/camera_screen.dart`, `map_screen.dart`, `widgets/before_after.dart`, `motion.dart` | Lapisan gelap `#0B1F2A` | `#07111F` |

Warna status (aman/waspada/risiko tinggi, kelas sumbatan) tetap hijau/kuning/merah. Hanya "tidak terlihat" yang digeser ke abu kebiruan.

## Verifikasi

- `dart format`, `flutter analyze` (tanpa masalah), `flutter test`: 44 tes lulus.
- Keempat XML launcher lolos `aapt2 compile` (build-tools 36.0.0).
- Emulator Pixel 8 (Android, APK debug, mode contoh):
  - Beranda light dan dark sudah biru, dengan ikon ombak di kiri atas.
  - Ikon RIVORA di app drawer tampil bulat dengan gradien dan ombak putih.
- Belum dicek: ikon bertema (Settings → Wallpaper & style → Themed icons) dan layar lain satu per satu.

## Belum dikerjakan

- Splash Android < 12 (`drawable/launch_background.xml`) masih putih polos. Android 12+ otomatis menampilkan ikon baru di splash.
