# Memasang Leaflet

**Waktu:** 2026-11-08 09:35

**Apa yang diubah**
`npm i leaflet react-leaflet`

**File berubah**
- `package.json`: dependensi `leaflet` ^1.9.4 dan `react-leaflet` ^5.0.0
- `package-lock.json`

**Alasan**
Peta risiko RW memakai Leaflet + OpenStreetMap (Tabel 12 proposal). react-leaflet 5 cocok dengan React 19.

**Cara cek**
`npm ls leaflet react-leaflet` menampilkan kedua paket tanpa error.
