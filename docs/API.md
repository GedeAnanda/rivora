# Kontrak API RIVORA

**Pemilik:** B (backend). Setiap perubahan diumumkan di Discord.
**Status:** DIKUNCI (8 Nov 2026). Sumber: SRS v1.0 bagian 7. File ini yang berlaku; `RENCANA_FINAL.md` bagian 5–6 hanya draft awal.

Base URL lokal: `http://localhost:3000`

## Aturan umum

- JSON memakai `snake_case`. Waktu ISO 8601 UTC (`2026-11-08T02:30:00.000Z`). Id berupa angka.
- Koordinat di body JSON memakai `lat` dan `lng` terpisah. Di GeoJSON, urutannya `[lng, lat]` sesuai standar.
- Semua error: `{ "error": "pesan singkat Bahasa Indonesia" }` dengan status 400/401/403/404/409/500. Tanpa stack trace.
- `foto_url` selalu URL absolut (`https://<host>/uploads/...`).

## Daftar endpoint

| Method | Path | Bagian |
|---|---|---|
| POST | `/auth/login` | 7.1 |
| POST | `/reports` | 7.2 |
| GET | `/reports/:id` | 7.3 |
| GET | `/rw/risk?kelurahan_id=` | 7.4 |
| GET | `/saluran?kelurahan_id=` | 7.5 |
| GET | `/saluran/:id` | 7.6 |
| GET | `/priorities?kelurahan_id=` | 7.7 |
| GET | `/petugas` | 7.8 |
| POST · GET | `/tasks` | 7.9 |
| POST | `/tasks/:id/verify` | 7.10 |
| POST · PATCH · PUT · GET | `/devices` · `/tasks/:id` · `/demo/hujan` · `/health` | 7.11 |

---

### 7.1 `POST /auth/login`

```jsonc
// request
{ "username": "lurah", "password": "••••" }
// 200
{ "token": "eyJ...", "role": "lurah", "pengguna": { "id": 1, "nama": "Lurah Contoh", "kelurahan_id": 1 } }
```

### 7.2 `POST /reports` → 201

Request: multipart `foto`, `lat`, `lng`, `captured_at`, `jenis_saluran` (token opsional). Laporan dalam radius 15 m dari saluran yang sudah ada digabung ke saluran itu **[ASUMSI]**.

Field yang sudah dibaca mobile ditulis lebih dulu. Field sesudah `ai` adalah tambahan; mobile mengabaikannya tanpa error.

```json
{
  "id": 42,
  "status": "dikirim",
  "jenis_saluran": "terbuka",
  "lat": -6.940123,
  "lng": 107.690456,
  "captured_at": "2026-11-08T02:30:00.000Z",
  "foto_url": "https://api.contoh/uploads/laporan/7f3c.jpg",
  "ai": {
    "jenis_saluran": "terbuka",
    "saluran_terlihat": true,
    "kelas_sumbatan": "berat",
    "skor_sumbatan": 0.85,
    "penyebab": ["plastik", "sedimen"],
    "keyakinan": "tinggi",
    "catatan": "Sampah plastik menutupi sebagian besar lebar saluran"
  },
  "ai_sumber": "model",
  "saluran_id": 7,
  "digabung": false,
  "rw_id": 5,
  "rw_nama": "RW 05",
  "lokasi_demo": false
}
```

### 7.3 `GET /reports/:id` → 200

Sama dengan 7.2, ditambah:

```json
{
  "tugas": { "id": 12, "status": "selesai", "petugas_nama": "Petugas 1" },
  "bukti": {
    "foto_sesudah_url": "https://api.contoh/uploads/verifikasi/91aa.jpg",
    "kelas_sesudah": "bersih",
    "selesai_at": "2026-11-08T05:10:00.000Z"
  }
}
```

`tugas` dan `bukti` bernilai `null` bila belum ada.

### 7.4 `GET /rw/risk?kelurahan_id=1` → 200

```json
{
  "type": "FeatureCollection",
  "meta": {
    "kelurahan": { "id": 1, "nama": "Kelurahan Contoh" },
    "hujan_24j_mm": 80,
    "hujan_sumber": "open_meteo",
    "hujan_diambil_at": "2026-11-08T03:00:00.000Z",
    "hujan_lebat_diprediksi": true,
    "bobot": { "hujan": 0.4, "sumbatan": 0.4, "kerentanan": 0.2 },
    "dihitung_at": "2026-11-08T03:05:12.000Z"
  },
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Polygon", "coordinates": [[[107.69, -6.94], [107.692, -6.94], [107.692, -6.942], [107.69, -6.942], [107.69, -6.94]]] },
      "properties": {
        "rw_id": 5,
        "nama": "RW 05",
        "skor": 0.80,
        "level": "risiko_tinggi",
        "komponen": {
          "hujan":      { "nilai": 0.80, "bobot": 0.4, "kontribusi": 0.32, "mm": 80 },
          "sumbatan":   { "nilai": 0.85, "bobot": 0.4, "kontribusi": 0.34, "jumlah_saluran": 1, "jumlah_cek_manual": 0, "data_cukup": true },
          "kerentanan": { "nilai": 0.70, "bobot": 0.2, "kontribusi": 0.14, "elevasi_relatif": 0.9, "jarak_genangan_m": 500, "genangan_terdekat": "Pasar Induk Gedebage" }
        },
        "alasan": "Risiko tinggi: prakiraan hujan 80 mm dalam 24 jam, 1 dari 1 saluran tersumbat sedang–berat, lokasi rendah dan 500 m dari titik genangan Pasar Induk Gedebage."
      }
    }
  ]
}
```

`hujan_sumber`: `open_meteo` · `cache` · `tidak_tersedia` · `simulasi_demo`.

### 7.5 `GET /saluran?kelurahan_id=1` → 200

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [107.690456, -6.940123] },
      "properties": {
        "saluran_id": 7,
        "jenis": "terbuka",
        "rw_id": 5,
        "rw_nama": "RW 05",
        "kondisi": {
          "laporan_id": 42,
          "kelas": "berat",
          "skor_sumbatan": 0.85,
          "keyakinan": "tinggi",
          "foto_url": "https://api.contoh/uploads/laporan/7f3c.jpg",
          "captured_at": "2026-11-08T02:30:00.000Z"
        },
        "perlu_cek_manual": false,
        "tugas_aktif": { "id": 12, "status": "baru", "petugas_nama": "Petugas 1" }
      }
    }
  ]
}
```

`kondisi` = laporan terbaru yang terlihat (bagian 9.1), `null` bila belum ada. `tugas_aktif` bernilai `null` bila tidak ada tugas yang belum selesai.

### 7.6 `GET /saluran/:id` → 200

```json
{
  "saluran_id": 7, "jenis": "terbuka", "rw_id": 5, "rw_nama": "RW 05", "lat": -6.940123, "lng": 107.690456,
  "riwayat": [
    { "laporan_id": 50, "sumber": "verifikasi", "kelas": "bersih", "skor_sumbatan": 0.08, "keyakinan": "tinggi",
      "foto_url": "…", "captured_at": "…", "status": "ditangani", "ai_sumber": "model", "lokasi_demo": false, "catatan": "…" },
    { "laporan_id": 42, "sumber": "laporan", "kelas": "berat", "skor_sumbatan": 0.85, "keyakinan": "tinggi",
      "foto_url": "…", "captured_at": "…", "status": "ditangani", "ai_sumber": "model", "lokasi_demo": false, "catatan": "…" }
  ],
  "tugas": [ { "…": "bentuk sama dengan 7.9" } ]
}
```

### 7.7 `GET /priorities?kelurahan_id=1` → 200

```json
{
  "meta": { "hujan_24j_mm": 80, "hujan_sumber": "open_meteo", "hujan_lebat_diprediksi": true, "dihitung_at": "…" },
  "prioritas": [
    {
      "peringkat": 1,
      "saluran_id": 7, "jenis": "terbuka", "rw_id": 5, "rw_nama": "RW 05",
      "lat": -6.940123, "lng": 107.690456,
      "kelas": "berat", "skor_sumbatan": 0.85, "keyakinan": "tinggi",
      "foto_url": "…", "captured_at": "…",
      "skor_prioritas": 0.80,
      "komponen": { "hujan": 0.80, "sumbatan": 0.85, "kerentanan": 0.70 },
      "tugas_aktif": null
    }
  ],
  "cek_manual": [
    { "saluran_id": 9, "jenis": "gorong_gorong", "rw_nama": "RW 02", "foto_url": "…", "captured_at": "…",
      "catatan": "Saluran tertutup beton, kondisi di dalam tidak terlihat" }
  ]
}
```

### 7.8 `GET /petugas` → 200

```json
[ { "id": 2, "nama": "Petugas 1", "tugas_aktif": 1 }, { "id": 3, "nama": "Petugas 2", "tugas_aktif": 0 } ]
```

### 7.9 `POST /tasks` → 201 · `GET /tasks` → 200 (array)

```jsonc
// request POST
{ "saluran_id": 7, "petugas_id": 2, "catatan": "Prioritas sebelum hujan sore" }
// objek tugas
{
  "id": 12,
  "status": "baru",
  "saluran": { "id": 7, "jenis": "terbuka", "rw_nama": "RW 05", "lat": -6.940123, "lng": 107.690456 },
  "petugas": { "id": 2, "nama": "Petugas 1" },
  "laporan_id": 42,
  "foto_sebelum_url": "…", "kelas_sebelum": "berat", "skor_sebelum": 0.85,
  "foto_sesudah_url": null,
  "verifikasi": null,
  "catatan": "Prioritas sebelum hujan sore",
  "dibuat_at": "…", "selesai_at": null
}
// respons POST membungkus objek di atas:
{ "tugas": { "…": "…" }, "notifikasi": "terkirim" }
```

`notifikasi`: `terkirim` · `gagal` · `tanpa_token` (petugas belum `POST /devices`) · `nonaktif` (Firebase belum disetel) **[ASUMSI]**. Data FCM (semua string): `type: "tugas_baru"` (SRS bag. 11), `tugas_id`, `saluran_id`, `lat`, `lng`. 409 bila saluran sudah punya tugas belum selesai. `GET /tasks`: petugas = tugas miliknya, lurah = semua; filter opsional `?status=`.

### 7.10 `POST /tasks/:id/verify` → 200

Request: multipart `foto` (sesudah), `lat`, `lng`, `captured_at` (wajib, aturan sama dengan 7.2; posisi maks 30 m dari saluran). Token petugas pemilik tugas. Opsional `lokasi_demo=true` [DEMO] → radius dilewati bila `DEMO_MODE=1`. `sudah_bersih: false` atau AI gagal → tugas tetap `dikerjakan`, boleh verifikasi ulang **[ASUMSI]**.

```json
{
  "tugas": { "…": "objek tugas 7.9, status sudah diperbarui" },
  "verifikasi": {
    "sudah_bersih": true,
    "kelas_sesudah": "bersih",
    "skor_sumbatan_sesudah": 0.08,
    "keyakinan": "tinggi",
    "catatan": "Sampah plastik sudah terangkat, aliran terlihat lancar"
  },
  "ai_sumber": "model"
}
```

### 7.11 Lainnya

| Endpoint | Request | Respons |
|---|---|---|
| `POST /devices` | `{ "fcm_token": "…" }` | 204 |
| `PATCH /tasks/:id` (P2) | `{ "status": "dikerjakan" }` | 200 objek tugas |
| `PUT /demo/hujan` [DEMO] | `{ "mm": 80 }` / `{ "mm": null }` | 200 `{ "mm": 80 }`. 404 bila `DEMO_MODE` mati |
| `GET /health` (P1) | – | `{ "ok": true, "demo_mode": true, "ai_siap": true, "db": "ok" }` |

---

## Nilai enum

| Field | Nilai |
|---|---|
| `jenis_saluran` | `terbuka` · `gorong_gorong` · `inlet_jalan` |
| `kelas_sumbatan` | `bersih` · `ringan` · `sedang` · `berat` · `tidak_terlihat` |
| `penyebab` | `plastik` · `sedimen` · `daun_ranting` · `puing` |
| `keyakinan` | `rendah` · `sedang` · `tinggi` |
| `level` (RW) | `aman` · `waspada` · `risiko_tinggi` |
| `laporan.status` | `dikirim` · `ditugaskan` · `ditangani` · `cek_manual` |
| `tugas.status` | `baru` · `dikerjakan` · `selesai` |
| `ai_sumber` | `model` · `demo` · `gagal` |
| `hujan_sumber` | `open_meteo` · `cache` · `tidak_tersedia` · `simulasi_demo` |
