# Dasbor Kelurahan RIVORA

React + Vite + Leaflet/OpenStreetMap. Peran C (AI dan dasbor). Acuan: SRS dasbor (`docs/dashboard/SRS.md`) dan kontrak API SRS backend bagian 7.

## Menjalankan

```bash
cd dashboard
cp .env.example .env     # VITE_USE_MOCK=1 memakai data contoh
npm install
npm run dev              # http://localhost:5173
```

Mode data contoh: masuk dengan username `lurah` dan password apa saja.
Pindah ke backend asli: `VITE_USE_MOCK=0` dan `VITE_API_URL` ke alamat backend, lalu jalankan ulang `npm run dev`.

### Alat uji di konsol peramban (hanya mode data contoh)

```js
__rivoraMock.lapor(21, 'berat')   // anggap ada laporan baru dari HP untuk saluran #21
__rivoraMock.verifikasi(3)        // anggap petugas mengirim foto bersih untuk tugas #3
```

Dalam 10 detik dasbor memuat ulang dan menampilkan perubahannya.

## Struktur

```
src/
├── App.jsx              # cek token -> Login atau Dashboard
├── api/client.js        # fetch + token + 401 + pilihan mock/asli
├── mocks/               # seed.js (data contoh), server.js (tiruan endpoint SRS 7, rumus SRS 9)
├── hooks/usePolling.js  # muat ulang tiap 10 detik
├── format.js            # label enum, warna (SRS 8), angka, waktu WIB
├── pages/               # Login.jsx, Dashboard.jsx
└── components/          # RiskMap, Legend, RainCard, DemoRainSlider, PriorityList, ManualCheckList,
                         # TaskList, RwDetail, SaluranDetail, BeforeAfter, AssignDialog, Toast, ...
```

Catatan perubahan: satu file per perubahan di `docs/dashboard-docs/`.
