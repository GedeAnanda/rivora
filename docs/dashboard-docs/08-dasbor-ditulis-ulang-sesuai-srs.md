# Dasbor ditulis ulang mengikuti PRD & SRS v1.0

**Waktu:** 2026-11-08 10:12 sampai 10:32

**Apa yang diubah**
Struktur dan perilaku dasbor disesuaikan dengan SRS dasbor (Dokumen 2) dan kontrak SRS backend bagian 7. File lama `src/lib/`, `src/mock/`, `src/components/*` (nama Indonesia) dihapus dan diganti.

**File**
| File | Isi | FR |
|---|---|---|
| `src/App.jsx` | Cek token, tampilkan Login atau Dashboard. 401 di mana pun -> kembali ke login | FR-DB-01 |
| `src/pages/Login.jsx` | Form username + password, hanya role `lurah`, token di `localStorage` | FR-DB-01 |
| `src/pages/Dashboard.jsx` | Tata letak SRS bagian 5: kepala (hujan + simulasi), peta, panel kanan bertab Prioritas/Tugas/Cek, panel detail di bawah daftar, kaki batas klaim | FR-DB-13, 15, 16 |
| `src/api/client.js` | Endpoint SRS 7: `/auth/login`, `/health`, `/rw/risk`, `/saluran`, `/saluran/:id`, `/priorities`, `/petugas`, `/tasks`, `POST /tasks`, `PUT /demo/hujan` | bagian 7 |
| `src/mocks/seed.js`, `src/mocks/server.js` | Data contoh deterministik + tiruan endpoint dengan bentuk respons persis SRS 7 dan rumus persis SRS 9 (kerentanan 9.2, kalimat alasan 9.5) | FR-DB-17 |
| `src/hooks/usePolling.js` | Muat ulang tiap 10 detik, data terakhir tetap tampil saat gagal | FR-DB-13 |
| `src/format.js` | Warna kelas dan level SRS bagian 8 (sama dengan `sumbatan_style.dart` mobile), label Indonesia, desimal koma, waktu WIB, umur relatif | bagian 8 |
| `components/RiskMap.jsx`, `Legend.jsx` | Poligon RW per level, "belum ada data" abu-abu putus-putus, pin per kelas, cincin biru untuk saluran yang ditugaskan, `fitBounds` sekali saja | FR-DB-03, 04, 05 |
| `components/RainCard.jsx`, `DemoRainSlider.jsx` | Kartu hujan dari `meta`. Slider [DEMO] hanya muncul bila `/health` `demo_mode: true`, dikirim saat dilepas, tombol kembali ke prakiraan asli | FR-DB-02, 14 |
| `components/PriorityList.jsx`, `ManualCheckList.jsx`, `TaskList.jsx` | Daftar prioritas urut `peringkat` backend, tab Cek, tab Tugas dikelompokkan Baru/Dikerjakan/Selesai | FR-DB-07, 08, 11 |
| `components/RwDetail.jsx` | "Kenapa skor ini?": angka dari `properties.komponen` dan `alasan` apa adanya, daftar saluran di RW | FR-DB-06 |
| `components/SaluranDetail.jsx`, `BeforeAfter.jsx`, `Foto.jsx` | Foto terbaru (klik perbesar), kelas, keyakinan AI, penyebab, riwayat, label "Bukti pembersihan" dan "contoh demo", sebelum dan sesudah | FR-DB-09, 12 |
| `components/AssignDialog.jsx`, `Toast.jsx` | Pilih petugas (+ jumlah tugas aktif), catatan, toast sesuai `notifikasi`, pesan 409 | FR-DB-10 |
| `README.md` | Cara jalan, akun data contoh, alat uji konsol | |

**Keputusan dan asumsi**
- Dasbor tidak menghitung skor sama sekali. Simulasi hujan sekarang lewat `PUT /demo/hujan` (FR-BE-20), bukan dihitung di peramban seperti entri 3.
- Grafik hujan per jam dari entri 3 dibuang karena `meta` di SRS 7.4 tidak membawa data per jam.
- Kalimat alasan di data contoh memakai "sedang atau berat" (bukan tanda pisah). Di backend asli, kalimat dari backend ditampilkan apa adanya.
- Ukuran target desktop >= 1280x720 (`min-width: 1024px`), tidak ada tampilan ponsel (SRS dasbor bagian 13).
- [DEMO] Di data contoh, petugas Euis Rahmawati dianggap belum punya token FCM supaya toast "notifikasi tidak terkirim" bisa dicoba.
- [DEMO] `window.__rivoraMock.lapor()` dan `.verifikasi()` hanya ada di mode data contoh, untuk latihan alur tanpa backend.

**Cara cek** (`npm run dev`, masuk dengan `lurah`)
- Peta: 12 RW dengan warna campuran, RW 03 abu-abu putus-putus (belum ada data), pin per kelas, cincin biru di saluran RW 07.
- Klik RW: panel menampilkan Hujan, Sumbatan, Kerentanan dengan rumus `nilai × bobot = kontribusi` dan kalimat alasan.
- Geser Simulasi ke 80 mm lalu lepas: banner oranye "SIMULASI DEMO", skor naik, toast "RW 05: Aman → Waspada". Tombol putar balik mengembalikan ke 62 mm.
- Tugaskan saluran teratas: dialog petugas, toast "Tugas dikirim ke ...", kartu berganti nama petugas, tab Tugas bertambah.
- Konsol `__rivoraMock.verifikasi(3)`: dalam 10 detik tugas pindah ke Selesai dan warna RW turun.

Sudah dicek lewat tangkapan layar Chrome headless di 1366x768: login, peta, panel RW, detail saluran, simulasi 80 mm, dialog tugas, tab Tugas setelah verifikasi. Console bersih, `npm run build` sukses. Lint menyisakan 1 peringatan `set-state-in-effect` di `DemoRainSlider.jsx` (menyamakan slider dengan nilai dari backend), sengaja dibiarkan.

**Belum dikerjakan**
- Uji dengan backend asli (menunggu Jajang).
- Memasang logo dari entri 4/5 ke kepala dasbor dan favicon.
