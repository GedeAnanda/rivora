# Alur Branch RIVORA

**Tujuan:** kode tidak langsung masuk ke `main`. Semua bagian (mobile, backend, dasbor) digabung dan diuji dulu di `dev`. `main` hanya berisi versi yang sudah jalan ujung ke ujung, karena `main` yang dilihat panitia saat code freeze.

```
feature/mobile   (A) ─┐
feature/backend  (B) ─┼──PR──▶  dev  ──PR (di checkpoint)──▶  main
feat/dashboard   (C) ─┘        (gabung + uji)                (versi stabil, code freeze)
```

## Peran tiap branch

| Branch | Isi | Siapa yang menulis |
|---|---|---|
| `main` | Versi stabil yang dinilai panitia | Hanya lewat PR dari `dev` |
| `dev` | Gabungan semua bagian, tempat uji ujung ke ujung | Hanya lewat PR dari branch fitur |
| `feature/mobile` | Aplikasi Flutter | A |
| `feature/backend` | API, DB, AI | B |
| `feat/dashboard` | Dasbor React | C |

Nama `feat/dashboard` tidak perlu diganti di tengah lomba; yang penting satu orang, satu branch.

## Kerja harian (semua anggota)

```bash
# 1. Mulai kerja: ambil perubahan terbaru dari dev
git switch feature/<bagianmu>
git pull origin dev

# 2. Kerja, commit kecil dan sering (dipantau panitia lewat riwayat commit)
git add <file>
git commit -m "feat(mobile): …"

# 3. Kirim ke branch sendiri
git push
```

Lalu buka **Pull Request ke `dev`** di GitHub:
`https://github.com/GedeAnanda/rivora/compare/dev...<branch-mu>`

## Aturan PR ke `dev`

1. **Base = `dev`**, bukan `main`. Cek ini sebelum klik "Create pull request".
2. Sebelum PR: `git pull origin dev` lalu jalankan cek bagianmu:
   - Mobile: `flutter analyze && flutter test`
   - Backend: server jalan + endpoint yang diubah dicoba
   - Dasbor: `npm run build` berhasil
3. Satu anggota lain melihat sekilas, lalu merge dengan **"Create a merge commit"** (jangan squash, supaya riwayat commit tiap anggota tetap terlihat).
4. Konflik: selesaikan di branch sendiri (`git pull origin dev`, perbaiki, commit, push). Jangan memperbaiki konflik langsung di `dev`.
5. Hanya ubah folder milik sendiri. `db/schema.sql` dan `docs/API.md` hanya diubah B (sesuai `SETUP_JAM0.md`).

## `dev` → `main` (di checkpoint)

Dilakukan bersama, hanya kalau `dev` sudah diuji ujung ke ujung (lapor dari HP → muncul di dasbor → tugaskan → verifikasi → skor turun):

| Kapan (Tabel 14) | Kenapa |
|---|---|
| Checkpoint jam 8 | Alur inti jalan |
| Jam 10 (fitur beku) | Versi untuk deploy dan video demo |
| Sebelum code freeze | Versi final yang dinilai |

PR: `https://github.com/GedeAnanda/rivora/compare/main...dev`, merge dengan "Create a merge commit".

## Pengaturan GitHub (pemilik repo, sekali saja)

Settings → Branches → **Add branch ruleset** (atau "Add rule"):

| Branch | Aturan |
|---|---|
| `main` | Require a pull request before merging · Block force pushes |
| `dev` | Require a pull request before merging · Block force pushes |

Jangan ubah default branch: biarkan `main`, karena itu yang dibuka panitia.

## Kalau salah langkah

| Kejadian | Perbaikan |
|---|---|
| Terlanjur commit di `dev`/`main` lokal | `git switch feature/<bagianmu>` lalu `git cherry-pick <hash>`; minta bantuan sebelum push |
| PR terlanjur ke `main` | Edit PR → ganti base ke `dev` |
| `git push` ditolak (non-fast-forward) | `git pull --rebase` lalu `git push`. Jangan `--force` |
