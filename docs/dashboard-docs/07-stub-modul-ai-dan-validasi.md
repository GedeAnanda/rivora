# [AI] Stub modul AI dan validasi keluaran

**Waktu:** 2026-11-08 10:10

**Apa yang diubah**
Mengisi `backend/src/ai/` sesuai antarmuka SRS backend bagian 10 (dua fungsi, CommonJS, tanpa dependensi). `.gitkeep` dihapus.

**File baru**
| File | Isi |
|---|---|
| `backend/src/ai/index.js` | `analyzeReport({ foto, mimeType, jenisSaluran })` dan `verifyCleaning({ fotoSebelum, fotoSesudah, mimeType })`. **Masih stub**: langsung mengembalikan contoh dengan `sumber: 'demo'`, plus log durasi |
| `backend/src/ai/contoh.js` | Hasil contoh bergiliran berat, sedang, bersih (Lampiran C) dan contoh verifikasi. Nanti dipakai juga untuk `DEMO_MODE=1` (FR-BE-19) |
| `backend/src/ai/validasi.js` | `validasiLaporan()` dan `validasiVerifikasi()`: enum, penyebab subset, kecocokan skor dengan kelas, `tidak_terlihat` -> skor null dan `saluran_terlihat: false` |

**Keputusan dan asumsi**
- Stub mengembalikan `sumber: 'demo'`, bukan `'model'`, supaya hasil contoh tidak tertukar dengan hasil model asli (NFR-09 kejujuran klaim).
- `jenis_saluran` hasil contoh mengikuti pilihan pelapor.
- [ASUMSI] Rentang skor per kelas inklusif di kedua batas (0,15 / 0,40 / 0,70 sah untuk dua kelas yang bersebelahan).
- [ASUMSI] Verifikasi dianggap bersih hanya bila `kelas_sesudah` bersih atau ringan. Foto sesudah yang `tidak_terlihat` tidak pernah dianggap bersih.

**Cara cek**
```bash
node -e "require('./backend/src/ai').analyzeReport({jenisSaluran:'terbuka'}).then(console.log)"
```
Sudah dicek: stub mengembalikan berat lalu sedang; validasi menerima contoh Lampiran C, menolak skor yang tidak cocok dengan kelas, menolak penyebab asing, merapikan `tidak_terlihat`, dan menolak `sudah_bersih: true` dengan kelas berat.

**Belum dikerjakan**
Pemanggilan model asli (Claude, keluaran JSON terstruktur), batas waktu 20 detik, ulang 1 kali, dan `DEMO_MODE`. Menunggu `backend/package.json` dari Jajang untuk menambah paket `@anthropic-ai/sdk`.
