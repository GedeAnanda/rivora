import Foto from './Foto'
import { Keyakinan, LencanaKelas } from './Lencana'
import { angka2, tanggalWib } from '../format'

/** Foto sebelum dan sesudah berdampingan (FR-DB-12). Menerima objek tugas (SRS backend 7.9). */
export default function BeforeAfter({ tugas, ringkas }) {
  const v = tugas.verifikasi
  return (
    <div className={`sebelum-sesudah${ringkas ? ' ringkas' : ''}`}>
      <div className="dua-foto">
        <figure>
          <Foto url={tugas.foto_sebelum_url} alt="Foto sebelum dibersihkan" kecil={ringkas} />
          <figcaption>
            <strong>Sebelum</strong>
            {!ringkas && <LencanaKelas kelas={tugas.kelas_sebelum} />}
            <span className="angka">{angka2(tugas.skor_sebelum)}</span>
          </figcaption>
        </figure>
        <figure>
          <Foto url={tugas.foto_sesudah_url} alt="Foto sesudah dibersihkan" kecil={ringkas} />
          <figcaption>
            <strong>Sesudah</strong>
            {!ringkas && v && <LencanaKelas kelas={v.kelas_sesudah} />}
            <span className="angka">{angka2(v?.skor_sumbatan_sesudah)}</span>
          </figcaption>
        </figure>
      </div>
      {!ringkas && v && (
        <div className="catatan-verifikasi">
          <p>{v.catatan}</p>
          <div className="baris-meta">
            <Keyakinan nilai={v.keyakinan} />
            {tugas.selesai_at && <span>Selesai {tanggalWib(tugas.selesai_at)}</span>}
          </div>
        </div>
      )}
    </div>
  )
}
