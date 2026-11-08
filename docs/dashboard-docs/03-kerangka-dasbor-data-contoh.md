# Kerangka dasbor dengan data contoh

**Waktu:** 2026-11-08 09:40 sampai 09:53

**Apa yang diubah**
1. Membuang file bawaan template yang tidak dipakai: `src/App.css`, `src/assets/`, `README.md` bawaan (diganti README dasbor).
2. `index.html`: `lang="id"`, judul tab "RIVORA Dasbor Kelurahan".
3. `src/main.jsx`: memuat `leaflet/dist/leaflet.css`.
4. Menulis ulang `src/App.jsx` dan `src/index.css`.
5. Menambah logika skor, lapisan data, data contoh, dan komponen (daftar di bawah).

**File baru**
| File | Isi |
|---|---|
| `src/lib/risk.js` | Rumus skor `0,4 H + 0,4 S + 0,2 K`, ambang level (0,40 / 0,70), H = mm/100, hujan lebat >= 50 mm, bobot keyakinan, label Indonesia, format angka |
| `src/api/client.js` | Satu pintu data. `VITE_USE_MOCK=1` pakai `src/mock`, `0` panggil backend (`/rw/risk`, `/priorities`, `/reports/:id`, `/users?role=petugas`, `POST /tasks`) |
| `src/mock/data.js` | Data contoh Kelurahan Rancabolang (Gedebage): 12 poligon RW ilustrasi, 31 saluran, 4 petugas, 2 titik genangan, prakiraan hujan 24 jam |
| `src/mock/api.js` | Tiruan endpoint dengan bentuk respons yang sama seperti `KEBUTUHAN_API.md` |
| `src/components/PetaRisiko.jsx` | Peta Leaflet: poligon RW berwarna per level, pin saluran per kelas sumbatan, titik genangan, legenda (bisa dilipat, tertutup di ponsel) |
| `src/components/PanelSkor.jsx` | Panel "Kenapa skor ini?": nilai H/S/K, bobot, kontribusi, catatan asumsi |
| `src/components/Prakiraan.jsx` | Total hujan 24 jam, grafik per jam dengan tooltip, jam puncak, slider Simulasi hujan [DEMO] |
| `src/components/DaftarPrioritas.jsx` | Daftar prioritas urut skor + tombol Tugaskan, bagian "Perlu cek manual" dan "Sudah ditangani" |
| `src/components/DetailLaporan.jsx` | Laci detail: foto (atau foto sebelum dan sesudah), hasil AI Lampiran C, keyakinan AI, hasil verifikasi, riwayat |
| `src/components/DialogTugas.jsx` | Pilih petugas lalu kirim tugas |
| `src/components/Ikon.jsx`, `Lencana.jsx` | Ikon garis dan lencana level/kelas (status selalu ikon + teks, tidak hanya warna) |
| `.env.example` | `VITE_API_URL`, `VITE_USE_MOCK`, `VITE_KELURAHAN_ID` |
| `README.md` | Cara menjalankan dan peta komponen |
| `KEBUTUHAN_API.md` | Usulan bentuk respons API untuk backend (Jajang) |

**Keputusan dan asumsi**
- Semua angka ambang dan bobot mengikuti `docs/RENCANA_FINAL.md` bagian 4 dan ditandai [ASUMSI] di kode.
- Kerentanan di data contoh: `0,5 x skor elevasi + 0,5 x kedekatan`, kedekatan = `1 - jarak/1500 m` [ASUMSI baru, untuk data contoh saja].
- Skor resmi dihitung backend. Dasbor hanya menghitung ulang saat Simulasi hujan [DEMO] aktif, memakai H/S/K dari backend.
- Warna: kepala navy dan tombol teal mengikuti wireframe proposal (Gambar 3). Level RW hijau/kuning/merah. Kelas sumbatan memakai satu rona biru muda ke tua supaya tidak tertukar dengan warna level.
- Data dimuat ulang otomatis tiap 30 detik.

**Cara cek**
```bash
cd dashboard
npm run dev      # buka http://localhost:5173
npm run build    # harus sukses tanpa error
```
- Klik poligon RW: panel "Kenapa skor ini?" muncul.
- Klik item prioritas atau pin: peta terbang ke saluran dan laci detail terbuka.
- Klik Tugaskan, pilih petugas, Kirim tugas: status item berubah jadi nama petugas · Baru.
- Buka "Simulasi hujan untuk demo", centang, geser: warna RW dan urutan prioritas berubah, ada lencana SIMULASI.
- Saluran RW 05 yang "Sudah ditangani" menampilkan foto sebelum dan sesudah serta hasil verifikasi AI.

Sudah dicek dengan tangkapan layar Chrome headless di lebar 1440 px dan 390 px: tidak ada luapan horizontal dan console bersih.

**Belum dikerjakan**
- Foto asli (data contoh belum punya foto, tampil kotak "Foto belum tersedia").
- Halaman login lurah (menunggu keputusan backend apakah endpoint dasbor butuh token).
- Peringatan linter `set-state-in-effect` di `App.jsx` (pemuatan data saat awal) dibiarkan, tidak memengaruhi fungsi.
