# PRD & SRS · Aplikasi Pelapor RIVORA (Mobile)

**Pemilik:** A · Mobile developer · **Branch:** `feature/mobile`
**Versi:** 1.0 · 8 November 2026 · **Status:** usulan, disepakati di Discord
**Acuan:** proposal 3.1, 3.2, 6.2, Tabel 3, 8, 12, 13, 14, Lampiran C · `docs/backend/SRS.md` (kontrak data, bagian 7) · `docs/mobile/01-alur-lapor.md`

**Penanda:** **P0** wajib jalan di checkpoint jam 10 · **P1** setelah semua P0 hijau · **P2** kalau sempat · **[ASUMSI]** belum ditetapkan proposal · **[DEMO]** alat bantu presentasi, wajib disebut ke juri · ✅ sudah jadi · ⬜ belum.

---

# Bagian I · PRD

## 1. Tujuan

Aplikasi Android untuk petugas kebersihan, siskamling, dan warga (3.1). Aplikasi ini memegang dua ujung siklus RIVORA (3.2):

1. **Lapor:** memotret saluran langsung dari kamera, GPS dan waktu tercatat otomatis, lalu menampilkan hasil analisis AI.
2. **Verifikasi:** petugas menerima tugas lewat notifikasi, membersihkan saluran, lalu memotret ulang sebagai bukti.

## 2. Pengguna

| Pengguna | Login | Yang dilakukan |
|---|---|---|
| Warga | Tidak wajib **[ASUMSI]** | Lapor saluran, lihat status laporannya |
| Petugas kebersihan / siskamling | Wajib (akun dari kelurahan) | Lapor, terima tugas, kirim foto sesudah |

Proposal menjadikan petugas pelapor utama dan warga pelapor tambahan (Tabel 8, mitigasi partisipasi rendah).

## 3. Cakupan

**Masuk:** lapor foto + GPS, hasil AI, status laporan, login petugas, daftar tugas, notifikasi tugas (FCM), foto sesudah untuk verifikasi.

**Tidak masuk (Tabel 3 "tahap lanjut"):** peringatan warga di wilayah berisiko, mode kemarau, versi iOS.

## 4. Ukuran sukses

| Jam | Bukti |
|---|---|
| **5** | Foto dari HP asli → backend asli → hasil AI asli tampil di layar hasil |
| **8** | Laporan saya menampilkan status dari backend. Petugas bisa login dan melihat daftar tugas |
| **10** | Lurah menugaskan di dasbor → notifikasi masuk di HP petugas → foto sesudah → "terverifikasi bersih" |
| **10–11** | APK release mengarah ke backend HTTPS, terpasang di minimal 2 HP Android (6.2) |

---

# Bagian II · SRS

## 5. Alur layar

```
Beranda ─┬─► Lapor saluran ─► Kamera ─► Konfirmasi ─► Hasil AI ─► (id laporan disimpan di HP)
         │
         ├─► Laporan saya ─► Detail status (+ foto bukti bila sudah ditangani)
         │
         └─► Masuk petugas ─► Tugas saya ─► Detail tugas ─► Kamera ─► Hasil verifikasi
                                  ▲
                   Notifikasi FCM "Tugas baru"
```

## 6. Kebutuhan fungsional

### 6.1 Sudah jadi di tahap 01 (`docs/mobile/01-alur-lapor.md`)

| Kode | Kebutuhan | Prioritas | Status |
|---|---|---|---|
| FR-MB-01 | Foto langsung dari kamera in-app, **tanpa galeri** (3.2) | P0 | ✅ |
| FR-MB-02 | GPS dan waktu tercatat otomatis, lokasi palsu ditolak (3.2, Tabel 8) | P0 | ✅ |
| FR-MB-03 | Pilih jenis saluran: terbuka, gorong-gorong, inlet jalan (3.2) | P0 | ✅ |
| FR-MB-04 | Kirim `POST /reports`, tampilkan kelas, skor, penyebab, **keyakinan AI selalu tampil**, banner "Perlu dicek manual" (Tabel 8, Lampiran C) | P0 | ✅ mode contoh · ⬜ uji dengan backend asli |
| FR-MB-05 | Mode contoh (`MockApiClient`) bila `API_URL` kosong | P0 | ✅ |

### 6.2 Belum dikerjakan

**FR-MB-06 · Laporan saya (P1)** · Tabel 8 "status sudah ditangani beserta foto dikirim kembali ke pelapor"
- Setiap laporan yang berhasil dikirim disimpan di HP (`shared_preferences`): id, waktu, jenis saluran, kelas. Warga tanpa login tetap bisa melacak laporannya.
- Layar daftar → ketuk → `GET /reports/:id` → tampilkan label status (`dikirim` / `ditugaskan` / `ditangani` / `cek_manual`).
- Status `ditangani` → tampilkan foto bukti (`bukti.foto_sesudah_url`), kelas sesudah, dan waktu selesai.
- Tarik ke bawah untuk muat ulang.

**FR-MB-07 · Masuk petugas (P0)** · Tabel 12 "Autentikasi"
- `POST /auth/login`. Di layar ini hanya role `petugas` yang diterima **[ASUMSI]**. Role lain → "Akun ini bukan akun petugas".
- Token disimpan di `shared_preferences`, dikirim sebagai `Authorization: Bearer` ke endpoint petugas. `POST /reports` juga mengirim token bila ada, supaya pelapor tercatat.
- Tombol Keluar menghapus token. Respons 401 → kembali ke layar login.

**FR-MB-08 · Tugas saya (P0)** · 3.2 langkah 3
- `GET /tasks?mine=1`. Tugas `baru` dan `dikerjakan` di atas, `selesai` di bawah.
- Kartu: jenis saluran + RW, foto sebelum + kelas sebelum, catatan dari lurah, waktu ditugaskan.
- Detail tugas: tombol **Foto sesudah** (FR-MB-10). **P1:** tombol **Buka di peta** (`url_launcher` ke Google Maps dengan `lat,lng`).
- Daftar dimuat ulang saat layar dibuka, saat app kembali ke depan, dan saat ditarik ke bawah. Ini cadangan bila notifikasi tidak sampai (`docs/backend/SRS.md` FR-BE-15).

**FR-MB-09 · Notifikasi tugas (P0)** · Tabel 3 "Penugasan dan notifikasi", Tabel 12 "Firebase Cloud Messaging"
- Paket `firebase_core` + `firebase_messaging`. `google-services.json` dari proyek Firebase yang sama dengan service account backend.
- Setelah login: minta izin notifikasi (Android 13+), ambil token FCM, kirim `POST /devices`. Saat `onTokenRefresh` → kirim ulang.
- Payload dari backend: `data.type = "tugas_baru"`, `data.tugas_id`, `data.saluran_id` (semua string).
- App di belakang / tertutup: notifikasi tampil otomatis dari blok `notification`. Ketuk → buka detail tugas (`getInitialMessage`, `onMessageOpenedApp`).
- App di depan: Android tidak menampilkan notifikasi FCM otomatis → tampilkan banner/SnackBar "Tugas baru masuk" dan muat ulang daftar **[ASUMSI: tanpa `flutter_local_notifications`, supaya cepat]**.

**FR-MB-10 · Foto sesudah / verifikasi (P0)** · 3.2 langkah 4, Tabel 3
- Pakai ulang layar kamera tahap 01: tanpa galeri, GPS + waktu otomatis, tolak lokasi palsu.
- `POST /tasks/:id/verify` multipart: `foto`, `lat`, `lng`, `captured_at` (UTC), dengan token petugas.
- Hasil:
  - `verifikasi.sudah_bersih = true` → "Saluran terverifikasi bersih", foto sebelum dan sesudah berdampingan, kelas sesudah, keyakinan AI.
  - `sudah_bersih = false` → tampilkan catatan AI + tombol **Foto ulang**.
  - `verifikasi = null` → tampilkan `pesan` dari backend + tombol **Foto ulang**.
- Backend menolak bila posisi lebih dari 30 m dari saluran (`docs/backend/SRS.md` FR-BE-17). Pesan error ditampilkan apa adanya.

**FR-MB-11 · Tandai dikerjakan (P2)**
- Tombol **Mulai kerjakan** → `PATCH /tasks/:id { "status": "dikerjakan" }`.

### 6.3 Label demo [DEMO]

- Bila respons berisi `ai_sumber = "demo"`, layar hasil menampilkan label kecil "Hasil contoh (mode demo)".
- Bila `lokasi_demo = true`, tampilkan "Lokasi dipetakan ke saluran contoh". Keduanya supaya jujur di depan juri (`docs/backend/SRS.md` FR-BE-19, FR-BE-21).

## 7. Endpoint yang dipakai

| Fitur | Endpoint (`docs/backend/SRS.md` bagian 7) | Token |
|---|---|---|
| Lapor | `POST /reports` (7.2) | Opsional |
| Laporan saya | `GET /reports/:id` (7.3) | Opsional |
| Masuk petugas | `POST /auth/login` (7.1) | – |
| Simpan token FCM | `POST /devices` (7.11) | Petugas |
| Tugas saya | `GET /tasks?mine=1` (7.9) | Petugas |
| Foto sesudah | `POST /tasks/:id/verify` (7.10) | Petugas |
| Tandai dikerjakan (P2) | `PATCH /tasks/:id` (7.11) | Petugas |

## 8. Kebutuhan non-fungsional

| Kode | Kebutuhan |
|---|---|
| NFR-01 Perangkat | Android. Diuji di minimal 2 HP Android asli (6.2) |
| NFR-02 Jaringan | Timeout unggah 60 detik (analisis AI bisa sampai sekitar 40 detik). Pesan error Bahasa Indonesia, pesan dari backend ditampilkan apa adanya |
| NFR-03 Anti laporan palsu | Tidak ada akses galeri di seluruh app, termasuk verifikasi. Lokasi palsu ditolak kecuali build emulator (`ALLOW_MOCK_LOCATION`) |
| NFR-04 Izin | Kamera, lokasi, dan notifikasi diminta dengan penjelasan singkat. GPS mati → tombol ke Pengaturan |
| NFR-05 Build demo | `flutter build apk --release --dart-define=API_URL=https://<backend>`. Setelah backend HTTPS, `usesCleartextTraffic` dimatikan |
| NFR-06 Rahasia | `google-services.json` dan keystore tidak di-commit (sudah di `.gitignore`) |
| NFR-07 Konsistensi | Warna kelas sumbatan sama dengan dasbor (`docs/dashboard/SRS.md` bagian 8) |

## 9. Uji terima

| # | Skenario | Hasil yang diharapkan | FR |
|---|---|---|---|
| 1 | Lapor saluran berat ke backend asli | Hasil AI asli tampil, pin muncul di dasbor ≤ 10 detik | 04 |
| 2 | Lapor saluran tertutup | Banner "Perlu dicek manual", status `cek_manual` | 04 |
| 3 | Buka Laporan saya setelah lapor | Laporan tadi ada, status sesuai backend | 06 |
| 4 | Laporan sudah dibersihkan petugas | Status "Sudah ditangani" + foto bukti | 06 |
| 5 | Login dengan akun warga di layar petugas | Ditolak dengan pesan | 07 |
| 6 | Lurah menugaskan, app di belakang | Notifikasi muncul, ketuk → detail tugas | 09 |
| 7 | Lurah menugaskan, app di depan | Banner "Tugas baru masuk", daftar bertambah | 09 |
| 8 | Notifikasi tidak sampai | Tugas tetap muncul setelah tarik ke bawah | 08 |
| 9 | Foto sesudah saluran bersih | "Terverifikasi bersih", sebelum–sesudah tampil, status di dasbor jadi Selesai | 10 |
| 10 | Foto sesudah masih kotor | Catatan AI + tombol Foto ulang | 10 |
| 11 | Backend mati saat kirim | Pesan "Tidak bisa terhubung ke server", foto tidak hilang, bisa kirim ulang | 04 |

## 10. Urutan kerja A (Tabel 14)

| Jam | Pekerjaan A | Selesai bila |
|---|---|---|
| **0–1** | Setup Flutter + HP Android | ✅ |
| **1–5** | Alur lapor (FR-MB-01–05), lalu uji ke backend asli begitu `POST /reports` B jalan | ✅ mode contoh · **Checkpoint jam 5** |
| **5–8** | Laporan saya (FR-MB-06), login petugas (FR-MB-07), kerangka Tugas saya (FR-MB-08) | **Checkpoint jam 8** |
| **8–10** | FCM (FR-MB-09), foto sesudah (FR-MB-10), label demo | **Checkpoint jam 10**, lalu fitur dibekukan |
| **10–11** | Build APK release, pasang di 2 HP, jalankan uji terima bagian 9 | APK siap |
| **11–12** | Rekam video demo (wajib dikumpulkan) | Video jadi |

## 11. Yang dibutuhkan dari anggota lain

| Dari | Kebutuhan | Paling lambat |
|---|---|---|
| B | `POST /reports` jalan di laptop/cloud + alamatnya | Jam 5 |
| B | Akun `petugas1` dari data contoh + password demo (lewat Discord, bukan di repo) | Jam 6 |
| B | Proyek Firebase: `google-services.json` untuk A, service account untuk backend **[ASUMSI: B yang membuat]** | Jam 8 |
| B | URL backend HTTPS hasil deploy | Jam 10 |
| C | Konfirmasi warna kelas di dasbor sama dengan app | Jam 8 |
