import { useEffect, useState } from 'react'
import Ikon from './Ikon'
import { api } from '../api/client'
import { JENIS } from '../format'

/** Dialog Tugaskan petugas (FR-DB-10). */
export default function AssignDialog({ saluran, onTutup, onSelesai }) {
  const [petugas, setPetugas] = useState(null)
  const [pilihan, setPilihan] = useState(null)
  const [catatan, setCatatan] = useState('')
  const [kirim, setKirim] = useState(false)
  const [galat, setGalat] = useState(null)

  useEffect(() => {
    api
      .petugas()
      .then(setPetugas)
      .catch((e) => setGalat(e.message))
  }, [])

  useEffect(() => {
    const esc = (e) => e.key === 'Escape' && !kirim && onTutup()
    window.addEventListener('keydown', esc)
    return () => window.removeEventListener('keydown', esc)
  }, [kirim, onTutup])

  async function simpan() {
    setKirim(true)
    setGalat(null)
    try {
      const res = await api.createTask({ saluran_id: saluran.saluran_id, petugas_id: pilihan, catatan: catatan.trim() || undefined })
      onSelesai(res)
    } catch (e) {
      setGalat(e.status === 409 ? 'Saluran ini sudah punya tugas aktif' : e.message)
      setKirim(false)
    }
  }

  return (
    <div className="latar" onClick={() => !kirim && onTutup()}>
      <div className="dialog" role="dialog" aria-modal="true" aria-label="Tugaskan petugas" onClick={(e) => e.stopPropagation()}>
        <div className="detail-kepala">
          <div>
            <div className="teks-redup kecil">Tugaskan petugas</div>
            <h2>
              {JENIS[saluran.jenis]} · {saluran.rw_nama}
            </h2>
          </div>
          <button className="tombol-ikon" onClick={onTutup} disabled={kirim} aria-label="Tutup">
            <Ikon nama="tutup" />
          </button>
        </div>

        <fieldset className="pilihan-petugas" disabled={kirim}>
          <legend className="teks-redup kecil">Pilih petugas</legend>
          {!petugas && !galat && <p className="teks-redup">Memuat daftar petugas...</p>}
          {petugas?.map((p) => (
            <label key={p.id} className={`opsi${pilihan === p.id ? ' dipilih' : ''}`}>
              <input type="radio" name="petugas" checked={pilihan === p.id} onChange={() => setPilihan(p.id)} />
              <span className="opsi-nama">{p.nama}</span>
              <span className="teks-redup kecil">{p.tugas_aktif} tugas aktif</span>
            </label>
          ))}
        </fieldset>

        <label className="label-isian">
          <span className="teks-redup kecil">Catatan (opsional)</span>
          <textarea
            rows={2}
            value={catatan}
            disabled={kirim}
            onChange={(e) => setCatatan(e.target.value)}
            placeholder="Contoh: prioritas sebelum hujan sore"
          />
        </label>

        {galat && <p className="galat">{galat}</p>}

        <div className="dialog-aksi">
          <button className="tombol tombol-garis" onClick={onTutup} disabled={kirim}>
            Batal
          </button>
          <button className="tombol" disabled={!pilihan || kirim} onClick={simpan}>
            {kirim ? 'Mengirim...' : 'Kirim tugas'}
          </button>
        </div>
      </div>
    </div>
  )
}
