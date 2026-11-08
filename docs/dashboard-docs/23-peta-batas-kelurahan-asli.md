# Peta data contoh memakai batas Kelurahan Rancabolang asli

**Waktu:** 2026-11-08 15:25

**Apa yang diubah**
Wildan menilai peta di entri 22 masih tampak persegi dan simetris, tidak seperti wilayah sungguhan. Penyebabnya, data contoh masih berupa grid 4x3 buatan sendiri, dan letaknya ternyata sekitar 2 km di utara Rancabolang yang sebenarnya.

Sekarang:
1. **Batas kelurahan asli** diambil dari OpenStreetMap: Kelurahan Rancabolang, Kecamatan Gedebage, relation 13290131 (lewat Nominatim). Wilayahnya memanjang di antara Jalan Tol Padalarang-Cileunyi dan Bulevar Selatan.
2. **12 RW ilustrasi** dibuat dengan sel Voronoi di dalam batas itu: 12 titik benih tersebar (jarak minimum, RNG tetap), diratakan dua kali dengan algoritma Lloyd, lalu tiap sel dipotong batas kelurahan. Luas tiap RW 6,8 sampai 11,5% wilayah. Batas RW resmi tidak tersedia terbuka, jadi tetap ditandai ilustrasi di legenda.
3. Hasilnya disimpan sekali sebagai `src/mocks/rw-rancabolang.json` (4,7 KB). Dasbor tidak butuh pustaka tambahan saat berjalan.

**File**
| File | Isi |
|---|---|
| `dashboard/src/mocks/rw-rancabolang.json` | Batas kelurahan (66 titik) dan 12 poligon RW, koordinat `[lng, lat]` 6 desimal |
| `dashboard/src/mocks/buat-rw-rancabolang.mjs` | Skrip pembuat JSON di atas (d3-delaunay, polygon-clipping). Hanya untuk membuat ulang, tidak ikut dasbor |
| `dashboard/src/mocks/seed.js` | Grid, garis berkelok, dan Chaikin dari entri 22 dihapus. Saluran ditempatkan acak tetap di dalam poligon RW (cek titik-dalam-poligon, menjauhi tepi). Elevasi relatif ilustrasi: makin ke selatan dan timur makin rendah. Dua titik genangan langganan di RW terendah |
| `dashboard/src/components/RiskMap.jsx` | Titik tengah awal peta dipindah ke Rancabolang (`-6.965, 107.695`) sebelum `fitBounds` |

**Keputusan dan asumsi**
- [ASUMSI data contoh] Elevasi relatif dari arah selatan-timur, bukan DEMNAS. Nilai asli dihitung backend (SRS backend 9.2).
- [ILUSTRASI] Titik genangan "Jl. Rancabolang" dan "ujung selatan Rancabolang" diletakkan di pusat RW terendah, bukan lokasi genangan yang terverifikasi.
- Letak saluran, kelas, dan skor berubah dari sebelumnya karena RW dan urutan acaknya berubah. Isi rencana per RW (`RENCANA`: RW tanpa data, RW demo, dan seterusnya) tetap.
- Data OSM berlisensi ODbL; atribusi "© OpenStreetMap contributors" sudah tampil di pojok peta.

**Cara cek**
Masuk dengan `lurah` di http://localhost:5173, tekan Ctrl+Shift+R.
Sudah dicek lewat tangkapan layar 1440x900: peta menampilkan bentuk kelurahan asli dengan RW tidak beraturan, daftar prioritas terisi. `npm run build` sukses.

**Belum dikerjakan**
- Dengan backend asli, poligon RW tetap dari seed Jajang. File JSON ini bisa dibagikan ke Jajang bila ia ingin memakai batas kelurahan yang sama di `db/seed/`.
