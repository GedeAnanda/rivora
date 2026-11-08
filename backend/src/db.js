const { Pool, types } = require('pg');

// NUMERIC (oid 1700) dikembalikan pg sebagai string → ubah ke number agar JSON berisi angka.
types.setTypeParser(1700, (v) => (v === null ? null : parseFloat(v)));

// DB_SSL=1 untuk Supabase/cloud (sertifikat pooler tidak diverifikasi), kosong/0 untuk Postgres lokal.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DB_SSL === '1' ? { rejectUnauthorized: false } : false,
  max: 5,
});

pool.on('error', (err) => {
  console.error('Koneksi DB error:', err.message);
});

module.exports = {
  pool,
  query: (text, params) => pool.query(text, params),
};
