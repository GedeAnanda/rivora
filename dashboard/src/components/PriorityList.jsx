import Ikon from './Ikon'
import { Keyakinan, LencanaKelas } from './Lencana'
import { JENIS, STATUS_TUGAS, angka2, umur } from '../format'

export function StatusTugasAtauTombol({ tugasAktif, onTugaskan }) {
  if (tugasAktif) {
    return (
      <span className="status-tugas">
        <Ikon nama="orang" ukuran={13} /> {tugasAktif.petugas_nama} · {STATUS_TUGAS[tugasAktif.status]}
      </span>
    )
  }
  return (
    <button
      className="tombol tombol-kecil"
      onClick={(e) => {
        e.stopPropagation()
        onTugaskan()
      }}
    >
      Tugaskan
    </button>
  )
}

/** Daftar prioritas sebelum hujan (FR-DB-07). Urutan = peringkat dari backend. */
export default function PriorityList({ data, saluranTerpilih, onPilih, onTugaskan }) {
  if (!data) return <p className="teks-redup">Memuat prioritas...</p>
  const { meta, prioritas } = data

  return (
    <div>
      <div className={`kepala-daftar${meta.hujan_lebat_diprediksi ? ' mendesak' : ''}`}>
        {meta.hujan_lebat_diprediksi ? (
          <>
            <Ikon nama="segitiga" ukuran={15} /> Bersihkan sebelum hujan: {prioritas.length} saluran
          </>
        ) : (
          <>
            <Ikon nama="info" ukuran={15} /> Tidak ada hujan lebat 24 jam ke depan. Urutan berdasarkan kondisi saluran.
          </>
        )}
      </div>

      {prioritas.length === 0 && <p className="teks-redup kosong">Tidak ada saluran yang perlu dibersihkan.</p>}

      <ol className="daftar">
        {prioritas.map((p) => (
          <li
            key={p.saluran_id}
            className={`kartu-item${p.saluran_id === saluranTerpilih ? ' terpilih' : ''}`}
            style={{ '--tepi': `var(--kelas-${p.kelas})` }}
            tabIndex={0}
            onClick={() => onPilih(p.saluran_id, [p.lat, p.lng])}
            onKeyDown={(e) => e.key === 'Enter' && onPilih(p.saluran_id, [p.lat, p.lng])}
          >
            <span className="peringkat">{p.peringkat}</span>
            <div className="item-isi">
              <div className="item-judul">
                {JENIS[p.jenis]} · {p.rw_nama}
              </div>
              <div className="item-meta">
                <LencanaKelas kelas={p.kelas} />
                <Keyakinan nilai={p.keyakinan} />
              </div>
              <div className="item-bawah">
                <StatusTugasAtauTombol tugasAktif={p.tugas_aktif} onTugaskan={() => onTugaskan(p)} />
                <span className="teks-redup kecil">{umur(p.captured_at)}</span>
              </div>
            </div>
            <div className="item-skor">
              <span className="teks-redup kecil">Skor</span>
              <span className="angka besar">{angka2(p.skor_prioritas)}</span>
            </div>
          </li>
        ))}
      </ol>
    </div>
  )
}
