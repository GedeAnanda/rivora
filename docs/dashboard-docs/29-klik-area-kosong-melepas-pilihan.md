# Klik area kosong peta melepas pilihan

**Waktu:** 2026-11-08 16:30

**Apa yang diubah**
Permintaan Wildan: setelah titik diklik (titik bercincin gelap), klik di luar titik harus mengembalikan titik ke tampilan biasa. Sebelumnya pilihan baru hilang lewat tombol "Kembali ke daftar".

Sekarang klik di area kosong peta (bukan titik dan bukan poligon RW) melepas pilihan saluran atau RW: cincin gelap hilang dan panel kanan kembali ke daftar. Klik pada RW lain tetap memilih RW itu; klik pada titik lain tetap memilih titik itu.

**File**
| File | Isi |
|---|---|
| `dashboard/src/components/RiskMap.jsx` | Komponen `KlikKosong` (`useMapEvents`): memanggil `onKlikKosong` bila target klik bukan `.leaflet-interactive`. Pemeriksaan ini perlu karena Leaflet meneruskan klik titik dan poligon ke peta juga |
| `dashboard/src/pages/Dashboard.jsx` | `onKlikKosong={tutupDetail}` (fungsi yang sama dengan tombol "Kembali ke daftar") |

**Cara cek**
Tekan Ctrl+Shift+R. Klik satu titik (cincin gelap, detail terbuka), lalu klik area peta di luar wilayah RW.
Sudah dicek dengan klik mouse sungguhan di Chrome headless: klik titik membuka detail dan memberi cincin gelap; klik area kosong menutup detail dan menghapus cincin; klik titik lain membuka detail lagi. `npm run build` sukses.

**Catatan**
Wilayah kelurahan menutupi sebagian besar peta, jadi area kosong ada di luar batas kelurahan. Klik di dalam wilayah akan memilih RW (menampilkan "Kenapa skor ini?"), dan cincin gelap pada titik juga hilang karena pilihan berpindah ke RW.
