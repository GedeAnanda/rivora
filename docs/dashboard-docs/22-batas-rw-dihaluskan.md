# Batas RW di data contoh dihaluskan

**Waktu:** 2026-11-08 15:10

**Apa yang diubah**
Wildan menilai peta terlalu kaku dan kotak-kotak. Penyebabnya poligon RW di data contoh: grid 4x3 yang sudutnya hanya digeser sedikit. Sekarang tiap garis batas RW dibuat berkelok lalu dihaluskan, sehingga peta terlihat seperti batas wilayah sungguhan.

**Cara kerja** (`dashboard/src/mocks/seed.js`)
1. Titik sudut grid tetap seperti sebelumnya.
2. Tiap sisi antara dua titik sudut diberi 3 titik antara yang digeser tegak lurus secara acak tetap (seed sendiri `8112026`). Besar geseran 20% panjang sisi untuk batas antar-RW dan 16% untuk tepi luar kelurahan, mengecil di dekat ujung sisi (`sin`), sehingga sudut tetap bertemu.
3. Garis dihaluskan dengan algoritma Chaikin tiga kali.
4. **Satu garis batas dipakai bersama dua RW tetangga** (disimpan di `cacheTepi`, dibalik urutannya untuk sisi lawan). Karena itu tidak ada celah atau tumpang tindih antar-RW.
5. RNG batas dipisah dari RNG data, jadi letak saluran, kelas, laporan, dan skor tetap sama seperti sebelumnya.

**Yang tidak berubah**
- Hanya data contoh (`VITE_USE_MOCK=1`). Dengan backend asli, bentuk RW mengikuti poligon dari seed backend (digambar Jajang di geojson.io, SRS backend FR-BE-18).
- Gaya poligon tetap sesuai brand kit: isi 0,32, garis 1,6.

**Cara cek**
`npm run dev`, masuk dengan `lurah`, lihat peta.
Sudah dicek lewat tangkapan layar Chrome headless 1440x900: batas RW berkelok, tepi kelurahan tidak lagi berbentuk persegi, tidak ada celah antar-RW. `npm run build` sukses.

**Belum dikerjakan**
- Titik saluran ditempatkan dengan interpolasi di dalam kotak asal. Karena batas berkelok, titik yang dekat tepi bisa sedikit keluar dari poligon RW-nya. Tidak terlihat di tangkapan layar saat ini.
