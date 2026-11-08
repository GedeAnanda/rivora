// FR-BE-12 · API 7.7: GET /priorities?kelurahan_id=1 → daftar saluran urut skor prioritas + daftar cek manual.
const express = require('express');
const { ambilKelurahanId } = require('../errors');
const { hitungPrioritas, metaHujan } = require('../risk/data');

const router = express.Router();

router.get('/', async (req, res) => {
  const { hujan, prioritas, cekManual } = await hitungPrioritas(ambilKelurahanId(req));
  const m = metaHujan(hujan);
  res.json({
    meta: {
      hujan_24j_mm: m.hujan_24j_mm,
      hujan_sumber: m.hujan_sumber,
      hujan_lebat_diprediksi: m.hujan_lebat_diprediksi,
      dihitung_at: new Date(),
    },
    prioritas,
    cek_manual: cekManual,
  });
});

module.exports = router;
