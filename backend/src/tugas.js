// Objek tugas bentuk API 7.9. Dipakai GET /saluran/:id sekarang, nanti /tasks (FR-BE-14/15/17).
const db = require('./db');

const SELECT_TUGAS = `
  SELECT t.id, t.status, t.laporan_id, t.catatan, t.foto_sesudah_url, t.ai_verifikasi_json,
    t.dibuat_at, t.selesai_at,
    s.id AS s_id, s.jenis AS s_jenis, rw.nama AS s_rw_nama,
    ST_Y(s.geom::geometry) AS s_lat, ST_X(s.geom::geometry) AS s_lng,
    p.id AS p_id, p.nama AS p_nama,
    l.foto_url AS l_foto_url, l.kelas AS l_kelas, l.skor_sumbatan AS l_skor
  FROM tugas t
  JOIN saluran s ON s.id = t.saluran_id
  LEFT JOIN rw ON rw.id = s.rw_id
  JOIN pengguna p ON p.id = t.petugas_id
  JOIN laporan l ON l.id = t.laporan_id`;

function keTugas(r) {
  return {
    id: r.id,
    status: r.status,
    saluran: { id: r.s_id, jenis: r.s_jenis, rw_nama: r.s_rw_nama, lat: r.s_lat, lng: r.s_lng },
    petugas: { id: r.p_id, nama: r.p_nama },
    laporan_id: r.laporan_id,
    foto_sebelum_url: r.l_foto_url,
    kelas_sebelum: r.l_kelas,
    skor_sebelum: r.l_skor,
    foto_sesudah_url: r.foto_sesudah_url,
    verifikasi: r.ai_verifikasi_json,
    catatan: r.catatan,
    dibuat_at: r.dibuat_at,
    selesai_at: r.selesai_at,
  };
}

// where: potongan SQL internal (bukan input pengguna), contoh 'WHERE t.saluran_id = $1'
async function cariTugas(where, params = []) {
  const { rows } = await db.query(`${SELECT_TUGAS} ${where} ORDER BY t.dibuat_at DESC, t.id DESC`, params);
  return rows.map(keTugas);
}

module.exports = { cariTugas };
