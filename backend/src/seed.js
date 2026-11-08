// FR-BE-18: npm run seed → isi data contoh 1 kelurahan. Aman diulang (TRUNCATE dulu).
// Semua angka di sini = [ASUMSI] data contoh, bukan data lapangan.
require('dotenv').config();
const bcrypt = require('bcrypt');
const db = require('./db');
const { skorK, bulat2 } = require('./risk/score');

const PASSWORD = process.env.SEED_PASSWORD;
// PUBLIC_URL = alamat API yang dipakai klien (mis. URL HTTPS deploy). Kosong → localhost.
const BASE_URL = (process.env.PUBLIC_URL || `http://localhost:${process.env.PORT || 3000}`).replace(/\/+$/, '');
const FOTO_CONTOH = `${BASE_URL}/uploads/contoh.jpg`;

// Grid 3 kolom × 2 baris, sel ±440 m. RW 01–03 baris atas, RW 04–06 baris bawah (lebih rendah).
const LNG0 = 107.684;
const LAT0 = -6.936;
const SEL = 0.004;

const RW = [
  { nama: 'RW 01', elevasi_m: 667, elevasi_relatif: 0.2, jarak_genangan_m: 900 },
  { nama: 'RW 02', elevasi_m: 666, elevasi_relatif: 0.4, jarak_genangan_m: 700 },
  { nama: 'RW 03', elevasi_m: 665, elevasi_relatif: 0.5, jarak_genangan_m: 600 },
  { nama: 'RW 04', elevasi_m: 664, elevasi_relatif: 0.6, jarak_genangan_m: 500 },
  { nama: 'RW 05', elevasi_m: 662, elevasi_relatif: 0.8, jarak_genangan_m: 400 }, // K = 0,70 (contoh SRS)
  { nama: 'RW 06', elevasi_m: 660, elevasi_relatif: 1.0, jarak_genangan_m: 150 },
];

// 2 saluran per RW: [jenis, kondisi laporan atau null]
const L = (kelas, skor, keyakinan) => ({ kelas, skor, keyakinan });
const SALURAN = [
  [['terbuka', L('bersih', 0.1, 'tinggi')], ['gorong_gorong', L('ringan', 0.3, 'sedang')]],
  [['inlet_jalan', null], ['terbuka', null]], // RW 02 belum ada laporan → data_cukup false
  [['terbuka', L('sedang', 0.55, 'sedang')], ['inlet_jalan', L('tidak_terlihat', null, 'rendah')]],
  [['gorong_gorong', L('ringan', 0.25, 'tinggi')], ['terbuka', L('sedang', 0.5, 'rendah')]],
  [['terbuka', L('berat', 0.85, 'tinggi')], ['gorong_gorong', L('berat', 0.85, 'tinggi')]],
  [['inlet_jalan', L('sedang', 0.6, 'tinggi')], ['terbuka', L('berat', 0.75, 'sedang')]],
];

const titik = (lng, lat) => `SRID=4326;POINT(${lng} ${lat})`;
function kotak(kol, baris) {
  const x0 = LNG0 + kol * SEL, y0 = LAT0 - baris * SEL, x1 = x0 + SEL, y1 = y0 - SEL;
  return `SRID=4326;POLYGON((${x0} ${y0}, ${x1} ${y0}, ${x1} ${y1}, ${x0} ${y1}, ${x0} ${y0}))`;
}

async function main() {
  if (!PASSWORD) throw new Error('SEED_PASSWORD belum diisi di backend/.env');
  const hash = await bcrypt.hash(PASSWORD, 10);
  const c = await db.pool.connect();
  try {
    await c.query('BEGIN');
    await c.query(`TRUNCATE prakiraan_hujan, tugas, laporan, saluran, titik_genangan, rw, pengguna, kelurahan
                   RESTART IDENTITY CASCADE`);

    const kel = await c.query(
      `INSERT INTO kelurahan (nama, kecamatan, centroid) VALUES ($1, $2, ST_GeogFromText($3)) RETURNING id`,
      ['Cisaranten Kidul', 'Gedebage', titik(LNG0 + 1.5 * SEL, LAT0 - SEL)]
    );
    const kelId = kel.rows[0].id;

    const akun = [
      ['lurah', 'Lurah Cisaranten Kidul', 'lurah'],
      ['petugas1', 'Petugas 1', 'petugas'],
      ['petugas2', 'Petugas 2', 'petugas'],
      ['warga', 'Warga Contoh', 'warga'],
    ];
    for (const [username, nama, role] of akun) {
      await c.query(
        'INSERT INTO pengguna (username, password_hash, nama, role, kelurahan_id) VALUES ($1, $2, $3, $4, $5)',
        [username, hash, nama, role, kelId]
      );
    }

    await c.query(
      `INSERT INTO titik_genangan (nama, geom, sumber) VALUES
       ('Genangan Jl. Contoh A', ST_GeogFromText($1), 'data contoh'),
       ('Genangan Jl. Contoh B', ST_GeogFromText($2), 'data contoh')`,
      [titik(LNG0 + 2.6 * SEL, LAT0 - 1.8 * SEL), titik(LNG0 + 1.4 * SEL, LAT0 - 2.1 * SEL)]
    );

    let jumlahLaporan = 0;
    for (let i = 0; i < RW.length; i++) {
      const r = RW[i];
      const kol = i % 3, baris = Math.floor(i / 3);
      const k = bulat2(skorK(r.elevasi_relatif, r.jarak_genangan_m));
      const rw = await c.query(
        `INSERT INTO rw (kelurahan_id, nama, geom, elevasi_m, elevasi_relatif, jarak_genangan_m, kerentanan)
         VALUES ($1, $2, ST_GeogFromText($3), $4, $5, $6, $7) RETURNING id`,
        [kelId, r.nama, kotak(kol, baris), r.elevasi_m, r.elevasi_relatif, r.jarak_genangan_m, k]
      );

      const posisi = [[0.3, 0.4], [0.7, 0.7]];
      for (let j = 0; j < SALURAN[i].length; j++) {
        const [jenis, lap] = SALURAN[i][j];
        const lng = LNG0 + (kol + posisi[j][0]) * SEL;
        const lat = LAT0 - (baris + posisi[j][1]) * SEL;
        const sal = await c.query(
          'INSERT INTO saluran (rw_id, jenis, geom) VALUES ($1, $2, ST_GeogFromText($3)) RETURNING id',
          [rw.rows[0].id, jenis, titik(lng, lat)]
        );
        if (!lap) continue;
        await c.query(
          `INSERT INTO laporan (saluran_id, jenis_saluran, foto_url, geom, captured_at, ai_json, ai_sumber,
             kelas, skor_sumbatan, keyakinan, status)
           VALUES ($1, $2, $3, ST_GeogFromText($4), now() - ($5 || ' hours')::interval, $6, 'demo', $7, $8, $9, $10)`,
          [sal.rows[0].id, jenis, FOTO_CONTOH, titik(lng, lat), String(j + 1),
            { kelas: lap.kelas, skor_sumbatan: lap.skor, keyakinan: lap.keyakinan, penyebab: lap.skor ? ['plastik'] : [], catatan: 'data contoh seed' },
            lap.kelas, lap.skor, lap.keyakinan, lap.kelas === 'tidak_terlihat' ? 'cek_manual' : 'dikirim']
        );
        jumlahLaporan++;
      }
    }

    await c.query('COMMIT');
    console.log(`Seed selesai: kelurahan_id=${kelId}, 4 akun, ${RW.length} RW, 12 saluran, ${jumlahLaporan} laporan.`);
  } catch (err) {
    await c.query('ROLLBACK');
    throw err;
  } finally {
    c.release();
    await db.pool.end();
  }
}

main().catch((err) => {
  console.error('Seed gagal:', err.message);
  process.exit(1);
});
