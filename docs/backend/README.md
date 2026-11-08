# Backend RIVORA — cara menjalankan

REST API Node.js + Express. Database PostgreSQL + PostGIS di **Supabase** (tanpa Docker), foto di **Supabase Storage**, notifikasi lewat **Firebase Cloud Messaging**, HTTPS publik lewat **Cloudflare Quick Tunnel**.

Kontrak API: [`docs/API.md`](../API.md). Skema: [`db/schema.sql`](../../db/schema.sql).

## Prasyarat

- Node.js ≥ 18
- Akun Supabase (gratis)
- Proyek Firebase (untuk FCM). Opsional: tanpa service account, API tetap jalan dan `notifikasi` bernilai `nonaktif`.
- `cloudflared` (hanya kalau API perlu diakses dari HP/dasbor lewat HTTPS)

## 1. Database Supabase (PostGIS + skema)

1. Buat proyek baru di <https://supabase.com/dashboard>. Catat password database. Gunakan **huruf dan angka saja**; karakter spesial membuat `DATABASE_URL` gagal diparse ("Invalid URL").
2. **Database → Extensions** → aktifkan `postgis`.
3. **SQL Editor** → tempel seluruh isi `db/schema.sql` → **Run**. Skrip ini diawali `DROP`, jadi aman dijalankan ulang (tapi menghapus data).
4. **Connect** (tombol di atas) → pilih **Session pooler** (IPv4, port 5432) → salin URI-nya untuk `DATABASE_URL`.

## 2. Storage: bucket `foto`

1. **Storage → New bucket** → nama `foto`, centang **Public bucket**.
2. Unggah `backend/assets/contoh.jpg` ke bucket `foto` (nama file tetap `contoh.jpg`). Foto ini dipakai laporan hasil seed.
3. **Project Settings → API Keys** → salin **service_role** key untuk `SUPABASE_SERVICE_KEY`. Key ini rahasia; hanya untuk `.env` backend.

Kalau `SUPABASE_URL` dikosongkan, foto disimpan ke disk lokal `backend/uploads/` dan dilayani di `/uploads/...`.

## 3. Firebase service account (FCM)

1. Firebase Console → proyek tim → ⚙ **Project settings → Service accounts** → **Generate new private key**.
2. Simpan file sebagai `backend/firebase-service-account.json`. File ini **tidak boleh di-commit** (sudah di `.gitignore`).
3. Alternatif tanpa file: isi `FIREBASE_SERVICE_ACCOUNT_BASE64` dengan isi JSON yang di-base64.

## 4. Instal dan isi `.env`

```powershell
# PowerShell, dari folder repo
cd backend
npm i
copy ..\.env.example .env
```

Buka `backend/.env`, hapus bagian dashboard/mobile, lalu isi:

| Variabel | Isi |
|---|---|
| `PORT` | `3000` |
| `DATABASE_URL` | URI Session pooler dari langkah 1 |
| `DB_SSL` | `1` (wajib untuk Supabase) |
| `JWT_SECRET` | string acak panjang |
| `SEED_PASSWORD` | password untuk 4 akun demo (dibagikan lewat Discord, tidak ditulis di repo) |
| `AI_API_KEY`, `AI_MODEL` | key Anthropic + nama model (dipakai modul `src/ai/`) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `./firebase-service-account.json` |
| `SUPABASE_URL` | `https://<ref>.supabase.co` |
| `SUPABASE_SERVICE_KEY` | service_role key dari langkah 2 |
| `SUPABASE_BUCKET` | `foto` |
| `DEMO_MODE` | `1` untuk demo (aktifkan fitur [DEMO]), `0` untuk normal |
| `DEMO_SALURAN_ID` | id saluran tujuan `lokasi_demo=true` (data seed: `9`, RW 05) |
| `PUBLIC_URL` | kosongkan bila pakai Supabase Storage |

## 5. Seed dan jalankan

```powershell
# PowerShell, di folder backend
npm run seed     # isi data contoh: 4 akun, 6 RW, 12 saluran, 9 laporan
npm start        # atau: npm run dev (auto-restart)
npm test         # unit test rumus skor (risk/score.test.js)
```

Cek: buka <http://localhost:3000/health>, harus ada `"db": "ok"`.

Akun demo: `lurah`, `petugas1`, `petugas2`, `warga`, semuanya dengan password `SEED_PASSWORD`.

> **Penting:** seed menghapus semua data, termasuk token FCM HP. Urutan saat demo: `npm run seed` → petugas login ulang di aplikasi → demo. Jangan seed lagi setelah HP login.

## 6. HTTPS publik (Cloudflare Quick Tunnel)

Biarkan `npm start` tetap jalan, lalu buka terminal kedua:

```powershell
# PowerShell, terminal kedua
cloudflared tunnel --url http://localhost:3000
```

Salin URL `https://<acak>.trycloudflare.com` yang muncul, lalu bagikan ke Mobile (`--dart-define=API_URL=...`) dan Dasbor (`VITE_API_URL`). Tidak perlu akun atau kartu. **URL berubah setiap kali tunnel di-restart**, jadi jangan tutup terminal ini selama demo. Laptop harus tetap menyala dan tidak sleep.

Instal `cloudflared` (sekali): `winget install --id Cloudflare.cloudflared`.

## Struktur `backend/src`

| File | Isi |
|---|---|
| `index.js` | server Express, `/health`, mount route |
| `db.js` | pool PostgreSQL (SSL via `DB_SSL`) |
| `auth.js` | `POST /auth/login`, JWT, `wajibLogin(...roles)` |
| `routes/` | reports, rw, saluran, priorities, tasks, lainnya (`/petugas`, `/devices`, `/demo/hujan`) |
| `risk/score.js` | rumus skor (fungsi murni) + test |
| `risk/data.js` | hitung risiko RW & prioritas dari DB |
| `weather/openMeteo.js` | Open-Meteo + cache 30 menit + hujan demo |
| `notify/fcm.js` | kirim notifikasi tugas |
| `storage.js` | unggah foto ke Supabase Storage |
| `saluran.js`, `tugas.js`, `demo.js`, `errors.js` | gabung saluran 15 m, bentuk tugas, fitur [DEMO], error JSON |
| `seed.js` | data contoh Cisaranten Kidul (Gedebage) |
| `ai/` | modul AI (milik anggota C) |

## Asumsi yang dipakai ([ASUMSI])

Hal yang tidak diatur tegas di SRS, diputuskan saat implementasi:

**Skor & data**
1. Bobot skor (0,4 / 0,4 / 0,2) dan ambang level adalah asumsi awal, belum dikalibrasi. Skor per RW, bukan per ruas jalan.
2. Data seed (6 RW berbentuk grid, 12 saluran, nilai K tiap RW, 9 laporan) adalah data contoh, bukan data lapangan.
3. Daftar prioritas berisi semua saluran yang sudah punya kondisi (pernah dilaporkan).
4. Laporan baru digabung ke saluran yang ada bila jaraknya ≤ 15 m **dan jenis salurannya sama**.

**Cuaca**
5. `hujan_sumber = open_meteo` berarti data berumur ≤ 30 menit; `cache` berarti Open-Meteo gagal sehingga dipakai data lama; `simulasi_demo` berarti nilai dari `PUT /demo/hujan`.

**Laporan & validasi**
6. Flag lokasi palsu dibaca dari field `lokasi_palsu` atau `is_mocked`.
7. `captured_at` wajib diisi (maks 60 menit lalu / 5 menit ke depan).
8. Token rusak di `POST /reports` diabaikan (laporan tetap diterima, `pelapor` null).
9. Bila unggah ke Supabase Storage gagal, foto disimpan di disk lokal.

**Akses**
10. `GET /rw/risk`, `/saluran`, `/priorities`, `/reports/:id` publik (tanpa token).
11. `PUT /demo/hujan` wajib token `lurah` dan `DEMO_MODE=1`.

**Tugas & verifikasi**
12. `POST /tasks` memakai laporan (sumber = laporan) terbaru di saluran itu.
13. Verifikasi wajib `lat`, `lng`, `captured_at`.
14. Bila hasil verifikasi belum bersih atau AI gagal, tugas kembali ke `dikerjakan` dan petugas bisa mengulang.
