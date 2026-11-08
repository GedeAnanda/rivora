// Ambil data DB + hitung skor RW (dipakai GET /rw/risk, nanti juga /priorities).
const db = require('../db');
const { skorH, skorS, skorRw, bulat2 } = require('./score');
const { getHujan24j } = require('../weather/openMeteo');

// Kondisi terkini tiap saluran = laporan valid terbaru (abaikan tidak_terlihat & gagal).
async function kondisiTerkini(kelurahanId) {
  const { rows } = await db.query(
    `SELECT DISTINCT ON (l.saluran_id)
       l.saluran_id, s.rw_id, l.kelas, l.skor_sumbatan, l.keyakinan, l.ai_sumber
     FROM laporan l
     JOIN saluran s ON s.id = l.saluran_id
     JOIN rw ON rw.id = s.rw_id
     WHERE rw.kelurahan_id = $1 AND l.kelas <> 'tidak_terlihat' AND l.ai_sumber <> 'gagal'
     ORDER BY l.saluran_id, l.captured_at DESC, l.id DESC`,
    [kelurahanId]
  );
  return rows;
}

async function hitungRisikoRw(kelurahanId) {
  const [hujan, rwRes, kondisi] = await Promise.all([
    getHujan24j(kelurahanId),
    db.query(
      `SELECT id, nama, kerentanan, ST_AsGeoJSON(geom)::json AS geometry
       FROM rw WHERE kelurahan_id = $1 ORDER BY id`,
      [kelurahanId]
    ),
    kondisiTerkini(kelurahanId),
  ]);
  const h = skorH(hujan.mm_24j);

  const perRw = new Map();
  for (const k of kondisi) {
    if (!perRw.has(k.rw_id)) perRw.set(k.rw_id, []);
    perRw.get(k.rw_id).push(k);
  }

  const rw = rwRes.rows.map((r) => {
    const s = skorS(perRw.get(r.id));
    const k = Number(r.kerentanan);
    const { skor, level } = skorRw({ h, s: s.s, k });
    return {
      id: r.id,
      nama: r.nama,
      geometry: r.geometry,
      skor,
      level,
      h: bulat2(h),
      s: bulat2(s.s),
      k: bulat2(k),
      data_cukup: s.data_cukup,
      jumlah_saluran_dinilai: s.jumlah_saluran,
    };
  });
  return { hujan, h, rw };
}

module.exports = { kondisiTerkini, hitungRisikoRw };
