// FR-BE-08: prakiraan hujan 24 jam dari Open-Meteo, cache 30 menit di tabel prakiraan_hujan.
// hujan_sumber [ASUMSI]:
//   open_meteo     = data Open-Meteo berumur ≤ 30 menit (baru diambil atau dari cache segar)
//   cache          = Open-Meteo gagal, dipakai data lama terakhir
//   tidak_tersedia = Open-Meteo gagal dan belum ada cache → mm 0
//   simulasi_demo  = nilai diatur lewat PUT /demo/hujan (FR-BE-20)
const db = require('../db');

const URL_DEFAULT = 'https://api.open-meteo.com/v1/forecast';
const CACHE_MS = 30 * 60 * 1000;
const JEDA_GAGAL_MS = 60 * 1000; // setelah gagal, jangan coba lagi selama 1 menit (agar API tidak lambat)
const TIMEOUT_MS = 8000;

let hujanDemo = null; // mm atau null (FR-BE-20)
const setHujanDemo = (mm) => { hujanDemo = mm; };
const getHujanDemo = () => hujanDemo;

const sedangAmbil = new Map(); // kelurahanId → Promise (cegah fetch ganda bersamaan)
const gagalTerakhir = new Map(); // kelurahanId → waktu gagal (ms)

async function cacheTerbaru(kelurahanId) {
  const { rows } = await db.query(
    `SELECT total_24j_mm, fetched_at FROM prakiraan_hujan
     WHERE kelurahan_id = $1 ORDER BY fetched_at DESC LIMIT 1`,
    [kelurahanId]
  );
  return rows[0] || null;
}

async function ambilOpenMeteo(kelurahanId) {
  const { rows } = await db.query(
    `SELECT ST_Y(centroid::geometry) AS lat, ST_X(centroid::geometry) AS lng FROM kelurahan WHERE id = $1`,
    [kelurahanId]
  );
  if (!rows[0]) throw new Error('kelurahan tidak ditemukan');

  const url = new URL(process.env.OPEN_METEO_URL || URL_DEFAULT);
  url.searchParams.set('latitude', rows[0].lat.toFixed(4));
  url.searchParams.set('longitude', rows[0].lng.toFixed(4));
  url.searchParams.set('hourly', 'precipitation');
  url.searchParams.set('forecast_days', '2');
  url.searchParams.set('timezone', 'UTC');

  const res = await fetch(url, { signal: AbortSignal.timeout(TIMEOUT_MS) });
  if (!res.ok) throw new Error(`Open-Meteo HTTP ${res.status}`);
  const data = await res.json();
  const waktu = data?.hourly?.time;
  const hujan = data?.hourly?.precipitation;
  if (!Array.isArray(waktu) || !Array.isArray(hujan)) throw new Error('format Open-Meteo tidak dikenal');

  // Jumlahkan 24 jam ke depan mulai jam berjalan (UTC)
  const mulai = new Date();
  mulai.setUTCMinutes(0, 0, 0);
  const akhir = mulai.getTime() + 24 * 3600 * 1000;
  let total = 0;
  const perJam = [];
  waktu.forEach((t, i) => {
    const ms = new Date(`${t}Z`).getTime();
    if (ms >= mulai.getTime() && ms < akhir) {
      const mm = Number(hujan[i]) || 0;
      total += mm;
      perJam.push({ time: `${t}Z`, mm });
    }
  });
  if (perJam.length === 0) throw new Error('Open-Meteo tidak mengirim data 24 jam ke depan');
  total = Math.round(total * 10) / 10;

  const simpan = await db.query(
    `INSERT INTO prakiraan_hujan (kelurahan_id, total_24j_mm, hourly_json)
     VALUES ($1, $2, $3) RETURNING fetched_at`,
    [kelurahanId, total, JSON.stringify(perJam)]
  );
  return { mm_24j: total, sumber: 'open_meteo', fetched_at: simpan.rows[0].fetched_at };
}

async function getHujan24j(kelurahanId) {
  if (hujanDemo != null) return { mm_24j: hujanDemo, sumber: 'simulasi_demo', fetched_at: new Date() };

  const cache = await cacheTerbaru(kelurahanId);
  if (cache && Date.now() - new Date(cache.fetched_at).getTime() < CACHE_MS) {
    return { mm_24j: Number(cache.total_24j_mm), sumber: 'open_meteo', fetched_at: cache.fetched_at };
  }

  const cadangan = () =>
    cache
      ? { mm_24j: Number(cache.total_24j_mm), sumber: 'cache', fetched_at: cache.fetched_at }
      : { mm_24j: 0, sumber: 'tidak_tersedia', fetched_at: null };

  if (Date.now() - (gagalTerakhir.get(kelurahanId) || 0) < JEDA_GAGAL_MS) return cadangan();

  if (!sedangAmbil.has(kelurahanId)) {
    sedangAmbil.set(
      kelurahanId,
      ambilOpenMeteo(kelurahanId).finally(() => sedangAmbil.delete(kelurahanId))
    );
  }
  try {
    const hasil = await sedangAmbil.get(kelurahanId);
    gagalTerakhir.delete(kelurahanId);
    return hasil;
  } catch (err) {
    console.error('Open-Meteo gagal:', err.message);
    gagalTerakhir.set(kelurahanId, Date.now());
    return cadangan();
  }
}

module.exports = { getHujan24j, setHujanDemo, getHujanDemo };
