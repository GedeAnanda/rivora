# Contoh HTML UI dasbor dengan referensi Notion

**Waktu:** 2026-11-08 10:56 sampai 10:59

**Apa yang diubah**
Membuat satu halaman contoh statis `docs/dashboard-docs/contoh-ui-notion.html`. Dasbor React di `dashboard/` tidak diubah.

Tujuannya supaya tim bisa menilai arah tampilan sebelum dasbor dirombak. Perubahan gaya di entri 09 terlalu halus untuk terlihat bedanya.

**Isi halaman contoh**
- Sidebar kiri seperti daftar halaman Notion: Sebelum hujan, Peta risiko, Prioritas, Tugas, Cek manual, Simulasi hujan.
- Judul besar bertracking rapat dengan pill sorotan pada kata kerja ("Bersihkan"), lalu paragraf serif.
- Callout hujan: 62 mm, lencana hujan lebat, tombol simulasi.
- Empat kartu aksen. Tiga kartu memakai warna level RW dari SRS (merah, oranye, hijau), satu kartu gelap midnight untuk tugas.
- Peta Leaflet dengan grid RW contoh, di sebelahnya panel "Kenapa skor ini?" berisi meter dan rumus.
- Tabel prioritas bergaya database Notion: nomor, saluran, pill kelas, keyakinan AI, umur laporan, skor, tombol Tugaskan.
- Papan kanban tugas: Baru, Dikerjakan, Selesai. Kartu selesai memuat foto sebelum dan sesudah.

**Keputusan**
- Warna level dan kelas tetap ikut SRS bagian 8. Tombol utama tetap teal RIVORA.
- Data di halaman ini karangan dan ditulis langsung di HTML.
- Leaflet dan font Inter serta Source Serif 4 dimuat dari CDN, jadi halaman butuh internet.
- Tata letak ini berbeda dari SRS dasbor bagian 5 (peta + panel kanan). Bila arah ini dipilih, SRS bagian 5 perlu diperbarui dan disepakati tim.

**Cara cek**
Buka `docs/dashboard-docs/contoh-ui-notion.html` langsung di peramban (klik dua kali).
Sudah dicek lewat tangkapan layar Chrome headless 1366 px: console bersih, tidak ada luapan horizontal.

**Belum dikerjakan**
- Perbaikan rumus skor yang terpotong ke dua baris sudah diterapkan, tetapi belum difoto ulang.
- Belum ada interaksi. Klik tombol dan wilayah RW tidak melakukan apa-apa.
