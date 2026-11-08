# Kotak fokus di peta dihilangkan

**Waktu:** 2026-11-08 15:35

**Masalah**
Saat poligon RW atau pin saluran diklik, muncul kotak persegi biru muda di sekelilingnya. Wildan menilai kotak itu mengganggu dan menyarankan penanda pilihan mengikuti bentuk yang dipilih.

Kotak itu adalah garis fokus bawaan browser: klik memberi fokus ke elemen SVG, dan Chrome menggambar garis fokus berbentuk persegi seukuran kotak pembatas elemen. Dasbor sendiri sudah menandai RW terpilih dengan garis Samudra 3,5px yang mengikuti bentuk RW (`RiskMap.jsx`).

**Apa yang diubah**
`dashboard/src/index.css`: `.leaflet-container path.leaflet-interactive:focus { outline: none; }`. Hanya berlaku untuk bentuk di peta; fokus tombol dan isian lain tetap terlihat.

**Cara cek**
Masuk dengan `lurah`, klik salah satu RW di peta. Yang tampil hanya garis gelap mengikuti bentuk RW, tanpa kotak.
Sudah dicek lewat tangkapan layar 1440x900 dengan RW 02 terpilih dan terfokus. `npm run build` sukses.
