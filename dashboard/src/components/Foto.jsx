import { useState } from 'react'
import Ikon from './Ikon'

/** Foto saluran. Gagal dimuat -> placeholder (NFR-03). Klik foto -> perbesar. */
export default function Foto({ url, alt, kecil, bisaPerbesar = true }) {
  const [gagal, setGagal] = useState(false)
  const [besar, setBesar] = useState(false)

  if (!url || gagal) {
    return (
      <div className={`foto-kosong${kecil ? ' kecil' : ''}`}>
        <Ikon nama="kamera" ukuran={kecil ? 18 : 28} />
        {!kecil && <span>Foto tidak tersedia</span>}
      </div>
    )
  }
  return (
    <>
      <img
        src={url}
        alt={alt}
        loading="lazy"
        className={`foto${kecil ? ' kecil' : ''}${bisaPerbesar ? ' bisa-klik' : ''}`}
        onError={() => setGagal(true)}
        onClick={bisaPerbesar ? () => setBesar(true) : undefined}
      />
      {besar && (
        <div className="latar" onClick={() => setBesar(false)} role="dialog" aria-label="Foto diperbesar">
          <img src={url} alt={alt} className="foto-besar" />
        </div>
      )}
    </>
  )
}
