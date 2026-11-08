import BeforeAfter from './BeforeAfter'
import { JENIS, STATUS_TUGAS, tanggalWib } from '../format'

const URUTAN = ['baru', 'dikerjakan', 'selesai']

/** Daftar tugas, dikelompokkan Baru -> Dikerjakan -> Selesai (FR-DB-11). */
export default function TaskList({ tugas, onPilih }) {
  if (!tugas) return <p className="teks-redup">Memuat tugas...</p>
  if (tugas.length === 0) return <p className="teks-redup kosong">Belum ada tugas. Tugaskan petugas dari tab Prioritas.</p>

  return URUTAN.map((status) => {
    const grup = tugas.filter((t) => t.status === status)
    if (!grup.length) return null
    return (
      <section key={status}>
        <h3 className={`judul-grup st-${status}`}>
          {STATUS_TUGAS[status]} <span className="teks-redup">({grup.length})</span>
        </h3>
        <ul className="daftar">
          {grup.map((t) => (
            <li
              key={t.id}
              className="kartu-item kolom"
              tabIndex={0}
              onClick={() => onPilih(t.saluran.id, [t.saluran.lat, t.saluran.lng])}
              onKeyDown={(e) => e.key === 'Enter' && onPilih(t.saluran.id, [t.saluran.lat, t.saluran.lng])}
            >
              <div className="item-judul">
                {JENIS[t.saluran.jenis]} · {t.saluran.rw_nama}
              </div>
              <p className="item-meta">Petugas: {t.petugas.nama}</p>
              <p className="item-meta">Dibuat {tanggalWib(t.dibuat_at)}</p>
              {t.catatan && <div className="teks-redup kecil">"{t.catatan}"</div>}
              {t.status === 'selesai' && <BeforeAfter tugas={t} ringkas />}
            </li>
          ))}
        </ul>
      </section>
    )
  })
}
