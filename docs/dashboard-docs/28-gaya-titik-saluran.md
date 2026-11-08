# Gaya titik saluran di peta

**Waktu:** 2026-11-08 16:20

**Apa yang diubah**
Permintaan Wildan: titik saluran di peta dibuat sedikit berbeda. Perubahan di `dashboard/src/components/RiskMap.jsx` (`SaluranLayer`):

| | Sebelum | Sesudah |
|---|---|---|
| Titik biasa | radius 7, cincin putih 2px | radius 8, cincin putih 2,5px |
| Bayangan | tidak ada | lingkaran Samudra `#04214B` transparan 16%, radius 11, tanpa garis, di belakang titik |
| Titik terpilih | radius 10, cincin Samudra 3px | radius 11, cincin Samudra 3,5px, bayangan radius 15 (22%) |
| Cincin "sedang ditugaskan" | radius 12 (terpilih 15) | radius 14 (terpilih 17), menyesuaikan titik yang lebih besar |

Bayangan tidak menerima klik (`interactive={false}`), jadi tidak menghalangi klik pada titik.

**Cara cek**
Tekan Ctrl+Shift+R, lihat peta, klik salah satu kartu prioritas.
Sudah dicek: tangkapan layar 1440x900 dengan saluran terpilih, dan klik mouse sungguhan pada ke-21 titik di Chrome headless membuka detail. `npm run build` sukses.
