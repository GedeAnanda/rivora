# Dasbor mengikuti rivora-brand-kit

**Waktu:** 2026-11-08 15:00

**Apa yang diubah**
Wildan menambahkan `dashboard/rivora-brand-kit/` (logo Ombak, palet biru air, huruf Atkinson Hyperlegible) dan meminta dasbor mengikutinya. Aplikasi mobile sudah memakai kit yang sama (commit `f09ad10` di `feature/mobile`).

**Langkah**
1. **Logo dan favicon:** isi `rivora-brand-kit/siap-tempel-dasbor/public/` disalin ke `dashboard/public/`, menimpa `favicon.svg` dan semua file di `public/brand/`. Halaman logo lama `public/brand/opsi-logo.html` dan `logo-rivora.html` (entri 04 dan 05) dihapus, sesuai arahan kit.
2. **Logo di layar:** tulisan "RIVORA" yang diketik dan ikon tetes air diganti file `brand/rivora-logo-putih.svg`, di kepala dasbor (tinggi 34px) dan di halaman login (44px). Kit melarang wordmark diketik ulang dengan font. Ukuran di atas minimum 96px.
3. **Warna merek:** variabel lama di `index.css` diisi nilai `token/dasbor-palet.css` (nama tidak berubah, jadi komponen tidak disentuh):

   | Variabel | Lama | Baru |
   |---|---|---|
   | `--teal` (aksi utama) | `#127a6c` | Laut `#0361C3` |
   | `--teal-gelap` (hover) | `#0d5e53` | Laut 700 `#024D9D` |
   | `--teal-muda` (terpilih) | `#e1f1ee` | Buih `#DFF2FE` |
   | `--navy`, `--air` (kepala, teks gelap) | `#17324d`, `#0b2b28` | Samudra `#04214B` |
   | `--latar` | `#f3f6f5` | Kabut `#F4FAFE` |
   | `--teks`, `--teks-2` | hijau gelap | Samudra, Batu 700 `#47566C` |
   | `--garis` | hitam 8% | Batu 300 `#D6E0EB` |
   | `--biru-tugas` | `#0075de` | Tirta 700 `#066784` (kit: supaya tidak tertukar dengan tombol) |

4. **Warna risiko dan kelas:** `src/format.js` memakai nilai kit, sama dengan `RivoraColors.light` di aplikasi:

   | | Titik/isi peta | Teks chip | Latar chip |
   |---|---|---|---|
   | Aman | `#2E9E6B` | `#17663F` | `#E3F3EA` |
   | Waspada | `#E9A23B` | `#8A4A00` | `#FCEFD6` |
   | Risiko tinggi | `#C8372D` | `#A51C14` | `#FBE4E1` |
   | Kelas bersih / ringan / sedang / berat / tidak terlihat | `#17663F` / `#5C6B0A` / `#9A4A06` / `#A51C14` / `#47566C` | sama | `#E3F3EA` / `#F1F4DC` / `#FCEBD9` / `#FBE4E1` / `#E8EDF3` |

   Poligon RW: `fillOpacity 0,32`, garis 1,6 (BRAND.md). Lencana level sekarang memakai teks/latar kit langsung, bukan campuran warna.
5. **Warna lain yang ikut:** banner kuning dan oranye simulasi, lencana hujan lebat, toast, keyakinan AI, label demo, bukti pembersihan, status tugas (Tirta 100/700), tab bersegmen (Batu 200), panel simulasi (Laut 900), lapisan gelap di foto login (Samudra), garis isian login (Batu 500), kaki login (Batu 200).
6. **Huruf:** Plus Jakarta Sans diganti Atkinson Hyperlegible (400 dan 700) dari Google Fonts, untuk login dan dasbor. Huruf ini dibuat Braille Institute untuk keterbacaan tinggi, cocok dengan sasaran lurah 30 tahun ke atas (entri 19).

**File**
`dashboard/public/favicon.svg`, `dashboard/public/brand/*`, `dashboard/index.html`, `dashboard/src/index.css`, `dashboard/src/format.js`, `dashboard/src/components/Lencana.jsx`, `RiskMap.jsx`, `Legend.jsx`, `dashboard/src/pages/Dashboard.jsx`, `Login.jsx`.

**Catatan untuk SRS**
SRS dasbor bagian 8 menulis warna kelas `#43A047 ... #607D8B` dan level `#43A047/#F57C00/#D32F2F`. Nilai itu sekarang diganti nilai kit karena aplikasi mobile sudah pindah ke kit, dan SRS meminta warna dasbor sama dengan mobile. Tabel di `docs/dashboard/SRS.md` bagian 8 perlu disesuaikan.

**Cara cek**
`npm run dev`, buka http://localhost:5173, tekan Ctrl+Shift+R. Lihat favicon Ombak di tab, logo di login dan kepala dasbor, tombol biru Laut.
Sudah dicek lewat tangkapan layar Chrome headless 1440x900: login, daftar prioritas, detail saluran. `npm run build` sukses, lint tanpa peringatan baru.

**Belum dikerjakan**
- `public/contoh-ui/index.html` (entri 10) masih memakai warna teal lama. Halaman itu hanya contoh dan bisa dihapus.
- Mode gelap dari kit (`tokens.css`) tidak dipasang; dasbor hanya punya tampilan terang.
- `--teks-redup` `#56667C` bukan warna kit: Batu 500 (4,2:1) terlalu pucat untuk teks kecil, jadi dipakai nilai di antara Batu 500 dan 700 (5,9:1) [ASUMSI].
