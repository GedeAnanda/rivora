// FR-BE-09 · API 7.4: GET /rw/risk?kelurahan_id=1 → FeatureCollection poligon RW + skor + komponen + alasan.
const express = require('express');
const { ambilKelurahanId } = require('../errors');
const { BOBOT } = require('../risk/score');
const { hitungRisikoRw, metaHujan } = require('../risk/data');

const router = express.Router();

router.get('/risk', async (req, res) => {
  const { kelurahan, hujan, rw } = await hitungRisikoRw(ambilKelurahanId(req));
  res.json({
    type: 'FeatureCollection',
    meta: { kelurahan, ...metaHujan(hujan), bobot: BOBOT, dihitung_at: new Date() },
    features: rw.map(({ geometry, ...properties }) => ({ type: 'Feature', geometry, properties })),
  });
});

module.exports = router;
