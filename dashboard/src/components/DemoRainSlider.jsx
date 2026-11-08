import { useEffect, useState } from 'react'
import Ikon from './Ikon'

/**
 * Simulasi hujan [DEMO] (FR-DB-14). Hanya dirender bila /health -> demo_mode: true.
 * Nilai dikirim lewat PUT /demo/hujan saat slider DILEPAS, bukan setiap digeser.
 */
export default function DemoRainSlider({ meta, onKirim }) {
  const aktif = meta?.hujan_sumber === 'simulasi_demo'
  const [nilai, setNilai] = useState(80)
  const [kirim, setKirim] = useState(false)

  // Ikuti nilai dari backend saat simulasi aktif (misalnya diubah dari laptop lain)
  useEffect(() => {
    if (aktif && meta?.hujan_24j_mm != null) setNilai(Math.round(meta.hujan_24j_mm))
  }, [aktif, meta?.hujan_24j_mm])

  async function jalankan(mmBaru) {
    setKirim(true)
    try {
      await onKirim(mmBaru)
    } finally {
      setKirim(false)
    }
  }

  return (
    <div className={`simulasi${aktif ? " aktif" : ""}`} title="Simulasi hujan untuk presentasi, bukan prakiraan asli">
      <span className="simulasi-label">Simulasi</span>
      <input
        type="range"
        min="0"
        max="100"
        step="5"
        value={nilai}
        disabled={kirim}
        onChange={(e) => setNilai(Number(e.target.value))}
        onPointerUp={(e) => jalankan(Number(e.currentTarget.value))}
        onKeyUp={(e) => ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Home', 'End'].includes(e.key) && jalankan(Number(e.currentTarget.value))}
        aria-label="Simulasi hujan 24 jam dalam mm"
      />
      <span className="simulasi-nilai">{nilai} mm</span>
      <button
        className="tombol-ikon terang"
        onClick={() => jalankan(null)}
        disabled={kirim || !aktif}
        aria-label="Kembali ke prakiraan asli"
        title="Kembali ke prakiraan asli"
      >
        <Ikon nama="ulang" />
      </button>
    </div>
  )
}
