// Error dengan pesan aman untuk klien (ditangani error handler di index.js)
function httpError(status, pesan) {
  const err = new Error(pesan);
  err.status = status;
  err.publicMessage = pesan;
  return err;
}

// ?kelurahan_id=… (default 1, prototipe 1 kelurahan)
function ambilKelurahanId(req) {
  const id = Number(req.query.kelurahan_id ?? 1);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'kelurahan_id tidak valid');
  return id;
}

// :id di path harus bilangan bulat positif
function ambilId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'id tidak valid');
  return id;
}

module.exports = { httpError, ambilKelurahanId, ambilId };
