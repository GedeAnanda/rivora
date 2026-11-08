# Dokumentasi Mobile: Aplikasi Pelapor RIVORA

**Pemilik:** A · Mobile developer · **Branch:** `feature/mobile`
**Kode:** `mobile/` (Flutter, Android) · **Acuan:** proposal 3.1–3.4, Tabel 3, 12, 13, 14

Aplikasi pelapor untuk petugas kebersihan, siskamling, dan warga: foto saluran langsung dari kamera, GPS dan waktu tercatat otomatis, lalu hasil analisis AI ditampilkan.

## Log dokumen per tahap

| No | Dokumen | Isi | Jam (Tabel 14) | Status |
|---|---|---|---|---|
| 01 | [01-alur-lapor.md](01-alur-lapor.md) | Kamera, GPS, jenis saluran, kirim, hasil AI | 1–5 | Selesai, teruji di emulator (mode contoh) |
| 02 | _belum_ | Status laporan + tab Tugas | 5–8 | – |
| 03 | _belum_ | Notifikasi FCM + foto sesudah (verifikasi) | 8–10 | – |

Setiap tahap baru ditambah satu file `NN-nama-tahap.md` dan satu baris di tabel ini.

## Menjalankan

```bash
cd mobile
flutter pub get
```

| Kondisi | Perintah |
|---|---|
| Backend belum ada (mode contoh) | `flutter run` |
| Emulator + backend di laptop | `flutter run --dart-define=API_URL=http://10.0.2.2:3000 --dart-define=ALLOW_MOCK_LOCATION=true` |
| HP asli + backend di laptop (satu WiFi/hotspot) | `flutter run --dart-define=API_URL=http://<IP-laptop>:3000` |
| HP asli + backend sudah deploy | `flutter run --dart-define=API_URL=https://<domain-backend>` |

- `10.0.2.2` = alamat laptop dari dalam emulator Android.
- `ALLOW_MOCK_LOCATION=true` hanya untuk emulator. Di HP asli jangan dipakai, karena pemeriksaan lokasi palsu adalah bagian dari pencegahan laporan palsu (Tabel 3).
- Build APK untuk demo: `flutter build apk --release --dart-define=API_URL=https://<domain-backend>`

## Struktur `mobile/lib`

```
lib/
├── main.dart                     # MaterialApp + tema
├── config.dart                   # API_URL, ALLOW_MOCK_LOCATION (--dart-define)
├── models/
│   ├── ai_result.dart            # Keluaran AI, format Lampiran C
│   ├── jenis_saluran.dart        # terbuka | gorong_gorong | inlet_jalan
│   └── report.dart               # Respons POST /reports
├── services/
│   ├── api_client.dart           # HttpApiClient + MockApiClient
│   └── location_service.dart     # Izin + posisi GPS
├── screens/
│   ├── home_screen.dart          # Beranda, tombol "Lapor saluran"
│   ├── camera_screen.dart        # Kamera in-app (tanpa galeri)
│   ├── report_form_screen.dart   # Konfirmasi + pilih jenis saluran
│   └── result_screen.dart        # Hasil analisis AI
├── widgets/
│   └── sumbatan_style.dart       # Warna, ikon, badge kelas sumbatan
└── utils/
    └── format.dart               # Format waktu, koordinat, desimal
```

## Cek sebelum commit

```bash
cd mobile
dart format lib test
flutter analyze
flutter test
```
