import { SUMBER_HUJAN, jamWib, mm } from '../format'

/** Kartu prakiraan hujan di kepala dasbor (FR-DB-02). Sumber: meta dari GET /rw/risk. */
export default function RainCard({ meta }) {
  if (!meta) return null
  const tidakAda = meta.hujan_sumber === 'tidak_tersedia'
  return (
    <div className={`kartu-hujan${tidakAda ? ' redup' : ''}`}>
      <div>
        <div className="hujan-baris">
          <span>Hujan 24 jam:</span>
          <strong className="hujan-angka">{tidakAda ? '-' : mm(meta.hujan_24j_mm)}</strong>
          {meta.hujan_lebat_diprediksi && (
            <span className="lencana lencana-lebat">
              Hujan lebat diprediksi
            </span>
          )}
        </div>
        <div className="hujan-sumber">
          {SUMBER_HUJAN[meta.hujan_sumber] ?? meta.hujan_sumber}
          {meta.hujan_sumber !== 'simulasi_demo' && !tidakAda && ` · ${jamWib(meta.hujan_diambil_at)}`}
        </div>
      </div>
    </div>
  )
}
