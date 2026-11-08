# RIVORA

> "See The Flood Before You See The Water."

Platform prediksi dan pencegahan genangan berbasis kondisi saluran drainase.
Prototipe untuk **CR YOUTH 2026 Hackathon**, subtema Sustainable Development.
Tim **Abis Ini ke WDP**, Telkom University.

Petugas atau warga memotret saluran lewat aplikasi, AI vision menilai tingkat sumbatannya, lalu hasilnya digabung dengan prakiraan hujan dan kerentanan lokasi menjadi skor risiko per RW. Kelurahan mendapat daftar saluran yang perlu dibersihkan sebelum hujan, dan pembersihan dibuktikan dengan foto sebelum–sesudah.

**Siklus:** Lapor → Prediksi → Bertindak → Verifikasi

## Struktur repo

```
.
├── mobile/          # Aplikasi pelapor (Flutter, Android)
├── backend/         # REST API (Node.js + Express)
│   └── src/ai/      # Integrasi AI vision + validasi JSON
├── dashboard/       # Dasbor kelurahan (React + Leaflet + OpenStreetMap)
├── db/
│   ├── schema.sql   # Skema PostgreSQL + PostGIS
│   └── seed/        # Data contoh: poligon RW, titik genangan, laporan dummy
└── docs/
    ├── RENCANA_FINAL.md
    ├── SETUP_JAM0.md
    ├── API.md
    └── LAPORAN_PENGEMBANGAN.md
```

## Tech stack

| Komponen | Teknologi |
|---|---|
| Aplikasi pelapor | Flutter (Android) |
| Dasbor web | React, Leaflet, OpenStreetMap |
| Backend | Node.js, Express (REST API) |
| Basis data | PostgreSQL + PostGIS |
| AI vision | API model multimodal, keluaran JSON terstruktur |
| Data cuaca | Open-Meteo API, data terbuka BMKG |
| Data elevasi | DEMNAS (Badan Informasi Geospasial) |
| Notifikasi | Firebase Cloud Messaging |

## Skor risiko

```
Skor Risiko RW = 0,4 × Hujan + 0,4 × Sumbatan + 0,2 × Kerentanan   (semua 0–1)
```

Bobot adalah asumsi awal dan akan dikalibrasi saat pilot. Rincian: `docs/RENCANA_FINAL.md` bagian 4.

## Menjalankan

> Diisi di jam 0–1.

### Backend

```bash
# TODO
```

### Dashboard

```bash
# TODO
```

### Mobile

```bash
# TODO
```

Salin `.env.example` ke `.env` di folder yang sesuai sebelum menjalankan.

## Status fitur (cakupan prototipe, Tabel 3 proposal)

| Fitur | Status |
|---|---|
| Lapor foto + GPS | ⬜ |
| Analisis sumbatan AI | ⬜ |
| Peta risiko | ⬜ |
| Daftar prioritas sebelum hujan | ⬜ |
| Penugasan dan notifikasi | ⬜ |
| Verifikasi sebelum–sesudah | ⬜ |

Tahap lanjut (di luar prototipe): peringatan warga, mode kemarau, rekap dan ekspor.

## Tim

| Nama | Peran |
|---|---|
| I Gede Ananda Bela Persada | |
| Fatih Akram Wicaksono | |
| Wildan Panji Maulana | |
