# Peta tidak melompat saat titik diklik

**Waktu:** 2026-11-08 16:10

**Masalah**
Saat titik saluran diklik, warna wilayah RW tampak bergeser lalu kembali ke tempatnya. Penyebabnya dua:
1. Peta memakai `flyTo`, yang memperkecil lalu memperbesar peta sambil bergeser.
2. Leaflet hanya menggambar poligon 10% melebihi layar (padding bawaan renderer SVG) dan menggambar ulang di akhir gerakan, sehingga bagian yang baru masuk layar muncul tiba-tiba.

**Apa yang diubah** (`dashboard/src/components/RiskMap.jsx`)
- `flyTo` diganti `panTo` (geser 0,45 detik tanpa mengubah zoom) bila zoom sudah 16 atau lebih; bila belum, `setView` ke zoom 16 dengan animasi zoom biasa.
- Renderer SVG poligon dan pin memakai `padding: 1` (area gambar selebar satu layar di tiap sisi), jadi tidak ada bagian yang terpotong lalu muncul saat peta digeser.
- Pin memakai renderer sendiri di `markerPane` (pengganti `pane="markerPane"` dari entri 26), tetap di atas poligon.

**Cara cek**
Tekan **Ctrl+Shift+R** (renderer baru hanya berlaku setelah peta dibuat ulang). Klik beberapa titik berturut-turut: peta bergeser halus, warna RW tidak lagi bergeser lalu melompat.
Sudah dicek: klik mouse sungguhan pada ke-21 titik di Chrome headless, semua membuka detail saluran. `npm run build` sukses. Gerakan animasi sendiri belum direkam frame demi frame.
