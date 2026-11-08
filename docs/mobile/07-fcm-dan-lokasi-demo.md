# 07 · Firebase (FCM) dan Mode Lokasi Demo

**Tanggal:** 8 November 2026 · **Branch:** `feature/mobile`
**Acuan:** backend SRS FR-BE-16 (`POST /devices`), FR-BE-17 (verifikasi 30 m), FR-BE-21 (lokasi demo), bagian 11 (payload FCM); mobile SRS FR-MB-09

Tahap ini menyamakan app dengan permintaan B di Discord: proyek Firebase untuk notifikasi tugas, payload FCM, dan `lokasi_demo` untuk demo.

## 1. Membuat proyek Firebase (dikerjakan A)

| Langkah | Isi |
|---|---|
| 1 | [console.firebase.google.com](https://console.firebase.google.com) → **Create project**, nama `rivora`, Google Analytics **mati** |
| 2 | **Add app → Android**, package name **`id.rivora.rivora`** (`applicationId` di `mobile/android/app/build.gradle.kts`). Nickname bebas, SHA-1 tidak perlu untuk FCM |
| 3 | Download **`google-services.json`** → taruh di `mobile/android/app/`. **Jangan di-commit** (`.gitignore`: `**/google-services.json`) |
| 4 | Project settings → **Users and permissions** → Add member: email B, role **Editor** (B membuat service account untuk `firebase-admin` di backend) |

Lewati tombol "Next" untuk langkah SDK di konsol: plugin `com.google.gms.google-services` sudah terpasang dan hanya aktif kalau file JSON ada (`build.gradle.kts`). Setelah file ditaruh: `flutter clean && flutter run …`.

## 2. Kecocokan dengan backend

| Item | Backend | App | Status |
|---|---|---|---|
| Daftar token | `POST /devices {fcm_token}` + `Authorization: Bearer` | Dikirim setelah petugas masuk (`PushService.start` → `api.registerDevice`), juga saat token diperbarui | ✅ Sudah sejak tahap 03 |
| Jenis notifikasi | SRS bagian 11: `type: "tugas_baru"`; kode B (`notify/fcm.js`): `jenis: "tugas_baru"` | **Keduanya diterima** (`tugasIdDariNotifikasi`) | ✅ Diperbaiki di tahap ini |
| Data lain | `tugas_id`, `saluran_id`, `lat`, `lng` (string) | `tugas_id` membuka detail tugas; lainnya tidak wajib | ✅ |
| Verifikasi | multipart `foto`, `lat`, `lng`, `captured_at` | Sama | ✅ |
| `lokasi_demo=true` | Opsional, berlaku kalau backend `DEMO_MODE` aktif: laporan/verifikasi dipasang ke saluran demo, batas 30 m dilewati | Dikirim hanya di build **`LOKASI_DEMO=true`** | ✅ Baru |

Sebelum perbaikan, notifikasi dari kode backend saat ini (`jenis`) tetap muncul, tapi mengetuknya hanya membuka app, bukan detail tugas.

## 3. Mode lokasi demo

Masalah: wilayah pilot ada di Gedebage, sedangkan demo dan pitching dilakukan di tempat lain. Tanpa mode ini laporan masuk tanpa RW, dan verifikasi ditolak karena lebih dari 30 m.

| Build | `lokasi_demo` | Batas 30 m di app |
|---|---|---|
| Biasa | tidak dikirim | Diblokir sebelum kirim (sama seperti backend) |
| `--dart-define=LOKASI_DEMO=true` | `"true"` di `POST /reports` dan `POST /tasks/:id/verify` | Hanya peringatan "Mode demo: lokasi dipetakan ke saluran contoh." |
| Mode contoh (tanpa `API_URL`) | – | Hanya peringatan "Mode contoh: jarak tidak diperiksa." |

Hasil yang dipetakan backend tetap diberi label "Lokasi dipetakan ke saluran contoh" dari field `lokasi_demo` di respons (mobile SRS 6.3).

```bash
# APK untuk demo di tempat pitching (backend sudah deploy dengan DEMO_MODE=1)
flutter build apk --release --dart-define=API_URL=https://<domain-backend> --dart-define=LOKASI_DEMO=true
```

Jangan pakai `LOKASI_DEMO` untuk pilot sungguhan.

## 4. Lokasi palsu

Pertanyaan B: nama field flag lokasi palsu. App **tidak mengirim** field ini. Lokasi palsu ditolak di HP sebelum foto diambil (`Position.isMocked`, `camera_screen.dart`). Kalau backend ingin menyiapkan field opsional, disarankan satu nama, `lokasi_palsu`.

## Hasil uji

`flutter analyze`: **No issues found**. `flutter test`: **48 tes lulus** (`test/tahap07_test.dart`: payload `type`, payload `jenis`, pesan lain, `tugas_id` kosong). Build `--dart-define=LOKASI_DEMO=true` berhasil dikompilasi.

Belum teruji: notifikasi sungguhan, karena butuh `google-services.json` dari langkah 1 dan backend yang sudah deploy.
