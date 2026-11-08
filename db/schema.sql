-- Skema basis data RIVORA (PostgreSQL + PostGIS). Pemilik: B (backend).
-- Sumber: docs/backend/SRS.md bagian 8. Enum memakai CHECK (mudah diubah saat hackathon).
-- Koordinat: GEOGRAPHY SRID 4326 (ST_DWithin/ST_Distance dalam meter). Waktu: TIMESTAMPTZ (UTC).
-- Aman dijalankan ulang: semua tabel di-drop dulu (data ikut hilang, isi lagi dengan npm run seed).

CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS prakiraan_hujan, tugas, laporan, saluran, titik_genangan,
  rw, pengguna, kelurahan CASCADE;

CREATE TABLE kelurahan (
  id         SERIAL PRIMARY KEY,
  nama       TEXT NOT NULL,
  kecamatan  TEXT,
  centroid   GEOGRAPHY(POINT, 4326) NOT NULL
);

CREATE TABLE pengguna (
  id             SERIAL PRIMARY KEY,
  username       TEXT UNIQUE NOT NULL,
  password_hash  TEXT NOT NULL,
  nama           TEXT NOT NULL,
  role           TEXT NOT NULL CHECK (role IN ('lurah', 'petugas', 'warga')),
  kelurahan_id   INT REFERENCES kelurahan(id),
  fcm_token      TEXT
);

CREATE TABLE rw (
  id                SERIAL PRIMARY KEY,
  kelurahan_id      INT NOT NULL REFERENCES kelurahan(id),
  nama              TEXT NOT NULL,
  geom              GEOGRAPHY(POLYGON, 4326) NOT NULL,
  elevasi_m         NUMERIC,                    -- DEMNAS di centroid RW
  elevasi_relatif   NUMERIC,                    -- 0..1, 1 = paling rendah di kelurahan
  jarak_genangan_m  NUMERIC,                    -- ke titik genangan langganan terdekat
  kerentanan        NUMERIC NOT NULL CHECK (kerentanan BETWEEN 0 AND 1)
);
CREATE INDEX rw_geom_idx ON rw USING GIST (geom);

CREATE TABLE titik_genangan (
  id      SERIAL PRIMARY KEY,
  nama    TEXT NOT NULL,
  geom    GEOGRAPHY(POINT, 4326) NOT NULL,
  sumber  TEXT
);

CREATE TABLE saluran (
  id         SERIAL PRIMARY KEY,
  rw_id      INT REFERENCES rw(id),           -- NULL = di luar wilayah
  jenis      TEXT NOT NULL CHECK (jenis IN ('terbuka', 'gorong_gorong', 'inlet_jalan')),
  geom       GEOGRAPHY(POINT, 4326) NOT NULL,
  dibuat_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX saluran_geom_idx ON saluran USING GIST (geom);

CREATE TABLE laporan (
  id             SERIAL PRIMARY KEY,
  saluran_id     INT NOT NULL REFERENCES saluran(id),
  pelapor_id     INT REFERENCES pengguna(id),  -- NULL = warga anonim
  sumber         TEXT NOT NULL DEFAULT 'laporan' CHECK (sumber IN ('laporan', 'verifikasi')),
  jenis_saluran  TEXT NOT NULL CHECK (jenis_saluran IN ('terbuka', 'gorong_gorong', 'inlet_jalan')),
  foto_url       TEXT NOT NULL,
  geom           GEOGRAPHY(POINT, 4326) NOT NULL,  -- posisi asli dari HP
  lokasi_demo    BOOLEAN NOT NULL DEFAULT false,
  captured_at    TIMESTAMPTZ NOT NULL,
  ai_json        JSONB,
  ai_sumber      TEXT NOT NULL CHECK (ai_sumber IN ('model', 'demo', 'gagal')),
  kelas          TEXT NOT NULL CHECK (kelas IN ('bersih', 'ringan', 'sedang', 'berat', 'tidak_terlihat')),
  skor_sumbatan  NUMERIC CHECK (skor_sumbatan BETWEEN 0 AND 1),
  keyakinan      TEXT NOT NULL CHECK (keyakinan IN ('rendah', 'sedang', 'tinggi')),
  status         TEXT NOT NULL CHECK (status IN ('dikirim', 'ditugaskan', 'ditangani', 'cek_manual')),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX laporan_saluran_waktu_idx ON laporan (saluran_id, captured_at DESC);

CREATE TABLE tugas (
  id                     SERIAL PRIMARY KEY,
  saluran_id             INT NOT NULL REFERENCES saluran(id),
  laporan_id             INT NOT NULL REFERENCES laporan(id),
  petugas_id             INT NOT NULL REFERENCES pengguna(id),
  ditugaskan_oleh        INT REFERENCES pengguna(id),
  status                 TEXT NOT NULL DEFAULT 'baru' CHECK (status IN ('baru', 'dikerjakan', 'selesai')),
  catatan                TEXT,
  foto_sesudah_url       TEXT,
  ai_verifikasi_json     JSONB,
  laporan_verifikasi_id  INT REFERENCES laporan(id),
  dibuat_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  selesai_at             TIMESTAMPTZ
);
-- Satu saluran hanya boleh punya satu tugas yang belum selesai (FR-BE-14)
CREATE UNIQUE INDEX tugas_aktif_per_saluran ON tugas (saluran_id) WHERE status <> 'selesai';

CREATE TABLE prakiraan_hujan (
  id            SERIAL PRIMARY KEY,
  kelurahan_id  INT NOT NULL REFERENCES kelurahan(id),
  fetched_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  total_24j_mm  NUMERIC NOT NULL,
  hourly_json   JSONB NOT NULL
);
-- Tambahan (bukan di SRS): ambil cache terbaru per kelurahan dengan cepat
CREATE INDEX prakiraan_hujan_terbaru_idx ON prakiraan_hujan (kelurahan_id, fetched_at DESC);
