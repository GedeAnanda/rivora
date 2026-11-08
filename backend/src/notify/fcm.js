// FR-BE-15: kirim notifikasi tugas baru lewat Firebase Cloud Messaging.
// Service account dari FIREBASE_SERVICE_ACCOUNT_PATH (tidak di-commit). Data FCM semua string.
// Hasil [ASUMSI]: 'terkirim' | 'gagal' | 'tanpa_token' (petugas belum POST /devices) | 'nonaktif' (Firebase belum disetel).
const path = require('path');
const db = require('../db');

let messaging; // undefined = belum dicoba, null = tidak tersedia

function ambilMessaging() {
  if (messaging !== undefined) return messaging;
  messaging = null;
  // Cloud tanpa file: FIREBASE_SERVICE_ACCOUNT_BASE64 = isi JSON service account di-base64.
  const b64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  const p = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!b64 && !p) {
    console.warn('FCM nonaktif: FIREBASE_SERVICE_ACCOUNT_BASE64/PATH belum diisi');
    return messaging;
  }
  try {
    const { initializeApp, cert } = require('firebase-admin/app');
    const { getMessaging } = require('firebase-admin/messaging');
    const akun = b64 ? JSON.parse(Buffer.from(b64, 'base64').toString('utf8')) : require(path.resolve(p));
    const app = initializeApp({ credential: cert(akun) }, 'rivora');
    messaging = getMessaging(app);
  } catch (err) {
    console.error('FCM gagal disiapkan:', err.message);
  }
  return messaging;
}

const TOKEN_MATI = ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'];

async function kirimTugasBaru(petugasId, tugas) {
  const { rows } = await db.query('SELECT fcm_token FROM pengguna WHERE id = $1', [petugasId]);
  const token = rows[0] && rows[0].fcm_token;
  if (!token) return 'tanpa_token';
  const m = ambilMessaging();
  if (!m) return 'nonaktif';

  const s = tugas.saluran;
  try {
    await m.send({
      token,
      notification: {
        title: 'Tugas baru RIVORA',
        body: `Bersihkan saluran ${s.jenis.replace('_', ' ')} di ${s.rw_nama || 'luar wilayah RW'}`,
      },
      data: {
        jenis: 'tugas_baru',
        tugas_id: String(tugas.id),
        saluran_id: String(s.id),
        lat: String(s.lat),
        lng: String(s.lng),
      },
      android: { priority: 'high' },
    });
    return 'terkirim';
  } catch (err) {
    console.error('FCM kirim gagal:', err.code || err.message);
    if (TOKEN_MATI.includes(err.code)) {
      await db.query('UPDATE pengguna SET fcm_token = NULL WHERE id = $1 AND fcm_token = $2', [petugasId, token]);
    }
    return 'gagal';
  }
}

module.exports = { kirimTugasBaru };
