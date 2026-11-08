import Foto from './Foto'
import Ikon from './Ikon'
import { StatusTugasAtauTombol } from './PriorityList'
import { JENIS, umur } from '../format'

/** Daftar perlu cek manual (FR-DB-08): saluran tertutup atau analisis AI gagal. */
export default function ManualCheckList({ data, saluranTerpilih, onPilih, onTugaskan }) {
  if (!data) return <p className="teks-redup">Memuat...</p>
  const daftar = data.cek_manual

  return (
    <div>
      <div className="kepala-daftar">
        <Ikon nama="mata_tutup" ukuran={15} /> AI tidak bisa menilai saluran ini. Tidak masuk skor, petugas perlu mengecek langsung.
      </div>
      {daftar.length === 0 && <p className="teks-redup kosong">Tidak ada saluran yang perlu dicek manual.</p>}
      <ul className="daftar">
        {daftar.map((c) => (
          <li
            key={c.saluran_id}
            className={`kartu-item${c.saluran_id === saluranTerpilih ? ' terpilih' : ''}`}
            style={{ '--tepi': 'var(--kelas-tidak_terlihat)' }}
            tabIndex={0}
            onClick={() => onPilih(c.saluran_id)}
            onKeyDown={(e) => e.key === 'Enter' && onPilih(c.saluran_id)}
          >
            <Foto url={c.foto_url} alt="Foto saluran" kecil bisaPerbesar={false} />
            <div className="item-isi">
              <div className="item-judul">
                {JENIS[c.jenis]} · {c.rw_nama}
              </div>
              <div className="teks-redup kecil">{c.catatan}</div>
              <div className="item-bawah">
                <StatusTugasAtauTombol tugasAktif={c.tugas_aktif} onTugaskan={() => onTugaskan(c)} />
                <span className="teks-redup kecil">{umur(c.captured_at)}</span>
              </div>
            </div>
          </li>
        ))}
      </ul>
    </div>
  )
}
