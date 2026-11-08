# Contoh UI dipindah ke server dasbor

**Waktu:** 2026-11-08 11:05

**Masalah**
Wildan melaporkan `docs/dashboard-docs/contoh-ui-notion.html` (entri 10) tidak bisa dibuka. File-nya sendiri utuh dan terbuka normal di Chrome headless lewat `file://`. Dugaan penyebab: klik di IDE hanya membuka teks, atau peta dari CDN (unpkg) terblokir.

**Apa yang diubah**
1. Memindahkan file ke `dashboard/public/contoh-ui/index.html`. Vite menyajikan folder `public/` apa adanya, jadi bisa dibuka lewat server dasbor yang sudah jalan.
2. Menyalin `leaflet.js` dan `leaflet.css` dari `dashboard/node_modules/leaflet/dist/` ke folder yang sama, dan mengganti tautan CDN dengan file lokal. Peta tidak lagi butuh unpkg.
3. File `docs/dashboard-docs/contoh-ui-notion.html` dihapus supaya tidak ada dua salinan.

**Cara buka**
Jalankan `npm run dev` di `dashboard/`, lalu buka:

http://localhost:5173/contoh-ui/index.html

Harus lengkap sampai `index.html`. Alamat `/contoh-ui/` saja akan menampilkan halaman login dasbor karena ditangkap routing React.

**Cara cek**
Sudah dicek lewat tangkapan layar Chrome headless di alamat di atas: halaman tampil utuh, peta dan panel "Kenapa skor ini?" muncul, rumus skor tidak terpotong lagi, console bersih.

**Belum dikerjakan**
- Font Inter dan Source Serif 4 masih dari Google Fonts. Tanpa internet halaman tetap terbuka dengan font sistem.
- Entri 10 masih menyebut lokasi file lama. Isinya tidak diubah supaya riwayat tetap utuh.
