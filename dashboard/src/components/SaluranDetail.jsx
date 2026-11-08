import BeforeAfter from './BeforeAfter'
import Foto from './Foto'
import Ikon from './Ikon'
import { Keyakinan, LabelDemo, LencanaKelas } from './Lencana'
import { StatusTugasAtauTombol } from './PriorityList'
import { JENIS, PENYEBAB, STATUS_LAPORAN, angka2, tanggalWib, umur } from '../format'

/** Detail saluran dari GET /saluran/:id (FR-DB-09, FR-DB-12). */
export default function SaluranDetail({ data, galat, onTugaskan, onTutup }) {
  if (galat && !data) {
    return (
      <section className="panel-detail">
        <div className="detail-kepala">
          <p className="galat">{galat}</p>
          <button className="tombol-ikon" onClick={onTutup} aria-label="Tutup panel saluran">
            <Ikon nama="tutup" />
          </button>
        </div>
      </section>
    )
  }
  if (!data) return <section className="panel-detail teks-redup">Memuat detail saluran...</section>

  const riwayat = data.riwayat ?? []
  const terbaru = riwayat[0]
  const tugasAktif = data.tugas?.find((t) => t.status !== 'selesai')
  const tugasSelesai = data.tugas?.find((t) => t.status === 'selesai')

  return (
    <section className="panel-detail">
      <div className="detail-kepala">
        <div>
          <div className="teks-redup kecil">Saluran #{data.saluran_id}</div>
          <h2>
            {JENIS[data.jenis]} · {data.rw_nama}
          </h2>
        </div>
        <button className="tombol-ikon" onClick={onTutup} aria-label="Tutup panel saluran">
          <Ikon nama="tutup" />
        </button>
      </div>

      {terbaru ? (
        <div className="kondisi">
          <Foto url={terbaru.foto_url} alt={`Foto ${JENIS[data.jenis]} ${data.rw_nama}`} />
          <div className="kondisi-info">
            <div className="baris-meta">
              <LencanaKelas kelas={terbaru.kelas} />
              {terbaru.skor_sumbatan != null && <span className="angka">{angka2(terbaru.skor_sumbatan)}</span>}
              <LabelDemo data={terbaru} />
            </div>
            <Keyakinan nilai={terbaru.keyakinan} rinci />
            {terbaru.penyebab?.length > 0 && (
              <div className="kecil">Penyebab: {terbaru.penyebab.map((p) => PENYEBAB[p] ?? p).join(', ')}</div>
            )}
            {terbaru.catatan && <p className="catatan-ai">{terbaru.catatan}</p>}
            <div className="teks-redup kecil">
              Foto {tanggalWib(terbaru.captured_at)} · {umur(terbaru.captured_at)}
            </div>
          </div>
        </div>
      ) : (
        <p className="teks-redup">Belum ada laporan.</p>
      )}

      <div className="baris-aksi">
        <span className="teks-redup kecil">Tugas:</span>
        <StatusTugasAtauTombol
          tugasAktif={tugasAktif && { ...tugasAktif, petugas_nama: tugasAktif.petugas.nama }}
          onTugaskan={() => onTugaskan({ saluran_id: data.saluran_id, jenis: data.jenis, rw_nama: data.rw_nama })}
        />
      </div>

      {tugasSelesai && (
        <>
          <h3 className="subjudul">
            <Ikon nama="cek" ukuran={15} /> Bukti pembersihan
          </h3>
          <BeforeAfter tugas={tugasSelesai} />
        </>
      )}

      <h3 className="subjudul">Riwayat laporan</h3>
      <ol className="riwayat">
        {riwayat.map((l) => (
          <li key={l.laporan_id}>
            <div className="baris-meta">
              <LencanaKelas kelas={l.kelas} />
              {l.skor_sumbatan != null && <span className="angka">{angka2(l.skor_sumbatan)}</span>}
              {l.sumber === 'verifikasi' && <span className="label-bukti">Bukti pembersihan</span>}
              <LabelDemo data={l} />
            </div>
            <div className="teks-redup kecil">
              {tanggalWib(l.captured_at)} · {STATUS_LAPORAN[l.status] ?? l.status} · Keyakinan AI {l.keyakinan}
            </div>
          </li>
        ))}
      </ol>
    </section>
  )
}
