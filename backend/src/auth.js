// FR-BE-01 · API 7.1: POST /auth/login + middleware token (JWT HS256, 24 jam, bcrypt).
const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('./db');
const { httpError } = require('./errors');

if (!process.env.JWT_SECRET) console.warn('PERINGATAN: JWT_SECRET belum diisi di .env, login tidak akan jalan');

const router = express.Router();

router.post('/login', async (req, res) => {
  const { username, password } = req.body || {};
  if (typeof username !== 'string' || !username.trim() || typeof password !== 'string' || !password) {
    throw httpError(400, 'username dan password wajib diisi');
  }
  if (!process.env.JWT_SECRET) throw httpError(500, 'Server belum siap untuk login');

  const { rows } = await db.query(
    'SELECT id, password_hash, nama, role, kelurahan_id FROM pengguna WHERE username = $1',
    [username.trim()]
  );
  const u = rows[0];
  if (!u || !(await bcrypt.compare(password, u.password_hash))) {
    throw httpError(401, 'Username atau password salah');
  }
  const token = jwt.sign(
    { sub: String(u.id), role: u.role, kelurahan_id: u.kelurahan_id },
    process.env.JWT_SECRET,
    { algorithm: 'HS256', expiresIn: '24h' }
  );
  res.json({ token, role: u.role, pengguna: { id: u.id, nama: u.nama, kelurahan_id: u.kelurahan_id } });
});

// Global: baca "Authorization: Bearer <token>" bila ada → req.user. Tanpa token tetap lanjut (token opsional).
// Token rusak/kedaluwarsa tidak langsung ditolak di sini, supaya laporan warga tetap masuk;
// route yang wajib login akan menolaknya lewat wajibLogin().
function bacaToken(req, res, next) {
  const header = req.get('authorization');
  if (!header) return next();
  const cocok = /^Bearer\s+(\S+)$/i.exec(header);
  try {
    if (!cocok) throw new Error('format');
    const p = jwt.verify(cocok[1], process.env.JWT_SECRET, { algorithms: ['HS256'] });
    req.user = { id: Number(p.sub), role: p.role, kelurahan_id: p.kelurahan_id };
  } catch (err) {
    req.tokenTidakValid = true;
  }
  next();
}

// Pakai di route: wajibLogin() = siapa saja yang login, wajibLogin('lurah') = hanya lurah.
function wajibLogin(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return next(httpError(401, req.tokenTidakValid ? 'Token tidak valid atau kedaluwarsa' : 'Perlu login'));
    }
    if (roles.length && !roles.includes(req.user.role)) return next(httpError(403, 'Akses ditolak untuk peran ini'));
    next();
  };
}

module.exports = { router, bacaToken, wajibLogin };
