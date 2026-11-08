# Foto contoh berbeda untuk tiap laporan

**Waktu:** 2026-11-08 19:00

**Apa yang diubah**
Permintaan Wildan: foto saluran harus berbeda semua, jangan satu foto yang sama untuk setiap kategori (entri 30 memakai lima foto, satu per kelas).

Sekarang ada 29 foto, satu untuk tiap laporan contoh: bersih 5, ringan 6, sedang 8, berat 8, tidak terlihat 2. Foto dinamai `{kelas}-{nomor}.jpg` di `dashboard/public/contoh-saluran/`. Laporan verifikasi dan foto "sesudah" pada tugas selesai memakai foto yang sama (`bersih-5.jpg`) karena keduanya kejadian yang sama.

Semua foto dari Wikimedia Commons (CC BY-SA, CC BY, CC0), dipilih manual agar sesuai kelasnya dan tidak ada dua foto dari lokasi yang sama. Ukurannya diperkecil ke lebar 720px (JPEG 72%), total 4,4 MB. Kredit tiap foto ada di `dashboard/public/contoh-saluran/KREDIT.md`.

Catatan AI contoh untuk kelas ringan dan tidak terlihat diubah supaya cocok dengan semua foto di kelas itu:
- ringan: "Ada sedikit sampah atau tumbuhan di saluran, aliran masih lancar"
- tidak terlihat: "Isi saluran tidak terlihat jelas di foto, perlu dicek langsung"

**File**
| File | Isi |
|---|---|
| `dashboard/src/mocks/seed.js` | Fungsi `fotoContoh(kelas)` memberi nomor foto urut per kelas. Bila laporan sekelas melebihi jumlah foto, foto berulang dari nomor 1 |
| `dashboard/src/mocks/server.js` | Alat uji konsol (`lapor`, `verifikasi`) memakai `fotoContoh` juga |
| `dashboard/public/contoh-saluran/*.jpg` | 29 foto baru, lima foto lama per kelas dihapus |
| `dashboard/public/contoh-saluran/KREDIT.md` | Tabel kredit 29 foto |

**Cara cek**
Tekan Ctrl+Shift+R, lalu buka beberapa titik saluran dan tab "Cek langsung".
Sudah dicek: 29 laporan memakai 29 foto berbeda, semua file ada, kelas di nama file cocok dengan kelas laporan. Foto tampil di tab "Cek langsung" di Chrome headless. `npm run build` sukses.

**Catatan**
Bila jumlah laporan contoh di `RENCANA` ditambah, tambahkan juga foto dan angka di `JUMLAH_FOTO`, supaya foto tidak berulang.
