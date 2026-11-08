# Panel detail RW dan saluran lebih nyaman dibaca, foto contoh per kondisi

**Waktu:** 2026-11-08 17:30

**Apa yang diubah**
Permintaan Wildan: panel "Kenapa skor ini?" dan detail saluran dirombak supaya lebih nyaman dibaca, dan slot foto yang tadinya hanya ikon kamera diisi foto yang sesuai kondisinya.

Panel RW ("Kenapa skor ini?"):
- Judul besar "RW 05" dengan lencana level di sebelahnya, lalu skor besar "0,41 skor risiko, dari 1,00".
- Kalimat alasan dipindah ke atas sebagai kotak ringkasan (huruf 16px, garis kiri berwarna level).
- Bagian "Yang dihitung": tiap faktor (Hujan, Sumbatan, Kerentanan) punya nama, sumbangan ke skor (+0,25), bilah lebih tebal, dan keterangan kalimat biasa. Rumus (0,62 × 0,4) tetap ada tapi kecil dan redup.
- Daftar "Saluran di RW": baris lebih tinggi (56px), nama saluran di atas, kondisi di bawah.

Panel saluran:
- Judul "RW 11, inlet jalan" (nomor saluran jadi label kecil di atasnya).
- Foto lebar penuh 16:10 di bawah judul. Klik foto tetap memperbesar.
- Kondisi dan skor sebagai satu baris besar, lalu fakta berlabel: Keyakinan AI, Penyebab, Catatan AI, Difoto.
- Tombol "Tugaskan petugas" selebar panel.
- Riwayat laporan jadi garis waktu dengan titik berwarna kelas.

Foto contoh:
- Data contoh (mode mock) sekarang punya `foto_url` asli sesuai kelas: `/contoh-saluran/{bersih|ringan|sedang|berat|tidak_terlihat}.jpg`. Laporan verifikasi dan tugas selesai memakai foto `bersih.jpg` sebagai foto sesudah.
- Catatan AI contoh untuk kelas ringan dan tidak terlihat diubah agar cocok dengan fotonya.
- Bila foto benar-benar tidak ada (data asli tanpa foto atau gagal dimuat), tetap tampil kotak "Foto tidak tersedia".

**File**
| File | Isi |
|---|---|
| `dashboard/src/components/RwDetail.jsx` | Susunan panel RW baru |
| `dashboard/src/components/SaluranDetail.jsx` | Susunan panel saluran baru, daftar fakta `<dl>`, garis waktu riwayat |
| `dashboard/src/components/Foto.jsx` | Ikon kamera sedikit lebih besar, perilaku sama |
| `dashboard/src/index.css` | Gaya `.rincian*`, `.kondisi*`, `.riwayat`, `.alasan`, `.baris-aksi` diganti `.skor-besar`, `.ringkasan-alasan`, `.faktor*`, `.detail-gambar`, `.status-kondisi`, `.fakta`, `.detail-aksi`, `.garis-waktu`. `.detail-kepala` tetap (dipakai dialog tugaskan) |
| `dashboard/src/mocks/seed.js`, `dashboard/src/mocks/server.js` | `foto_url` contoh per kelas, catatan contoh disesuaikan |
| `dashboard/public/contoh-saluran/*.jpg`, `KREDIT.md` | Lima foto contoh dan kreditnya |

**Kredit foto**
Semua dari Wikimedia Commons, CC BY-SA 4.0: Yemi festus (bersih), Halima Waziri (ringan), DayakSibiriak (sedang), Obuezie (berat), Crown2022 (tidak terlihat). Rincian di `dashboard/public/contoh-saluran/KREDIT.md`.

**Cara cek**
Tekan Ctrl+Shift+R. Klik satu RW lalu satu titik saluran. Sudah dicek dengan tangkapan layar Chrome headless pada 1440×1000. `npm run build` sukses.

**Catatan**
Foto contoh hanya untuk mode mock. Di backend asli, `foto_url` datang dari unggahan petugas atau warga.
