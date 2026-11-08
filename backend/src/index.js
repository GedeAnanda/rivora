require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();
app.set('trust proxy', 1); // foto_url pakai https saat di belakang proxy (deploy)
app.use(cors());
app.use(express.json());

app.use('/uploads', express.static(require('./routes/reports').UPLOAD_DIR));

// FR-BE-22 · SRS 7.11: { ok, demo_mode, ai_siap, db }
app.get('/health', async (req, res) => {
  let dbStatus = 'ok';
  try {
    await db.query('SELECT postgis_version()');
  } catch (err) {
    dbStatus = 'gagal';
    console.error('Health DB gagal:', err.message);
  }
  let aiSiap = false;
  try {
    const ai = require('./ai');
    aiSiap = typeof ai.analyzeReport === 'function' && typeof ai.verifyCleaning === 'function';
  } catch (err) {
    aiSiap = false; // modul AI (milik C) belum ada
  }
  res.json({
    ok: dbStatus === 'ok',
    demo_mode: process.env.DEMO_MODE === '1',
    ai_siap: aiSiap,
    db: dbStatus,
  });
});

const auth = require('./auth');
app.use(auth.bacaToken); // FR-BE-01: req.user bila ada token
app.use('/auth', auth.router); // POST /auth/login
app.use('/reports', require('./routes/reports')); // FR-BE-02/03/07
app.use('/rw', require('./routes/rw')); // FR-BE-09
app.use('/saluran', require('./routes/saluran')); // FR-BE-10/11
app.use('/priorities', require('./routes/priorities')); // FR-BE-12
app.use('/tasks', require('./routes/tasks')); // FR-BE-14/15/17
app.use(require('./routes/lainnya')); // FR-BE-13 /petugas, FR-BE-16 /devices, FR-BE-20 /demo/hujan

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint tidak ditemukan' });
});

// Error umum: tanpa stack trace ke klien
app.use((err, req, res, next) => {
  const status = err.status || err.statusCode || 500;
  if (status >= 500) console.error(err);
  let pesan = err.publicMessage;
  if (!pesan && err.type === 'entity.parse.failed') pesan = 'Body JSON tidak valid';
  if (!pesan && err.type === 'entity.too.large') pesan = 'Body terlalu besar';
  if (!pesan) pesan = status < 500 ? 'Permintaan tidak valid' : 'Terjadi kesalahan pada server';
  res.status(status).json({ error: pesan });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`RIVORA API jalan di http://localhost:${PORT}`);
});
