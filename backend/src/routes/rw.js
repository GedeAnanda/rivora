// FR-BE-09: GET /rw/risk?kelurahan_id=1 → GeoJSON FeatureCollection poligon RW + skor.
const express = require('express');
const { ambilKelurahanId } = require('../errors');
const { hitungRisikoRw } = require('../risk/data');

const router = express.Router();

router.get('/risk', async (req, res) => {
  const kelurahanId = ambilKelurahanId(req);
  const { hujan, rw } = await hitungRisikoRw(kelurahanId);
  res.json({
    type: 'FeatureCollection',
    kelurahan_id: kelurahanId,
    hujan_mm_24j: hujan.mm_24j,
    hujan_sumber: hujan.sumber,
    dihitung_at: new Date().toISOString(),
    features: rw.map(({ geometry, ...properties }) => ({ type: 'Feature', geometry, properties })),
  });
});

module.exports = router;
