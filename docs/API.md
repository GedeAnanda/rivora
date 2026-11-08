# Kontrak API RIVORA

**Pemilik:** B (backend). Setiap perubahan diumumkan di Discord.
**Status:** DRAFT. Dikunci di jam 0–1 (Tabel 14 proposal). Setelah dikunci, file ini yang berlaku; `RENCANA_FINAL.md` bagian 5–6 hanya draft awal.

Base URL lokal: `http://localhost:3000`

## Endpoint

| Method | Path | Request | Response / efek |
|---|---|---|---|
| POST | `/auth/login` | `{username, password}` | `{token, role}`. Akun siap pakai: lurah, petugas, warga |
| POST | `/reports` | multipart: `foto`, `lat`, `lng`, `captured_at`, `jenis_saluran` | Laporan + hasil AI. Skor RW dihitung ulang. Laporan dalam radius 15 m dari saluran yang sudah ada digabung ke saluran itu **[ASUMSI]** |
| GET | `/reports/:id` | – | Status laporan + foto bukti bila sudah ditangani |
| GET | `/rw/risk?kelurahan_id=` | – | GeoJSON poligon RW + `skor`, `level`, rincian `hujan`/`sumbatan`/`kerentanan` |
| GET | `/priorities?kelurahan_id=` | – | Daftar saluran urut skor + flag `hujan_lebat_diprediksi` |
| POST | `/tasks` | `{saluran_id, petugas_id}` | Tugas dibuat, FCM dikirim ke petugas |
| GET | `/tasks?mine=1` | – | Tugas milik petugas yang login |
| POST | `/tasks/:id/verify` | multipart: `foto` (sesudah) | Hasil verifikasi AI, skor + status laporan diperbarui |
| POST | `/devices` | `{fcm_token}` | Token FCM disimpan |

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

## Keluaran AI: analisis laporan (Lampiran C proposal)

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

## Keluaran AI: verifikasi sebelum–sesudah [ASUMSI]

```json
{
  "sudah_bersih": true,
  "kelas_sesudah": "bersih",
  "skor_sumbatan_sesudah": 0.08,
  "keyakinan": "tinggi",
  "catatan": "Sampah plastik sudah terangkat, aliran terlihat lancar"
}
```

## Format error

```json
{ "error": "pesan singkat" }
```
