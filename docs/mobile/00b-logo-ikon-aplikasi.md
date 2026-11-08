# 00b · Logo dan Ikon Aplikasi

**Panduan lengkap logo + palet:** [../BRAND.md](../BRAND.md) · **Dibuat:** 8 November 2026
**Kode:** `mobile/android/app/src/main/res/` · **Sumber logo:** `brand/logo/rivora-mark.svg`

## Yang diubah

Ikon launcher bawaan Flutter diganti logo RIVORA "Mata Air" (mata dengan iris berisi air, lihat BRAND.md bagian 1).

| File | Isi |
|---|---|
| `mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon: background + foreground + monochrome |
| `drawable/ic_launcher_background.xml` | Vektor gradien Arus `#11808C` → `#0A4E57` |
| `drawable/ic_launcher_foreground.xml` | Vektor simbol Mata Air, lebar 46 dp dari kanvas 108 dp (di dalam zona aman 66 dp) |
| `drawable/ic_launcher_monochrome.xml` | Simbol satu warna untuk ikon bertema Android 13+ (mengikuti warna wallpaper) |
| `mipmap-{mdpi…xxxhdpi}/ic_launcher.png` | PNG 48/72/96/144/192 px untuk launcher lama, dari `brand/png/rivora-app-icon-1024.png` |

`AndroidManifest.xml` tidak diubah: sudah menunjuk `@mipmap/ic_launcher` dan label `RIVORA`.

## Kenapa vektor

- Tajam di semua kepadatan layar tanpa banyak PNG.
- Bentuk ikon mengikuti launcher HP (lingkaran, squircle, kotak) karena memakai adaptive icon.
- `minSdk` Flutter = 24, jadi gradien di VectorDrawable didukung langsung. Adaptive icon aktif mulai API 26; di bawahnya memakai PNG.

## Verifikasi

- Keempat file XML lolos `aapt2 compile` (build-tools 36.0.0).
- Belum dicek di emulator: jalankan `flutter run`, lalu lihat ikon di app drawer. Untuk ikon bertema: Settings → Wallpaper & style → Themed icons (Android 13+).

## Belum dikerjakan

- Logo di dalam aplikasi (layar login/beranda) masih ikon `Icons.water_drop_rounded` di `lib/widgets/common.dart`. Bisa diganti `CustomPainter` dari path SVG (tanpa dependensi baru) atau paket `flutter_svg`.
- Splash Android < 12 (`drawable/launch_background.xml`) masih putih polos. Android 12+ sudah otomatis menampilkan ikon baru di splash.
