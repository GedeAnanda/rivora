# Dua belas opsi logo tambahan

**Waktu:** 2026-11-08 10:00 sampai 10:20

**Apa yang diubah**
Membuat halaman galeri `public/brand/opsi-logo.html` berisi 12 arah logo baru untuk dipilih tim. Logo Mata Daun (entri 4) tetap ada sebagai pembanding. Belum ada yang dipasang ke dasbor.

**Daftar opsi**
01 Tetes Daun · 02 R Mengalir · 03 Gorong Bertunas · 04 Bukit Hujan · 05 Capung · 06 Teratai · 07 Kawung Air · 08 Riak · 09 Radar Daun · 10 Payung Daun · 11 Kampung Hijau · 12 Peta RW

**Catatan teknis**
- Semua simbol digambar sebagai SVG di dalam halaman (fungsi bantu `daun`, `tetes`, `hex`), warnanya lewat variabel `--d` (hijau), `--a` (biru), `--t` (navy) sehingga versi putih cukup mengganti variabel.
- Tulisan RIVORA di kartu memakai font Lexend hanya untuk pratinjau. Setelah dipilih, tulisan digambar ulang sebagai garis SVG dan opsi terpilih diekspor ke SVG/PNG seperti entri 4.

**Cara cek**
Buka `public/brand/opsi-logo.html` di peramban, atau http://localhost:5173/brand/opsi-logo.html saat `npm run dev`.
