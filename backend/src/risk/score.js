// Rumus skor RIVORA (SRS bag. 9). Fungsi murni, tanpa DB. Bobot = [ASUMSI], bukan hasil kalibrasi.

const BOBOT_KEYAKINAN = { tinggi: 1.0, sedang: 0.6, rendah: 0.3 };
const BOBOT = { hujan: 0.4, sumbatan: 0.4, kerentanan: 0.2 };
const HUJAN_LEBAT_MM = 50;

const bulat2 = (x) => Math.round(x * 100) / 100;
const batas01 = (x) => Math.min(Math.max(x, 0), 1);

// H = min(mm_24j / 100, 1)
function skorH(mm24j) {
  const mm = Number(mm24j);
  return Number.isFinite(mm) ? batas01(mm / 100) : 0;
}

// S = rata-rata tertimbang skor_sumbatan kondisi terkini tiap saluran.
// Abaikan kelas tidak_terlihat & ai_sumber gagal. Tanpa data → s 0, data_cukup false.
function skorS(kondisiList) {
  let jumlahBobot = 0;
  let jumlah = 0;
  let n = 0;
  for (const k of kondisiList || []) {
    if (k.kelas === 'tidak_terlihat' || k.ai_sumber === 'gagal') continue;
    const skor = Number(k.skor_sumbatan);
    const bobot = BOBOT_KEYAKINAN[k.keyakinan];
    if (k.skor_sumbatan == null || !Number.isFinite(skor) || !bobot) continue;
    jumlah += bobot * batas01(skor);
    jumlahBobot += bobot;
    n += 1;
  }
  if (n === 0) return { s: 0, data_cukup: false, jumlah_saluran: 0 };
  return { s: jumlah / jumlahBobot, data_cukup: true, jumlah_saluran: n };
}

// K = 0,5·elevasi_relatif + 0,5·(1 − min(jarak_genangan_m/1000, 1)). Dihitung saat seed.
function skorK(elevasiRelatif, jarakGenanganM) {
  const e = batas01(Number(elevasiRelatif) || 0);
  const j = batas01((Number(jarakGenanganM) || 0) / 1000);
  return 0.5 * e + 0.5 * (1 - j);
}

function level(skor) {
  if (skor >= 0.7) return 'risiko_tinggi';
  if (skor >= 0.4) return 'waspada';
  return 'aman';
}

// Skor RW = 0,4·H + 0,4·S + 0,2·K (dibulatkan 2 desimal, level dari nilai bulat)
function skorRw({ h, s, k }) {
  const skor = bulat2(0.4 * h + 0.4 * s + 0.2 * k);
  return { skor, level: level(skor) };
}

// Skor prioritas saluran = 0,4·H + 0,4·skor_sumbatan + 0,2·K_rw
function skorPrioritas({ h, skorSumbatan, kRw }) {
  return bulat2(0.4 * h + 0.4 * (Number(skorSumbatan) || 0) + 0.2 * kRw);
}

module.exports = { BOBOT_KEYAKINAN, BOBOT, HUJAN_LEBAT_MM, bulat2, skorH, skorS, skorK, level, skorRw, skorPrioritas };
