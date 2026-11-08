# Modul AI memanggil Claude asli

**Waktu:** 2026-11-08 13:45

**Apa yang diubah**
`analyzeReport` dan `verifyCleaning` di `backend/src/ai/index.js` tidak lagi stub. Keduanya sekarang memanggil Claude lewat `@anthropic-ai/sdk` (sudah ada di `backend/package.json` milik Jajang, versi ^1.6.0), dengan keluaran JSON terstruktur, lalu divalidasi. Antarmuka tetap sama dengan SRS backend bagian 10, jadi `backend/src/routes/reports.js` tidak perlu diubah.

**File**
| File | Isi |
|---|---|
| `backend/src/ai/index.js` | Klien Anthropic (`AI_API_KEY`, `AI_MODEL`), skema JSON keluaran, prompt bahasa Indonesia, batas 20 detik per panggilan, ulang 1 kali, cadangan `DEMO_MODE`, log per panggilan |
| `backend/src/ai/ai.test.js` | 6 tes `node:test` dengan klien tiruan (tidak memanggil API asli) |
| `backend/src/ai/validasi.js`, `contoh.js` | Tidak berubah (dari entri 07) |

**Alur satu panggilan**
1. Foto dikirim sebagai gambar base64. Untuk verifikasi, dua gambar berurutan: SEBELUM lalu SESUDAH.
2. Permintaan memakai `output_config.format` bertipe `json_schema`, jadi keluaran model selalu berbentuk JSON sesuai skema Lampiran C (atau format verifikasi di `docs/API.md`).
3. Hasil dicek `validasi.js`: enum, penyebab, kecocokan skor dengan kelas, aturan `tidak_terlihat`.
4. Gagal (timeout 20 detik, galat API, model menolak, JSON atau validasi gagal) -> diulang sekali. Paling lama sekitar 40 detik, masih di bawah timeout mobile 60 detik.
5. Gagal dua kali: `DEMO_MODE=1` -> hasil contoh bergiliran dengan `sumber: 'demo'`; selain itu `{ ok: false, alasan }`, dan backend menyimpan laporan sebagai `cek_manual` (FR-BE-06).

**Keputusan dan asumsi**
- Model bawaan `claude-opus-5-5` bila `AI_MODEL` kosong. Model lain boleh lewat `AI_MODEL`, asal mendukung keluaran terstruktur dan `effort` (keluarga Claude 5; bukan Sonnet 4.5 atau Haiku 4.5).
- `effort: 'low'`: tugasnya klasifikasi satu foto, dan harus selesai di bawah 20 detik.
- Kunci API dibaca dari `AI_API_KEY` (nama di `.env.example`), bukan `ANTHROPIC_API_KEY`. Kunci tidak pernah ditulis ke log.
- SDK dibuat dengan `maxRetries: 0`; pengulangan diatur modul ini supaya total waktu tetap sekitar 40 detik.
- Penolakan model (`stop_reason: refusal`) dianggap gagal biasa, lalu diulang atau jatuh ke cek manual. Fallback model sisi server tidak dipasang, karena modelnya bisa diganti lewat `AI_MODEL` dan fitur itu tidak didukung semua model.
- [ASUMSI] Verifikasi dianggap bersih hanya bila `kelas_sesudah` bersih atau ringan (sama dengan entri 07). Bila dua foto jelas bukan saluran yang sama, model diminta mengisi `sudah_bersih: false`.

**Cara cek**
```bash
cd backend
npm install
node --test src/ai            # 6 tes, tanpa API asli
```
Uji dengan API asli (butuh `AI_API_KEY` di `backend/.env`): jalankan backend, lalu kirim satu foto ke `POST /reports`. Respons harus berisi `"ai_sumber": "model"` dan log server menampilkan `[ai] analyzeReport sumber=model`.

Sudah dicek: 6 tes lulus (hasil valid, JSON rusak lalu berhasil di ulangan, skor tidak cocok dua kali -> gagal, gagal + DEMO_MODE -> demo, verifikasi valid, tanpa kunci -> gagal).

**Belum dikerjakan**
- Belum diuji dengan API asli: laptop Wildan tidak punya `AI_API_KEY`. Kualitas penilaian foto sungguhan belum diukur.
- Belum diuji ke 10 sampai 15 foto uji (SRS dasbor tabel urutan kerja C, jam 1 sampai 5).
