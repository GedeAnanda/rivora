# Dasbor lebih mudah dibaca untuk lurah

**Waktu:** 2026-11-08 14:35

**Apa yang diubah**
Permintaan Wildan: penempatan tombol dan susunan dasbor dirombak supaya lebih sederhana dan mudah dibaca, karena lurah umumnya berusia 30 tahun ke atas. Prinsip dari `ui-ux-pro-max` (aksesibilitas dan target sentuh di prioritas tertinggi) dan `frontend-design` (satu tugas jelas per layar).

**Perubahan susunan**
| Sebelum | Sesudah | Alasan |
|---|---|---|
| Detail RW atau saluran muncul di bawah daftar, daftar terjepit | Detail menggantikan daftar di panel kanan, dengan tombol besar "Kembali ke daftar" | Satu hal dalam satu waktu, tidak perlu menggulir dua area |
| Tombol tutup berupa ikon X kecil | Tombol "Kembali ke daftar" berlabel, tinggi 48px | Tombol berlabel lebih mudah dikenali |
| Tab "Prioritas", "Tugas", "Cek" | "Perlu dibersihkan", "Tugas petugas", "Cek langsung" | Bahasa sehari-hari, tidak perlu ditebak |
| Tombol "Tugaskan" kecil di pojok kartu | Tombol lebar "Tugaskan petugas" di bawah tiap kartu, tinggi 48px | Aksi utama jelas dan mudah diklik |
| Status tugas teks kecil biru | Kotak biru "Ditugaskan ke Asep Saepudin, dikerjakan" | Terbaca sekali lihat |
| Judul kartu "Saluran terbuka · RW 12" | "RW 12, saluran terbuka", lalu kondisi, lalu "Dilaporkan 16 jam lalu. Keyakinan AI: Tinggi" | Yang dicari lurah (RW) diletakkan pertama |
| Penggeser simulasi hujan selalu tampil di kepala | Disimpan di balik tombol "Simulasi hujan" | Alat demo tidak mengganggu pemakaian harian |
| Slogan di kepala | Dihapus; diganti nama kelurahan di baris kedua | Mengurangi teks yang tidak dipakai |

**Perubahan ukuran**
- Huruf dasar 14,5px menjadi 16px. Teks kecil minimal 13,5px.
- Panel kanan 390px menjadi 440px.
- Tab tinggi 52px; tombol utama 48px; tombol kepala 40px; tombol zoom peta 40px.
- Judul kartu 17px, kondisi 15px, keterangan 14,5px. Panel "Kenapa skor ini?" 13,5 sampai 15px.

**File**
| File | Isi |
|---|---|
| `dashboard/src/pages/Dashboard.jsx` | Panel kanan: daftar atau detail (bukan keduanya). Label tab baru. Kepala tanpa slogan. Simulasi di dalam `<details>` |
| `dashboard/src/components/PriorityList.jsx` | Susunan kartu baru, tombol "Tugaskan petugas", status tugas dalam kalimat |
| `dashboard/src/components/ManualCheckList.jsx` | Susunan kartu sama dengan prioritas |
| `dashboard/src/components/RwDetail.jsx`, `SaluranDetail.jsx` | Tombol X dihapus (diganti "Kembali ke daftar" di Dashboard) |
| `dashboard/src/components/Ikon.jsx` | Ikon `kembali` |
| `dashboard/src/index.css` | Ukuran huruf dan tombol di atas, gaya `.tombol-tugaskan`, `.tombol-kembali`, `.status-tugas`, `.demo-hujan` |

**Catatan untuk SRS**
SRS dasbor bagian 5 menulis "panel detail muncul di bawah daftar". Sekarang detail menggantikan daftar. Isi panel dan semua FR tetap sama, tetapi kalimat di `docs/dashboard/SRS.md` perlu disesuaikan oleh pemilik dokumen (peran C).

**Cara cek**
Masuk dengan `lurah` di http://localhost:5173, tekan Ctrl+Shift+R.
- Klik kartu: panel kanan berganti detail, tombol "Kembali ke daftar" di atas.
- Klik "Tugaskan petugas": dialog pilih petugas.
- Klik "Simulasi hujan": panel kecil berisi penggeser.

Sudah dicek lewat tangkapan layar Chrome headless 1440x900: daftar, detail saluran, panel simulasi terbuka. `npm run build` sukses.

**Belum dikerjakan**
- Tab Tugas petugas dan Cek langsung serta dialog Tugaskan belum difoto ulang.
- Teks di dalam panel detail saluran (catatan AI, riwayat) masih 12,5 sampai 13,5px di beberapa tempat.
