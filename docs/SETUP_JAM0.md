# Setup Jam 0

Langkah pertama begitu 12 jam dimulai. Folder ini **belum** jadi repo git, jadi commit pertama terjadi di dalam jam lomba.

## 1. Ketua: buat repo dan push pertama

Buat repo kosong `rivora` di GitHub (tanpa README/gitignore bawaan). Pastikan panitia bisa mengaksesnya: publik, atau undang panitia.

```bash
cd ~/RIVORA
git init -b main
git add .
git commit -m "chore: struktur awal repo RIVORA"
git remote add origin https://github.com/<username>/rivora.git
git push -u origin main
```

Undang 2 anggota lain sebagai collaborator.

## 2. Anggota lain: clone

```bash
git clone https://github.com/<username>/rivora.git
cd rivora
```

## 3. Inisialisasi per bagian

**A · Mobile (Flutter)**

```bash
cd mobile
flutter create . --project-name rivora --org id.rivora --platforms android
flutter pub add camera geolocator http firebase_core firebase_messaging
```

Taruh `google-services.json` di `mobile/android/app/`. File ini sudah di-`.gitignore`; bagikan ke tim lewat Discord.

**B · Backend (Node.js + Express + PostGIS)**

```bash
cd backend
npm init -y
npm i express cors dotenv pg multer firebase-admin
npm i -D nodemon
docker run -d --name rivora-db -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=rivora -p 5432:5432 postgis/postgis:16-3.4
```

**C · Dasbor (React + Leaflet)**

```bash
cd dashboard
npm create vite@latest . -- --template react
npm i leaflet react-leaflet
```

Kalau Vite bertanya folder tidak kosong, pilih **Ignore files and continue**.

## 4. Semua

- Salin bagian yang sesuai dari `.env.example` ke `.env` di folder masing-masing.
- Hapus `.gitkeep` di folder yang sudah terisi.
- Commit kecil dan sering. Sebelum push: `git pull --rebase`.
- Hanya ubah folder milik sendiri. `db/schema.sql` dan `docs/API.md` hanya diubah B.
