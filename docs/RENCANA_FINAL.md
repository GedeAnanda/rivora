# RIVORA — Rencana Final Hackathon CR YOUTH 2026

> "See The Flood Before You See The Water."
> Tim **Abis Ini ke WDP** · Subtema **Sustainable Development** · Telkom University

**Acuan isi produk:** `CR YOUTH 2026_HACKATHON_Abis Ini ke WDP_Proposal fix 3.pdf`. Acuan aturan lomba: Guidebook + pengumuman Discord.
Semua keputusan di bawah merujuk ke bagian/tabel proposal. Hal yang tidak tertulis di proposal ditandai:

- **[ASUMSI]**: angka/aturan teknis yang proposal belum tetapkan. Boleh diubah tim, tapi sebut sebagai asumsi saat pitch.
- **[DEMO]**: alat bantu presentasi, bukan fitur produk.

---

## Aturan lomba yang membentuk rencana ini (Guidebook + pengumuman Discord)

- **Hackathon: Minggu, 8 November 2026 (12 jam). Final Presentation: Senin, 9 November 2026 (H+1).**
- Prototipe **wajib selaras dengan proposal**. Itu alasan setiap keputusan di sini diberi rujukan tabel.
- Aktivitas dipantau panitia lewat **Discord** dan **riwayat commit/push GitHub** → repo dibuat di jam 0, commit kecil dan sering dari akun masing-masing.
- **Code freeze:** setelah batas pengumpulan, dilarang ada commit lagi.
- Wajib dikumpulkan lewat formulir panitia sebelum deadline: **tautan repo GitHub, video demo produk, laporan pengembangan, PPT pitching, lembar pernyataan orisinalitas** (format di Guidebook).
- Penilaian final = **proposal + laporan pengembangan + presentasi** → laporan pengembangan sama penting dengan demo.
- Format dokumen (termasuk lembar orisinalitas) ada di Guidebook Final: https://canva.link/b4qfy0uhgz5ea3a. Cek sebelum jam 0.

---

## 0. Yang diubah dari rencana sebelumnya

| Rencana sebelumnya | Sekarang (selaras proposal) | Rujukan |
|---|---|---|
| Memasukkan saran juri WIA (proyek Suarakyat) | **Dihapus.** WIA lomba lain. Uji kasus ujung tetap ada, tapi dasarnya mitigasi risiko di proposal sendiri | Tabel 8 |
| Supabase sebagai backend + Express kecil khusus AI/skor | **Node.js + Express REST API** jadi satu-satunya pintu untuk app dan dasbor. DB **PostgreSQL + PostGIS** (boleh di-host di layanan cloud mana pun) | Tabel 12 |
| Push notification FCM dipotong | **FCM masuk cakupan**, dikerjakan jam 8–10 | Tabel 3, 12, 14 |
| Kerentanan diisi manual | **Elevasi relatif (DEMNAS) + jarak ke titik genangan langganan** | Tabel 2 |
| Timeline versi sendiri | **Ikut Tabel 14.** Hanya jam 11–12 disesuaikan dengan aturan pengumpulan (lihat bagian 8) | Tabel 14 |
| Cadangan: ganti ke PWA | **Tetap Flutter (Android).** Darurat: build Flutter Web dari kode yang sama | 3.1, Tabel 12 |
| Slider "Simulasi Hujan" sebagai fitur | Hanya **[DEMO]** override nilai hujan. Fitur aslinya tetap prakiraan Open-Meteo | Tabel 2 |

---

## 1. Produk yang didemokan

RIVORA terdiri dari dua bagian (3.1):

1. **Aplikasi pelapor** (Flutter, Android) untuk petugas kebersihan, siskamling, dan warga.
2. **Dasbor web** untuk kelurahan, kecamatan, dan dinas.

### Cakupan prototipe 12 jam (Tabel 3, fitur tanpa tanda "tahap lanjut")

| Fitur | Pengguna | Wujud di demo |
|---|---|---|
| Lapor foto + GPS | Petugas, warga | Foto **langsung dari kamera** (galeri tidak bisa). GPS dan waktu tercatat otomatis. Pilih jenis saluran: terbuka, gorong-gorong, inlet jalan |
| Analisis sumbatan AI | Sistem | Kelas sumbatan (bersih/ringan/sedang/berat/tidak terlihat), penyebab dominan, tingkat keyakinan. **Keyakinan selalu ditampilkan** (Tabel 8) |
| Peta risiko | Kelurahan, dinas | Leaflet + OSM: poligon RW berwarna aman/waspada/risiko tinggi + pin saluran bermasalah |
| Daftar prioritas sebelum hujan | Kelurahan | Saluran diurutkan dari skor tertinggi saat hujan lebat diprediksi |
| Penugasan dan notifikasi | Lurah, petugas | Lurah klik Tugaskan → petugas dapat notifikasi FCM → status tugas terpantau di dasbor |
| Verifikasi sebelum–sesudah | Petugas, sistem | Petugas foto ulang → AI bandingkan sebelum vs sesudah → skor RW diperbarui → status "sudah ditangani" + foto bukti terlihat oleh pelapor (Tabel 8) |

### Di luar cakupan hari ini (cukup disebut di pitch sebagai roadmap)

Peringatan warga, mode kemarau, rekap & ekspor (Tabel 3, "tahap lanjut"); integrasi LAPOR! dan Command Center; model deteksi khusus YOLOv8; model ML gradient boosting (2.2, 3.3).

---

## 2. Siklus kerja di prototipe (3.2)

1. **Lapor.** Kamera in-app → pilih jenis saluran → kirim. Backend panggil AI vision → hasil JSON (format Lampiran C) tampil di HP.
2. **Prediksi.** Skor risiko per RW = hujan 24 jam ke depan + sumbatan terbaru + kerentanan lokasi → level aman/waspada/risiko tinggi.
3. **Bertindak.** Saat hujan lebat diprediksi, dasbor menampilkan daftar saluran prioritas. Lurah menugaskan petugas lewat notifikasi.
4. **Verifikasi.** Petugas foto sesudah dibersihkan. AI membandingkan, skor RW turun, pekerjaan tercatat, dan laporan ini menambah dataset drainase.

---

## 3. Tech stack (Tabel 12)

| Komponen | Teknologi | Catatan hari ini |
|---|---|---|
| Aplikasi pelapor | Flutter (Android) | Kamera, GPS, unggah laporan, terima notifikasi tugas |
| Dasbor web | React + Leaflet + OpenStreetMap | Proposal: "Flutter Web atau React". Dipilih React karena Leaflet native di JS |
| Backend | Node.js + Express (REST API) | Autentikasi, mesin skor risiko, penjadwalan ambil prakiraan hujan |
| Basis data | PostgreSQL + PostGIS | Data spasial laporan, titik saluran, poligon RW |
| AI vision | API model multimodal, keluaran JSON terstruktur | Pakai mode structured output / JSON schema dari provider yang dipilih |
| Data cuaca | Open-Meteo API (+ data terbuka BMKG) | `hourly=precipitation`, 24 jam ke depan, per centroid kelurahan |
| Data elevasi | DEMNAS (BIG) | Lihat bagian 9 |
| Notifikasi | Firebase Cloud Messaging | Tugas ke petugas |
| Hosting & kolaborasi | Layanan cloud, GitHub, Figma | API key di `.env`, sertakan `.env.example` |

---

## 4. Mesin skor risiko (3.3, Tabel 2)

```
Skor Risiko RW = 0,4 × Hujan + 0,4 × Sumbatan + 0,2 × Kerentanan     (semua 0–1)
```

Bobot 0,4/0,4/0,2 = asumsi awal dari proposal, akan disesuaikan saat pilot.

| Komponen | Cara hitung di prototipe |
|---|---|
| **Hujan (H)** | Total prakiraan hujan 24 jam (Open-Meteo, mm) ÷ 100, maksimal 1 **[ASUMSI: 100 mm = batas atas kategori hujan lebat BMKG]** |
| **Sumbatan (S)** | Rata-rata tertimbang `skor_sumbatan` laporan **terbaru tiap saluran** di RW (Tabel 2). Bobot keyakinan: tinggi 1,0 / sedang 0,6 / rendah 0,3 **[ASUMSI]**. Kelas "tidak terlihat" **tidak dihitung** dan ditandai "perlu cek manual" (3.2, Tabel 8) |
| **Kerentanan (K)** | 0,5 × elevasi relatif (makin rendah dibanding RW lain di kelurahan → makin rentan) + 0,5 × kedekatan ke titik genangan langganan (PostGIS `ST_Distance`) **[ASUMSI bobot 0,5/0,5]** |

**Level** **[ASUMSI]**: aman < 0,40 · waspada 0,40–0,69 · risiko tinggi ≥ 0,70.

**Daftar prioritas** **[ASUMSI turunan rumus]**: skor saluran = 0,4 × H(RW) + 0,4 × skor_sumbatan saluran + 0,2 × K(RW), diurutkan menurun. Mode "hujan lebat diprediksi" aktif bila total 24 jam ≥ 50 mm (ambang hujan lebat BMKG).

**Panel "Kenapa skor ini?"** di dasbor: tampilkan tiga komponen (H, S, K) beserta bobotnya, supaya rekomendasi bisa dipercaya (3.3 menekankan transparansi model).

**Batas klaim (3.3):** skor ditampilkan per RW, bukan per ruas jalan. Jangan klaim prediksi hitungan menit di tingkat jalan.

---

## 5. Kontrak keluaran AI (Lampiran C)

### Analisis laporan

```json
{
  "jenis_saluran": "terbuka",
  "saluran_terlihat": true,
  "kelas_sumbatan": "berat",
  "skor_sumbatan": 0.85,
  "penyebab": ["plastik", "sedimen"],
  "keyakinan": "tinggi",
  "catatan": "Sampah plastik menutupi sebagian besar lebar saluran"
}
```

- `jenis_saluran`: `terbuka` | `gorong_gorong` | `inlet_jalan`
- `kelas_sumbatan`: `bersih` | `ringan` | `sedang` | `berat` | `tidak_terlihat`
- `penyebab`: subset dari `plastik`, `sedimen`, `daun_ranting`, `puing`
- `keyakinan`: `rendah` | `sedang` | `tinggi`

**Validasi keluaran** (tugas peran AI, Tabel 13) **[ASUMSI rentang]**: `skor_sumbatan` harus cocok dengan kelasnya (bersih 0–0,15 · ringan 0,15–0,40 · sedang 0,40–0,70 · berat 0,70–1). Kalau JSON rusak atau tidak cocok: ulangi sekali, lalu tandai laporan "perlu cek manual".

### Verifikasi sebelum–sesudah **[ASUMSI, turunan Lampiran C]**

```json
{
  "sudah_bersih": true,
  "kelas_sesudah": "bersih",
  "skor_sumbatan_sesudah": 0.08,
  "keyakinan": "tinggi",
  "catatan": "Sampah plastik sudah terangkat, aliran terlihat lancar"
}
```

---

## 6. Draft kontrak API & skema DB (dikunci di jam 0–1)

### Endpoint

| Method | Path | Fungsi |
|---|---|---|
| POST | `/auth/login` | Akun siap pakai: lurah, petugas, warga |
| POST | `/reports` | multipart: foto, lat, lng, captured_at, jenis_saluran → panggil AI → simpan → hitung ulang skor RW. Laporan dalam radius 15 m **[ASUMSI]** dari saluran yang sudah ada digabung ke saluran itu (Tabel 8) |
| GET | `/reports/:id` | Status laporan untuk pelapor + foto bukti bila sudah ditangani |
| GET | `/rw/risk?kelurahan_id=` | GeoJSON poligon RW + skor, level, rincian H/S/K |
| GET | `/priorities?kelurahan_id=` | Daftar saluran urut skor + flag "hujan lebat diprediksi" |
| POST | `/tasks` | `{saluran_id, petugas_id}` → kirim FCM ke petugas |
| GET | `/tasks?mine=1` | Tugas milik petugas yang login |
| POST | `/tasks/:id/verify` | multipart foto sesudah → AI bandingkan → update skor + status laporan |
| POST | `/devices` | Simpan FCM token |

### Tabel

```
pengguna(id, nama, role[lurah|petugas|warga], fcm_token)
kelurahan(id, nama, centroid geography(Point))
rw(id, kelurahan_id, nama, geom geography(Polygon), elevasi_relatif, jarak_genangan_m, kerentanan)
titik_genangan(id, nama, geom geography(Point), sumber)
saluran(id, rw_id, jenis, geom geography(Point))
laporan(id, saluran_id, pelapor_id, foto_url, geom, captured_at,
        ai_json, kelas, skor_sumbatan, keyakinan,
        status[dikirim|ditugaskan|ditangani|cek_manual], created_at)
tugas(id, saluran_id, laporan_id, petugas_id, status[baru|dikerjakan|selesai],
      foto_sesudah_url, ai_verifikasi_json, selesai_at)
prakiraan_hujan(kelurahan_id, fetched_at, total_24j_mm, hourly_json)
```

---

## 7. Pembagian peran (Tabel 13)

Isi nama sesuai kesepakatan tim: I Gede Ananda Bela Persada · Fatih Akram Wicaksono · Wildan Panji Maulana.

| Peran | Nama | Tanggung jawab (Tabel 13) |
|---|---|---|
| **A · Mobile developer** | … | Aplikasi pelapor Flutter: alur foto dan GPS, tampilan hasil analisis, notifikasi tugas |
| **B · Backend developer** | … | REST API, basis data spasial, mesin skor risiko, integrasi data cuaca dan notifikasi |
| **C · AI dan dasbor** | … | Integrasi AI vision dan validasi keluarannya, peta risiko, dasbor kelurahan |

Tentukan juga satu orang yang presentasi.

---

## 8. Timeline 12 jam (Tabel 14)

| Jam | Kegiatan (Tabel 14) | A · Mobile | B · Backend | C · AI + Dasbor |
|---|---|---|---|---|
| **0–1** | Repositori, skema DB, kontrak API, data contoh | Setup Flutter + HP Android, `google-services.json` | Repo, skema PostGIS, isi data contoh | Kunci format JSON AI, kumpulkan 10–15 foto uji |
| **1–5** | Fitur inti paralel: app lapor, endpoint laporan & skor risiko, integrasi AI vision | Kamera in-app, GPS, pilih jenis saluran, unggah, tampil hasil AI | `POST /reports`, `GET /rw/risk`, mesin skor (hujan masih dummy) | Prompt + validasi JSON, uji ke semua foto, sambungkan ke `POST /reports` |
| **5–8** | Prakiraan hujan, peta risiko, daftar prioritas | Layar status laporan, kerangka tab Tugas | Open-Meteo + cache, `GET /priorities` | Peta Leaflet (poligon RW berwarna, pin saluran), panel "Kenapa skor ini?", daftar prioritas |
| **8–10** | Penugasan, verifikasi sebelum–sesudah, notifikasi | Terima FCM, foto sesudah | `POST /tasks` + kirim FCM, `POST /tasks/:id/verify` | Tombol Tugaskan, prompt verifikasi, tampilan foto sebelum–sesudah |
| **10–11** | Deploy, uji ujung ke ujung, perbaikan bug | Build APK, tes di HP asli | Deploy API + DB | Deploy dasbor |
| **11–12** | Video demo + berkas pengumpulan | Rekam video demo (wajib) | Rapikan README + laporan pengembangan | Jalankan alur di dasbor untuk video, siapkan screenshot untuk PPT |
| **H+1** | Final Presentation (9 Nov) | Latihan pitching 2–3× pakai timer sebelum sesi | | |

- **PPT:** dikerjakan presenter (siapa pun yang ditunjuk), mulai jam 10–11 begitu bagiannya sudah ter-deploy.
- **Formulir pengumpulan + commit terakhir:** ketua tim, sebelum deadline.

Tabel 14 menaruh "latihan demo & pitching" di jam 11–12. Karena pitching baru H+1 dan berkas wajib dikumpulkan di akhir 12 jam, jam 11–12 dipakai untuk video + berkas, latihan pindah ke besok.

**Checkpoint:**

- **Jam 0–1:** repo GitHub dibuat, README kerangka, `docs/LAPORAN_PENGEMBANGAN.md` kosong, `.env.example`. Ketua siapkan lembar orisinalitas.
- **Jam 5:** foto dari HP → AI → tersimpan → skor RW berubah (dicek lewat API).
- **Jam 8:** dasbor menampilkan peta risiko dan daftar prioritas dari data asli + prakiraan Open-Meteo.
- **Jam 10:** siklus lapor → prediksi → bertindak → verifikasi jalan penuh. **Setelah ini tidak ada fitur baru.**
- **Setiap checkpoint:** tiap orang tulis 3–5 poin di laporan pengembangan (apa yang jadi, kendala, keputusan, asumsi) + 1 screenshot. Laporan di jam 11–12 tinggal dirapikan.

---

## 9. Data contoh (jam 0–1)

- **Lokasi:** 1 kelurahan rawan genangan di daerah Gedebage atau Kopo (2.1). Gedebage itu kecamatan, jadi pilih salah satu kelurahannya.
- **Poligon RW:** 10–15 poligon digambar di geojson.io di atas peta OSM. Sebut sebagai ilustrasi, bukan batas resmi.
- **Titik genangan langganan:** dari sumber [3]: Pasar Induk Gedebage, Jl. Soekarno-Hatta, Kopo, Cibaduyut, Citarip, Pasir Koja, Leuwipanjang.
- **Elevasi (DEMNAS):** unduh tile area kelurahan dari tanahair.indonesia.go.id (perlu akun), ambil elevasi di centroid tiap RW, normalisasi relatif dalam kelurahan. Kalau unduhan gagal di jam 0–1, pakai sementara Open-Meteo Elevation API dan sebut terus terang di pitch bahwa DEMNAS menyusul.
- **Foto saluran:** 10–15 foto, mencakup semua kelas (termasuk "tidak terlihat") dan ketiga jenis saluran.
- **Laporan dummy:** sekitar 30, tersebar di RW supaya peta punya warna campuran.

---

## 10. Uji kasus ujung (dasar: Tabel 8, dites di jam 10–11)

| Kasus | Perilaku yang diharapkan |
|---|---|
| Saluran tertutup beton/bangunan | Kelas "tidak terlihat" → status `cek_manual`, tidak masuk skor |
| Keyakinan AI rendah | Tetap tampil dengan label keyakinan, bobot kecil di skor |
| Dua laporan berdekatan | Digabung ke saluran yang sama |
| Coba unggah dari galeri | Tidak ada opsi galeri. GPS + waktu otomatis |
| Laporan selesai ditangani | Pelapor lihat status "sudah ditangani" + foto bukti |
| AI lambat/gagal | Mode demo memakai hasil tersimpan (bagian 12) |

---

## 11. Skrip demo & pitch

1. **Masalah:** 68 titik genangan di Kota Bandung (data 2023) [4]; saluran tersumbat sampah [3]; ±200 ton sampah/hari belum terolah [7]; di Bandung Raya, banjir Dayeuhkolot–Baleendah–Bojongsoang April 2026 berdampak 34.497 warga [1], dekat kampus kami.
2. **Lapor:** foto saluran langsung dari HP → AI: "berat · plastik + sedimen · keyakinan tinggi".
3. **Prediksi:** RW itu berubah warna di dasbor. Klik "Kenapa skor ini?" → rincian hujan, sumbatan, kerentanan.
4. **Bertindak:** daftar prioritas → Tugaskan → notifikasi masuk di HP petugas.
5. **Verifikasi:** foto sesudah → AI: "sudah bersih" → skor RW turun, peta jadi lebih hijau.
6. **Bisnis (3.6, Tabel 5–6):** app pelapor gratis; paket Kelurahan Rp750.000/bulan, Kawasan Rp500.000/bulan, Kota mulai Rp60 juta/tahun; pilot didanai CSR "Adopsi Saluran". Proyeksi pendapatan Rp780 juta di tahun ke-3 dan titik impas di tahun ke-3 (asumsi, diuji saat pilot). Pilot 6 bulan di 2 kelurahan: Rp35 juta.
7. **Beda dengan yang ada (Bab 5):** Noah AI, Google Flood Hub, dan PetaBencana.id tidak memakai data kondisi saluran dan bekerja saat banjir sudah/akan terjadi. RIVORA memberi tindakan sebelum hujan, tanpa sensor, dan **melengkapi** LAPOR!, bukan menggantikan.
8. **Dampak (3.7):** SDG 6, 11, 13. Target pilot: 1.000 laporan terverifikasi; tahun ke-3: 60 kelurahan.
9. **Jujur soal batas (3.3):** bobot skor masih asumsi dan akan dikalibrasi saat pilot; skor per RW, bukan per jalan.

---

## 12. Pengaman demo

- **`DEMO_MODE=1`** **[DEMO]**: kalau API AI lambat/gagal, backend memakai hasil tersimpan untuk foto demo.
- **Override hujan** **[DEMO]**: cuaca hari-H belum tentu hujan. Dasbor punya slider untuk mengganti nilai hujan 24 jam. Sebut di depan juri bahwa ini simulasi; nilai aslinya dari Open-Meteo.
- Lomba daring: pastikan koneksi stabil, siapkan hotspot HP sebagai cadangan.
- Video demo wajib dikumpulkan, sekaligus jadi cadangan kalau live demo gagal saat final.
- **Jangan commit API key.** Repo akan dilihat panitia dan juri. Simpan di `.env`, sertakan `.env.example`.

---

## 13. Checklist pengumpulan (sebelum code freeze)

- [ ] Tautan repo GitHub (bisa diakses panitia), README: deskripsi, tech stack, cara run, status fitur
- [ ] Video demonstrasi produk: siklus lapor → prediksi → bertindak → verifikasi
- [ ] Laporan pengembangan: fitur jadi vs Tabel 3, keputusan teknis, semua **[ASUMSI]**, kendala, rencana lanjut (2.2)
- [ ] PPT pitching: alur bagian 11
- [ ] Lembar pernyataan orisinalitas karya (format Guidebook)
- [ ] Commit terakhir sudah di-push sebelum deadline
