// Simpan foto unggahan ke Supabase Storage (bucket publik) agar tidak hilang saat server cloud restart.
// Aktif bila SUPABASE_URL + SUPABASE_SERVICE_KEY diisi; kalau tidak / gagal → URL lokal /uploads (dev).
const fs = require('fs');

const BUCKET = process.env.SUPABASE_BUCKET || 'foto';

function urlLokal(req, file) {
  return `${req.protocol}://${req.get('host')}/uploads/${file.filename}`;
}

async function simpanFoto(req, file) {
  const base = (process.env.SUPABASE_URL || '').replace(/\/+$/, '');
  const key = process.env.SUPABASE_SERVICE_KEY;
  if (!base || !key) return urlLokal(req, file);
  try {
    const isi = await fs.promises.readFile(file.path);
    const r = await fetch(`${base}/storage/v1/object/${BUCKET}/${file.filename}`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, apikey: key, 'Content-Type': file.mimetype, 'x-upsert': 'true' },
      body: isi,
      signal: AbortSignal.timeout(15000),
    });
    if (!r.ok) throw new Error(`status ${r.status} ${await r.text()}`);
    return `${base}/storage/v1/object/public/${BUCKET}/${file.filename}`;
  } catch (err) {
    console.error('Unggah Supabase Storage gagal, pakai URL lokal:', err.message);
    return urlLokal(req, file);
  }
}

module.exports = { simpanFoto };
