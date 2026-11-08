# 00 · Design System Mobile

**Kode:** `mobile/lib/theme/app_theme.dart` · **Dibuat:** tahap 02 (8 November 2026)
**Sumber keputusan:** skill ui-ux-pro-max: `--design-system` untuk layanan publik, `--stack flutter`, dan `references/pro-rules.md` (checklist app mobile)

## Arah desain

**Gaya: Accessible & Ethical.** Hasil pencarian design system untuk "government environmental service mobile app" merekomendasikan gaya ini untuk layanan publik dengan audiens luas. Cocok karena pengguna utama RIVORA adalah petugas kebersihan dan siskamling yang memakai HP di luar ruangan, sering di bawah terik matahari (proposal 3.2, Tabel 13).

Prinsip yang dipakai:

1. **Terbaca di lapangan.** Kontras teks ≥ 4,5:1 di semua pasangan warna, font khusus keterbacaan, ukuran tap ≥ 48 dp.
2. **Status tidak hanya lewat warna.** Setiap kelas sumbatan dan status laporan punya ikon + teks + warna.
3. **Satu aksi utama per layar.** Beranda → Lapor saluran; Konfirmasi → Kirim; Tugas → Arahkan ke lokasi. Tombol utama menempel di bawah layar (mudah dijangkau jempol).
4. **Datar dan tenang.** Kartu putih dengan garis tipis, tanpa bayangan tebal atau gradien. Warna kuat hanya untuk aksi utama dan status.

Hasil pertama `--design-system` (pola landing page "Hero + CTA", biru generik) **tidak dipakai** karena untuk halaman web, bukan app mobile.

## Warna

Semua warna lewat token tema (`ColorScheme` + `RivoraColors`). Tidak ada hex langsung di layar.

### Inti

| Token | Light | Dark | Dipakai untuk |
|---|---|---|---|
| `primary` | `#0B6E79` teal air | `#5FC3CF` | Aksi utama, tab aktif, tanda merek |
| `onPrimary` | `#FFFFFF` | `#00363D` | Teks di atas primary |
| `primaryContainer` | `#D3ECEE` | `#0E4A52` | Pilihan terpilih, indikator tab |
| `surface` | `#F3F6F5` | `#0D1417` | Latar halaman |
| `surfaceContainerLowest` | `#FFFFFF` | `#152024` | Kartu |
| `onSurface` | `#0B1F2A` | `#E6EEF0` | Teks utama |
| `onSurfaceVariant` | `#46575D` | `#A7B6BB` | Teks sekunder |
| `outline` | `#7A8B90` | `#6F8186` | Garis tepi kontrol (≥ 3:1) |
| `outlineVariant` | `#DCE3E1` | `#2A3A3F` | Garis tepi kartu (dekoratif) |
| `error` | `#B42318` | `#FF9A8F` | Pesan error |

### Kelas sumbatan (`RivoraColors`)

| Kelas | Light (teks / latar) | Dark (teks / latar) | Ikon |
|---|---|---|---|
| Bersih | `#17663F` / `#E3F3EA` | `#7BD8A6` / `#12301F` | check_circle |
| Ringan | `#5C6B0A` / `#F1F4DC` | `#C9D86A` / `#2A2F0E` | info |
| Sedang | `#9A4A06` / `#FCEBD9` | `#F5B26B` / `#3A2410` | warning |
| Berat | `#A51C14` / `#FBE4E1` | `#FF9A8F` / `#3D1714` | error |
| Tidak terlihat | `#4A5A62` / `#E7ECEE` | `#B4C2C8` / `#243034` | visibility_off |

### Rasio kontras (dihitung, rumus WCAG)

| Pasangan | Rasio |
|---|---|
| Light: primary di atas putih | 5,96 |
| Light: teks utama di atas latar | 15,53 |
| Light: teks sekunder di atas kartu | 7,55 |
| Light: bersih / ringan / sedang / berat / tidak terlihat | 6,07 / 5,25 / 5,37 / 6,23 / 6,02 |
| Dark: teks utama di atas latar | 15,81 |
| Dark: teks sekunder di atas kartu | 7,95 |
| Dark: onPrimary di atas primary | 6,39 |
| Dark: bersih / ringan / sedang / berat / tidak terlihat | 8,32 / 8,94 / 7,96 / 7,72 / 7,43 |

Semua teks ≥ 4,5:1. Warna garis kontrol awalnya `#8A9A9E` (2,92:1, gagal) lalu digelapkan ke `#7A8B90`.

## Tipografi

**Atkinson Hyperlegible** (Braille Institute, lisensi OFL), di-bundle di `mobile/assets/fonts/`. Dirancang supaya huruf mirip (I/l/1, O/0) mudah dibedakan, jadi koordinat dan skor tetap terbaca di bawah matahari. Dipilih dari hasil `--design-system` untuk layanan publik. Font dibundel di app (bukan diunduh saat runtime) supaya tetap jalan saat sinyal lemah.

| Gaya | Dipakai untuk |
|---|---|
| `headlineMedium` bold | Judul login, angka skor |
| `headlineSmall` bold | Kartu Lapor saluran, angka statistik |
| `titleLarge` bold | Judul AppBar, sapaan |
| `titleMedium` bold | Judul kartu, judul bagian, tombol |
| `bodyLarge` / `bodyMedium` | Isi |
| `bodySmall` | Info sekunder (waktu, lokasi) |
| `labelLarge` / `labelMedium` bold | Chip, badge, tombol teks |

Ukuran mengikuti setelan teks sistem (diuji pada skala 130%).

## Spasi, sudut, gerak

| Token | Nilai |
|---|---|
| `Space` | 4 · 8 · 12 · 16 · 24 · 32 |
| `Radii` | 8 (chip, badge) · 12 (tombol, input) · 16 (kartu) |
| `Motion` | 150 ms (cepat) · 250 ms (normal) |

Gutter halaman 16 dp. Tinggi minimal tombol 52 dp, area tap ≥ 48 dp.

## Komponen

| Komponen | File | Catatan |
|---|---|---|
| `SumbatanBadge` | `widgets/sumbatan_style.dart` | Ikon + teks + warna, versi `compact` untuk daftar |
| `LaporanStatusChip`, `TugasStatusChip` | `widgets/status_chip.dart` | Dikirim / Ditugaskan / Ditangani / Cek manual; Baru / Dikerjakan / Selesai |
| `AiResultCard` | `widgets/ai_result_card.dart` | Kelas, skor 0–1 besar + bar, penyebab, indikator keyakinan 3 batang, catatan |
| `ReportPhoto` | `widgets/report_photo.dart` | File lokal → URL → pengganti (latar kelas + piktogram jenis saluran, tahap 05) |
| `ReportTile` | `widgets/report_tile.dart` | Baris laporan di Beranda dan Laporan saya |
| `RivoraMark`, `SectionTitle`, `EmptyState` | `widgets/common.dart` | Tanda merek, judul bagian (header untuk TalkBack), keadaan kosong/gagal |

## Ikon

Satu keluarga: **Phosphor** (sejak tahap 05, rekomendasi ui-ux-pro-max). Garis tipis seragam; versi Fill hanya untuk tab aktif. Semua ikon lewat `RIcons` di `lib/theme/rivora_icons.dart`, tidak ada `Icons.*` langsung di layar. Font dipasang sebagai aset (lihat tahap 05). Tidak ada emoji sebagai ikon.

Jenis saluran memakai piktogram gambar sendiri (`JenisPictogram`), bukan ikon umum.

## Aksesibilitas

- `Semantics` pada kartu yang bisa ditekan, chip pilihan (`selected`), timeline, skor, dan indikator keyakinan.
- Judul bagian ditandai `header` untuk TalkBack.
- Ikon tombol punya `tooltip` (Akun, Tutup, tampilkan kata sandi).
- Login mendukung isi otomatis dari password manager (`AutofillGroup`) dan paste.
- Getaran ringan saat jepret dan saat laporan terkirim.

## Keputusan yang sengaja tidak diikuti

| Saran | Alasan |
|---|---|
| `go_router` (pedoman stack Flutter) | Hanya ±10 layar dan tanpa deep link; `Navigator` cukup untuk 12 jam. Bisa dipindah saat notifikasi FCM perlu membuka layar tertentu (tahap 03) |
| Animasi scroll reveal (hasil design system) | Untuk web; di app cukup transisi bawaan Material dan umpan balik tekan |

## Tambahan tahap 03

| Item | Isi |
|---|---|
| Tanda merek | `RivoraMark` = ikon aplikasi **Mata Air** (`widgets/rivora_mark.dart`), digambar dari `brand/logo/rivora-mark.svg`. Panduan: [../BRAND.md](../BRAND.md) |
| Warna `waspada` | Light `#8A4A00` / `#FCEFD6` (6,03:1) · Dark `#F2C16B` / `#362607` (8,78:1). Dipakai level risiko RW bersama `bersih` (aman) dan `berat` (risiko tinggi) |
| Token `Motion` | `fast` 150 ms · `normal` 250 ms · `reveal` 700 ms · masuk `easeOutCubic` · keluar `easeInCubic`. `Motion.of()` mengembalikan 0 kalau "Hapus animasi" aktif |
| Komponen gerak | `AnimatedScore`, `AnimatedBar`, `ScanOverlay` (garis pindai warna Bening `#5FC3CF`), `Skeleton`, `SkeletonList` (`widgets/motion.dart`) |
| `BeforeAfterCompare` | Geser, ketuk, atau aksi slider TalkBack (naik/turun 10%) |
| `RisikoChip` | Aman / Waspada / Risiko tinggi, ikon + teks + warna |
| Tombol | Padding horizontal 16 (bukan 24) supaya dua tombol berdampingan tidak memotong label |

## Tambahan tahap 04

| Item | Isi |
|---|---|
| Kartu | Sudut `Radii.xl` = 20. Light: tanpa garis, bayangan lembut (elevasi 1,5, `#0B1F2A` 20%). Dark: garis `outlineVariant` |
| Hero hujan | Gradien ikut kategori: teal `#0B6E79→#06424A`, cokelat `#7A4300→#4A2800`, merah `#9B1C14→#5E0F0A`. Teks putih ≥ 5,96:1, teks sekunder putih 88% ≥ 5,03:1 |
| Penanda peta | Selalu warna pekat `RivoraColors.light` di kedua tema (putih di atasnya ≥ 5,89:1). Laporan = bulat + ikon kelas; tugas = kotak membulat + nomor prioritas |
| Tile peta | OpenStreetMap, saturasi ±30% + sedikit lebih terang; mode gelap memakai filter gelap flutter_map |
| Large title | `SliverAppBar.large` di Laporan dan Tugas |
| Indikator langkah | `StepProgress`: 3 segmen 4 dp + label "Langkah n dari 3 · …" |
| Placeholder foto | Latar warna kelas + tekstur gelombang 10% + ikon jenis saluran |

Detail dan referensi: [04-redesign-modern.md](04-redesign-modern.md).

## Tambahan tahap 05

| Item | Isi |
|---|---|
| Ikon | Phosphor Regular/Fill sebagai font aset (`PhosphorRegular`, `PhosphorFill`), lewat `RIcons`. Paket `phosphor_flutter` tidak dipakai karena tidak bisa dikompilasi di Flutter 3.47 |
| Piktogram jenis saluran | `JenisPictogram` (`widgets/pictogram.dart`): saluran terbuka (penampang), gorong-gorong (bawah jalan), inlet jalan (kisi + panah). Dipakai form, placeholder foto, kartu tugas |
| Chip | Status = titik + teks. Badge sumbatan/risiko = teks berwarna di latar lembut, tanpa ikon. Tag penyebab = latar `surfaceContainerHigh`, tanpa garis (bukan tombol) |
| Hero hujan | Warna datar, gradien dihapus: teal `#0A5C66`, cokelat `#6B3B00`, merah tua `#8A1A12`. Teks putih ≥ 4,5:1 |
| Pin peta | Bentuk tetes (`_PinPainter`), ujung di titik. Laporan 28×36 warna kondisi sekarang (`kelasKini`), tugas 34×44 dengan nomor |
| Poligon RW | Isi warna level 16%, garis 70%, label nama RW di sisi utara dengan halo warna permukaan. Label hanya di peta penuh |
| Atribusi OSM | Strip kecil pojok kanan bawah, tidak tertutup legenda |
| Kartu risiko | `RiskCard`: nama RW, `RisikoChip`, skor, alasan, tiga bar komponen, rumus, label mode demo bila hujan disimulasikan |
| App bar | `SliverAppBar.medium` di Laporan dan Tugas (menggantikan `large`) |
| Lembar izin | Bottom sheet "Sebelum memotret" sekali sebelum dialog izin sistem (NFR-04) |

Detail: [05-audit-qa.md](05-audit-qa.md).

## Tambahan tahap 06: bahasa warga

Aturan: **kata dan warna dulu, angka belakangan**. Angka 0–1, mm, rumus, dan koordinat tidak tampil sebagai informasi utama; tetap tersedia lewat `Semantics` dan lembar "Cara RIVORA menilai".

| Item | Isi |
|---|---|
| Kartu cuaca | Judul = kalimat kesimpulan (`headlineSmall` putih tebal) + saran (`bodyLarge`) + `CuacaIlustrasi` 72 dp. mm/peluang `bodySmall` 88% putih |
| `RiskMeter` | 3 segmen 10 dp (lebar 4 : 3 : 3 sesuai ambang), segmen aktif warna `fg`, lainnya `bg`; penanda lingkaran 22 dp, tepi 4 dp warna level, bayangan halus. Label Aman · Waspada · Tinggi di bawah |
| Kotak saran | Latar `risiko(level).bg`, teks + ikon `fg`, tebal. Satu kalimat tindakan |
| Baris faktor | Kotak ikon 36 dp (`bg`/`fg` tingkat), kalimat `bodyLarge`, tiga titik 8 dp |
| `SumbatanVisual` | Penampang 104 × 75 dp: dinding `onSurfaceVariant`, sampah `sumbatan(kelas).fg`, air Bening `#5FC3CF`. Tidak terlihat = garis putus + "?" |
| Keyakinan | "AI yakin / cukup yakin / kurang yakin" + tiga batang |
| `LokasiMini` | Ringkas: peta 76 dp di kiri. Penuh: peta 148 dp selebar kartu + pin kondisi. Judul "Di RW 05" |

Detail: [06-ramah-warga.md](06-ramah-warga.md).

## Checklist pra-rilis (pro-rules)

| Item | Status |
|---|---|
| Tanpa emoji sebagai ikon | ✅ |
| Satu keluarga ikon | ✅ |
| Token warna, tanpa hex di layar | ✅ |
| Kontras teks ≥ 4,5:1 light dan dark | ✅ (dihitung) |
| Area tap ≥ 48 dp | ✅ |
| Umpan balik tekan (ripple) | ✅ |
| Disabled state jelas | ✅ (tombol Kirim) |
| Safe area untuk tombol bawah | ✅ |
| Dark mode diuji terpisah | ✅ (emulator) |
| Teks besar tanpa terpotong | ✅ (skala 130%) |
| Animasi mati saat "Hapus animasi" | ✅ (lewat `Motion.of`) |
| Pemberitahuan tidak menutupi aksi utama | ✅ (ditunda saat kamera/verifikasi terbuka) |
| Diuji TalkBack | ❌ belum |
| Diuji tablet / landscape | ❌ belum |
