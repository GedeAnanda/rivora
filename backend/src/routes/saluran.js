// FR-BE-10: GET /saluran?kelurahan_id=1 → GeoJSON titik saluran + kondisi laporan terbaru.
const express = require('express');
const db = require('../db');
const { ambilKelurahanId } = require('../errors');

const router = express.Router();

router.get('/', async (req, res) => {
  const kelurahanId = ambilKelurahanId(req);
  const { rows } = await db.query(
    `SELECT s.id, s.jenis, s.rw_id, rw.nama AS rw_nama, ST_AsGeoJSON(s.geom)::json AS geometry,
       l.id AS laporan_id, l.kelas, l.skor_sumbatan, l.keyakinan, l.ai_sumber, l.status,
       l.foto_url, l.captured_at
     FROM saluran s
     JOIN rw ON rw.id = s.rw_id
     LEFT JOIN LATERAL (
       SELECT * FROM laporan WHERE saluran_id = s.id ORDER BY captured_at DESC, id DESC LIMIT 1
     ) l ON true
     WHERE rw.kelurahan_id = $1
     ORDER BY s.id`,
    [kelurahanId]
  );
  res.json({
    type: 'FeatureCollection',
    kelurahan_id: kelurahanId,
    features: rows.map(({ geometry, ...p }) => ({
      type: 'Feature',
      geometry,
      properties: { ...p, captured_at: p.captured_at ? p.captured_at.toISOString() : null },
    })),
  });
});

module.exports = router;
