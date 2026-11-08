# Gaya tampilan dasbor mengikuti referensi Notion

**Waktu:** 2026-11-08 10:40 sampai 10:54

**Apa yang diubah**
Hanya `dashboard/src/index.css`. Tidak ada perubahan komponen atau logika.

Referensi dari Wildan: `design-notion.md` (gaya "kertas hangat"). Dipakai sebagai referensi saja. Bila bentrok dengan milik tim, milik tim yang dipakai.

**Yang diambil dari referensi**
| Hal | Sebelum | Sesudah |
|---|---|---|
| Kanvas halaman | `#f3f4f1` | `#f6f5f4` (kertas hangat) |
| Garis kartu | `#e1e0d9` | `rgba(0, 0, 0, 0.08)`, tanpa bayangan |
| Sudut kartu | 10px | 12px (tombol tetap 8px, lencana 9999px) |
| Teks | abu kebiruan | `#111111`, isi `#615d59`, redup `#757575` |
| Kepala dasbor | navy gelap | putih dengan garis tipis dan bayangan nav halus |
| Halaman login | gradien navy ke teal | kanvas datar + kartu putih bergaris (referensi melarang gradien) |
| Tagline | sans miring | serif miring (aksen editorial, seperti Lyon Text di referensi) |
| Lencana "Data contoh" | putih transparan | biru muda `#e6f3fe` |
| Toast | navy | midnight `#02093a` ("pulau gelap") |
| Huruf | system-ui | `Inter` bila terpasang, lalu system-ui. Tidak memuat font dari internet |

**Yang tetap milik kita (menang saat bentrok)**
- Warna level RW dan kelas sumbatan: SRS dasbor bagian 8, sama dengan aplikasi mobile. Bukan palet aksen Notion.
- Tombol aksi utama: teal merek RIVORA `#127a6c`, bukan biru Notion `#0075de`.
- Cincin "sedang ditugaskan": biru sesuai SRS FR-DB-04, sekarang `#0075de`.
- Banner simulasi oranye dan banner kuning "Tidak terhubung" sesuai SRS FR-DB-13 dan FR-DB-14.
- Struktur tata letak SRS bagian 5 (peta + panel kanan). Pola halaman pemasaran Notion (hero, kartu aksen, ilustrasi karakter) tidak dipakai karena dasbor adalah alat kerja.

**Cara cek**
`npm run dev`, buka http://localhost:5173, masuk dengan `lurah`.
Sudah dicek lewat tangkapan layar Chrome headless 1366x768: halaman login dan dasbor dengan detail saluran terbuka. `npm run build` sukses.

**Belum dikerjakan**
- Font Inter tidak dibundel. Di laptop tanpa Inter tampil Segoe UI.
- Tampilan dialog, tab Tugas, dan banner simulasi belum difoto ulang setelah perubahan gaya.
