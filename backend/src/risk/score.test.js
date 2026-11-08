// Jalankan: npm test  (node:test bawaan Node ≥ 18)
const test = require('node:test');
const assert = require('node:assert/strict');
const { skorH, skorS, skorK, skorRw, level, skorPrioritas } = require('./score');

const berat = { kelas: 'berat', skor_sumbatan: 0.85, keyakinan: 'tinggi', ai_sumber: 'model' };
const bersih = { kelas: 'bersih', skor_sumbatan: 0.08, keyakinan: 'tinggi', ai_sumber: 'model' };

test('Contoh SRS: RW 05, K 0,70, hujan 80 mm, berat 0,85 → 0,80 risiko_tinggi', () => {
  const r = skorRw({ h: skorH(80), s: skorS([berat]).s, k: 0.7 });
  assert.deepEqual(r, { skor: 0.8, level: 'risiko_tinggi' });
});

test('Contoh SRS: sesudah dibersihkan 0,08 → 0,49 waspada', () => {
  const r = skorRw({ h: skorH(80), s: skorS([bersih]).s, k: 0.7 });
  assert.deepEqual(r, { skor: 0.49, level: 'waspada' });
});

test('Contoh SRS: tanpa hujan → 0,48', () => {
  const r = skorRw({ h: skorH(0), s: skorS([berat]).s, k: 0.7 });
  assert.deepEqual(r, { skor: 0.48, level: 'waspada' });
});

test('H dibatasi 1 dan tahan input aneh', () => {
  assert.equal(skorH(150), 1);
  assert.equal(skorH(null), 0);
  assert.equal(skorH(-5), 0);
});

test('S: bobot keyakinan, abaikan tidak_terlihat & gagal', () => {
  const r = skorS([
    { kelas: 'berat', skor_sumbatan: 1, keyakinan: 'tinggi', ai_sumber: 'model' },
    { kelas: 'bersih', skor_sumbatan: 0, keyakinan: 'rendah', ai_sumber: 'demo' },
    { kelas: 'tidak_terlihat', skor_sumbatan: null, keyakinan: 'rendah', ai_sumber: 'model' },
    { kelas: 'sedang', skor_sumbatan: 0.5, keyakinan: 'tinggi', ai_sumber: 'gagal' },
  ]);
  assert.equal(r.data_cukup, true);
  assert.equal(r.jumlah_saluran, 2);
  assert.ok(Math.abs(r.s - 1 / 1.3) < 1e-9);
});

test('S tanpa data → 0, data_cukup false', () => {
  assert.deepEqual(skorS([]), { s: 0, data_cukup: false, jumlah_saluran: 0 });
});

test('K: elevasi 0,8 & jarak 400 m → 0,70', () => {
  assert.ok(Math.abs(skorK(0.8, 400) - 0.7) < 1e-9);
  assert.equal(skorK(0, 5000), 0);
});

test('Batas level', () => {
  assert.equal(level(0.39), 'aman');
  assert.equal(level(0.4), 'waspada');
  assert.equal(level(0.69), 'waspada');
  assert.equal(level(0.7), 'risiko_tinggi');
});

test('Skor prioritas saluran', () => {
  assert.equal(skorPrioritas({ h: 0.8, skorSumbatan: 0.85, kRw: 0.7 }), 0.8);
});
