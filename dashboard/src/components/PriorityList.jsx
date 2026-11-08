import { Keyakinan, LencanaKelas } from './Lencana'
import { JENIS, STATUS_TUGAS, angka2, umur } from '../format'

export function StatusTugasAtauTombol({ tugasAktif, onTugaskan }) {
  if (tugasAktif) {
    return (
      <p className="status-tugas">

        <span>
          Ditugaskan ke <strong>{tugasAktif.petugas_nama}</strong>, {STATUS_TUGAS[tugasAktif.status].toLowerCase()}
        </span>
      </p>
    )
  }
  return (
    <button
      className="tombol tombol-tugaskan"
      onClick={(e) => {
        e.stopPropagation()
        onTugaskan()
      }}
    >
      Tugaskan petugas
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
            Bersihkan sebelum hujan: {prioritas.length} saluran
          </>
        ) : (
          <>
            Tidak ada hujan lebat 24 jam ke depan. Urutan berdasarkan kondisi saluran.
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
            <div className="item-atas">
              <span className="peringkat" aria-label={`Urutan ${p.peringkat}`}>{p.peringkat}</span>
              <div className="item-isi">
                <h3 className="item-judul">
                  {p.rw_nama}, {JENIS[p.jenis].toLowerCase()}
                </h3>
                <LencanaKelas kelas={p.kelas} />
                <p className="item-meta">
                  Dilaporkan {umur(p.captured_at)}. <Keyakinan nilai={p.keyakinan} />
                </p>
              </div>
              <div className="item-skor">
                <span>Skor</span>
                <span className="angka besar">{angka2(p.skor_prioritas)}</span>
              </div>
            </div>
            <StatusTugasAtauTombol tugasAktif={p.tugas_aktif} onTugaskan={() => onTugaskan(p)} />
          </li>
        ))}
      </ol>
    </div>
  )
}
