import { KELAS, KEYAKINAN, infoLevel } from '../format'

/** Lencana level RW: teks + warna (NFR-04, level selalu ditulis). Menerima properties fitur RW. */
export function LencanaLevel({ props, kecil }) {
  const l = infoLevel(props)
  return (
    <span className={`lencana${kecil ? ' kecil' : ''}`} style={{ background: l.latar, color: l.teks, borderColor: l.latar }}>
      {l.label}
    </span>
  )
}

/** Lencana kelas sumbatan dengan warna yang sama seperti aplikasi mobile. */
export function LencanaKelas({ kelas }) {
  const k = KELAS[kelas]
  if (!k) return null
  return (
    <span className="lencana-kelas">
      <span className="titik-kelas" style={{ background: k.warna }} />
      {k.label}
    </span>
  )
}

/** "Keyakinan AI" selalu tampil (Tabel 8 proposal). */
export function Keyakinan({ nilai, rinci }) {
  if (!nilai) return null
  return (
    <span className={`keyakinan ky-${nilai}`}>
      Keyakinan AI: {KEYAKINAN[nilai] ?? nilai}
      {rinci && nilai === 'rendah' && <span className="teks-redup"> · perlu dikonfirmasi petugas</span>}
    </span>
  )
}

/** Label [DEMO] untuk hasil AI contoh atau lokasi demo (FR-DB-09). */
export function LabelDemo({ data }) {
  if (data?.ai_sumber !== 'demo' && !data?.lokasi_demo) return null
  return <span className="label-demo">contoh demo</span>
}
