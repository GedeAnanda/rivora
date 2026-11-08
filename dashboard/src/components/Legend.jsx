import Ikon from './Ikon'
import { BELUM_ADA_DATA, KELAS, LEVEL, WARNA_DITUGASKAN } from '../format'

/** Legenda pojok kiri bawah peta (FR-DB-05). */
export default function Legend() {
  return (
    <details className="legenda" open>
      <summary>Legenda</summary>
      <div className="legenda-judul">Level risiko RW</div>
      {[...Object.values(LEVEL), BELUM_ADA_DATA].map((l) => (
        <div key={l.label} className="legenda-baris">
          <span
            className="kotak-level"
            style={{
              background: l.warna,
              opacity: l === BELUM_ADA_DATA ? 0.45 : 0.75,
              outline: l === BELUM_ADA_DATA ? `2px dashed ${l.warna}` : 'none',
            }}
          />
          <Ikon nama={l.ikon} ukuran={12} />
          {l.label}
        </div>
      ))}
      <div className="legenda-judul">Kondisi saluran</div>
      {Object.entries(KELAS).map(([kunci, k]) => (
        <div key={kunci} className="legenda-baris">
          <span className="titik-kelas" style={{ background: k.warna }} />
          {k.label}
        </div>
      ))}
      <div className="legenda-baris">
        <span className="cincin" style={{ borderColor: WARNA_DITUGASKAN }} />
        Sedang ditugaskan
      </div>
      <div className="legenda-catatan">Batas RW ilustrasi, bukan batas resmi</div>
    </details>
  )
}
