# Dokumentasi Mobile: Aplikasi Pelapor RIVORA

**Pemilik:** A · Mobile developer · **Branch:** `feature/mobile`
**Kode:** `mobile/` (Flutter, Android) · **Acuan:** proposal 3.1–3.4, Tabel 3, 12, 13, 14
**Kebutuhan (PRD & SRS):** [SRS.md](SRS.md)

Aplikasi pelapor untuk petugas kebersihan, siskamling, dan warga: foto saluran langsung dari kamera, GPS dan waktu tercatat otomatis, lalu hasil analisis AI ditampilkan.

## Log dokumen per tahap

| No | Dokumen | Isi | Jam (Tabel 14) | Status |
|---|---|---|---|---|
| 00 | [00-design-system.md](00-design-system.md) | Warna light/dark + rasio kontras, font, spasi, komponen, checklist | – | Dipakai semua layar |
| 00b | [00b-logo-ikon-aplikasi.md](00b-logo-ikon-aplikasi.md) | Logo "Mata Air" + ikon launcher Android (adaptive, themed). Panduan merek: [../BRAND.md](../BRAND.md) | – | Ikon terpasang, lolos `aapt2`; belum dicek di emulator |
| 01 | [01-alur-lapor.md](01-alur-lapor.md) | Kamera, GPS, jenis saluran, kirim, hasil AI | 1–5 | Selesai, teruji di emulator (mode contoh). Tampilan didesain ulang di 02 |
| 02 | [02-status-dan-tugas.md](02-status-dan-tugas.md) | Login + peran, navigasi bawah, Beranda baru, Laporan saya + timeline, tab Tugas | 5–8 | Selesai, teruji di emulator (mode contoh) |
| 03 | [03-verifikasi-dan-notifikasi.md](03-verifikasi-dan-notifikasi.md) | Foto sesudah + verifikasi AI + skor RW turun, notifikasi tugas (cek berkala + FCM), logo Mata Air di app, motion | 8–10 | Selesai, teruji di emulator (mode contoh). FCM aktif setelah `google-services.json` dipasang |
| 04 | [04-redesign-modern.md](04-redesign-modern.md) | Redesign berbasis riset: hero prakiraan hujan Open-Meteo, tab Peta (flutter_map + OSM), beranda baru, large title, indikator langkah | – | Selesai, teruji di emulator light/dark |
| 05 | [05-audit-qa.md](05-audit-qa.md) | Audit QA: kontrak disamakan dengan backend SRS bagian 7, warga tanpa login + Masuk petugas, laporan disimpan di HP, risiko RW di wilayahmu + poligon peta, Mulai kerjakan, label demo, ikon Phosphor + piktogram saluran | – | Selesai, 39 tes lulus, teruji di emulator light/dark. Belum diuji ke backend asli |

Setiap tahap baru ditambah satu file `NN-nama-tahap.md` dan satu baris di tabel ini.

## Menjalankan

```bash
cd mobile
flutter pub get
```

| Kondisi | Perintah |
|---|---|
| Backend belum ada (mode contoh; warga tanpa login, "Masuk petugas" → "Isi akun contoh petugas") | `flutter run` |
| Emulator + backend di laptop | `flutter run --dart-define=API_URL=http://10.0.2.2:3000 --dart-define=ALLOW_MOCK_LOCATION=true` |
| HP asli + backend di laptop (satu WiFi/hotspot) | `flutter run --dart-define=API_URL=http://<IP-laptop>:3000` |
| HP asli + backend sudah deploy | `flutter run --dart-define=API_URL=https://<domain-backend>` |

- `10.0.2.2` = alamat laptop dari dalam emulator Android.
- `ALLOW_MOCK_LOCATION=true` hanya untuk emulator. Di HP asli jangan dipakai, karena pemeriksaan lokasi palsu adalah bagian dari pencegahan laporan palsu (Tabel 3).
- Build APK untuk demo: `flutter build apk --release --dart-define=API_URL=https://<domain-backend>`
- Push FCM: taruh `google-services.json` di `mobile/android/app/` (jangan di-commit). Tanpa file ini app tetap jalan dengan cek tugas berkala. Langkah lengkap: [03-verifikasi-dan-notifikasi.md](03-verifikasi-dan-notifikasi.md#menyalakan-fcm).

## Struktur `mobile/lib`

```
lib/
├── main.dart                     # MaterialApp, tema light/dark, shell (warga tanpa login)
├── app_keys.dart                 # navigatorKey, messengerKey, layarFokus
├── config.dart                   # API_URL, ALLOW_MOCK_LOCATION (--dart-define)
├── theme/
│   ├── app_theme.dart            # Token desain (lihat 00-design-system.md)
│   └── rivora_icons.dart         # RIcons: ikon Phosphor (font aset)
├── models/
│   ├── ai_result.dart            # Keluaran AI, format Lampiran C
│   ├── jenis_saluran.dart        # terbuka | gorong_gorong | inlet_jalan
│   ├── report.dart               # Laporan (backend 7.2/7.3: tugas, bukti)
│   ├── rw_risk.dart              # Risiko RW dari GET /rw/risk + titik di poligon
│   ├── session.dart              # Sesi petugas (pengguna bersarang)
│   ├── task.dart                 # Tugas petugas (backend 7.9)
│   └── verification.dart         # Hasil verifikasi + level risiko RW
├── services/
│   ├── api_client.dart           # HttpApiClient + MockApiClient
│   ├── location_service.dart     # Izin + posisi GPS
│   ├── repositories.dart         # Laporan (disimpan di HP), tugas, risiko RW
│   ├── session_store.dart        # Simpan/muat sesi
│   ├── task_watcher.dart         # Cek tugas berkala (notifikasi)
│   ├── push_service.dart         # Push FCM (opsional)
│   └── weather_service.dart      # Prakiraan hujan Open-Meteo
├── screens/
│   ├── login_screen.dart         # Masuk petugas (opsional, hanya role petugas)
│   ├── app_shell.dart            # Navigasi bawah
│   ├── home_screen.dart          # Beranda (hujan, lapor, tugas terdekat, peta, status)
│   ├── map_screen.dart           # Tab Peta
│   ├── lapor_flow.dart           # Penjelasan izin → izin lokasi → kamera
│   ├── camera_screen.dart        # Kamera in-app (tanpa galeri)
│   ├── report_form_screen.dart   # Konfirmasi + pilih jenis saluran
│   ├── result_screen.dart        # Hasil analisis AI
│   ├── reports_screen.dart       # Laporan saya
│   ├── report_detail_screen.dart # Detail + timeline
│   ├── tasks_screen.dart         # Tugas (petugas)
│   ├── task_detail_screen.dart   # Detail tugas
│   └── verify_screen.dart        # Verifikasi foto sesudah
├── widgets/                      # Komponen bersama (pictogram, risk_card, rivora_map, …)
└── utils/
    ├── format.dart               # Waktu, koordinat, desimal, jarak
    └── maps.dart                 # Buka Google Maps
```

Font: `mobile/assets/fonts/` (Atkinson Hyperlegible, OFL; ikon Phosphor Regular + Fill, MIT).

## Cek sebelum commit

```bash
cd mobile
dart format lib test
flutter analyze
flutter test
```
