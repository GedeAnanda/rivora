// FR-BE-13 GET /petugas (lurah) · FR-BE-16 POST /devices · FR-BE-20 PUT /demo/hujan [DEMO]. API 7.8 & 7.11.
const express = require('express');
const db = require('../db');
const { httpError } = require('../errors');
const { wajibLogin } = require('../auth');
const { demoAktif } = require('../demo');
const { setHujanDemo } = require('../weather/openMeteo');

const router = express.Router();

// 7.8: [{ id, nama, tugas_aktif }] — petugas di kelurahan lurah
router.get('/petugas', wajibLogin('lurah'), async (req, res) => {
  const { rows } = await db.query(
    `SELECT p.id, p.nama, COUNT(t.id)::int AS tugas_aktif
     FROM pengguna p
     LEFT JOIN tugas t ON t.petugas_id = p.id AND t.status <> 'selesai'
     WHERE p.role = 'petugas' AND ($1::int IS NULL OR p.kelurahan_id = $1)
     GROUP BY p.id ORDER BY p.id`,
    [req.user.kelurahan_id ?? null]
  );
  res.json(rows);
});

// 7.11: { fcm_token } → 204. Satu token hanya milik satu akun (HP ganti akun).
router.post('/devices', wajibLogin(), async (req, res) => {
  const token = req.body && req.body.fcm_token;
  if (typeof token !== 'string' || !token.trim() || token.length > 4096) {
    throw httpError(400, 'fcm_token wajib diisi');
  }
  await db.query('UPDATE pengguna SET fcm_token = NULL WHERE fcm_token = $1 AND id <> $2', [token.trim(), req.user.id]);
  await db.query('UPDATE pengguna SET fcm_token = $1 WHERE id = $2', [token.trim(), req.user.id]);
  res.status(204).end();
});

// 7.11 [DEMO]: { mm: 80 } atur hujan simulasi, { mm: null } kembali ke Open-Meteo. 404 bila DEMO_MODE mati.
router.put('/demo/hujan', (req, res, next) => {
  if (!demoAktif()) return next(httpError(404, 'Endpoint tidak ditemukan'));
  next();
}, wajibLogin('lurah'), (req, res) => {
  const mm = req.body ? req.body.mm : undefined;
  if (mm !== null && (typeof mm !== 'number' || !Number.isFinite(mm) || mm < 0 || mm > 500)) {
    throw httpError(400, 'mm harus angka 0–500 atau null');
  }
  setHujanDemo(mm);
  res.json({ mm });
});

module.exports = router;
