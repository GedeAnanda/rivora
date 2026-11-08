// SEMENTARA (jam 1–5): H dummy. Diganti Open-Meteo + cache 30 menit di FR-BE-08.
// DUMMY_HUJAN_MM di .env opsional (default 80 → cocok dengan contoh hitung SRS).
async function getHujan24j(/* kelurahanId */) {
  const mm = Number(process.env.DUMMY_HUJAN_MM ?? 80);
  return { mm_24j: Number.isFinite(mm) ? mm : 0, sumber: 'simulasi_demo', fetched_at: new Date().toISOString() };
}

module.exports = { getHujan24j };
