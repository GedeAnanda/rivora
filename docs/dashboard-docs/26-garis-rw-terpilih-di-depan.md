# Garis RW terpilih tidak tertimpa RW tetangga

**Waktu:** 2026-11-08 15:55

**Masalah**
Garis tepi gelap RW terpilih tertutup sebagian oleh RW tetangga, karena poligon yang digambar belakangan berada di atas.

**Apa yang diubah** (`dashboard/src/components/RiskMap.jsx`)
- Komponen `RwPoligon` memanggil `bringToFront()` saat RW dipilih atau sedang berkedip (sorot perubahan level), sehingga garis tepinya utuh di semua sisi.
- Pin saluran dan cincin "sedang ditugaskan" dipindah ke `pane="markerPane"`, lapisan di atas poligon. Tanpa ini, RW yang dibawa ke depan akan menutupi pin di dalamnya.

**Cara cek**
Masuk dengan `lurah`, klik RW mana pun. Garis gelap mengelilingi seluruh RW, pin tetap terlihat dan bisa diklik.
Sudah dicek lewat tangkapan layar 1440x900 dengan RW 02 terpilih. `npm run build` sukses.
