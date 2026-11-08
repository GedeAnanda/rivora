require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const db = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

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

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint tidak ditemukan' });
});

// Error umum: tanpa stack trace ke klien
app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({ error: err.publicMessage || 'Terjadi kesalahan pada server' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`RIVORA API jalan di http://localhost:${PORT}`);
});
