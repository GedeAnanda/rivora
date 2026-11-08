import Ikon from './Ikon'
import { LencanaKelas, LencanaLevel } from './Lencana'
import { JENIS, angka2, bobot, infoLevel, mm } from '../format'

const lokasi = (e) => (e >= 0.67 ? 'lokasi rendah' : e >= 0.34 ? 'lokasi sedang' : 'lokasi relatif tinggi')

/**
 * Panel "Kenapa skor ini?" (FR-DB-06). Angka diambil apa adanya dari properties.komponen
 * dan properties.alasan. Dasbor tidak menghitung ulang skor.
 */
export default function RwDetail({ props, saluran, onPilihSaluran, onTutup }) {
  const k = props.komponen
  const belumAda = k.sumbatan.data_cukup === false
  const l = infoLevel(props)

  const baris = [
    {
      nama: 'Hujan',
      c: k.hujan,
      ket: `${mm(k.hujan.mm)} / 24 jam`,
    },
    {
      nama: 'Sumbatan',
      c: k.sumbatan,
      ket: belumAda
        ? 'belum ada laporan saluran'
        : `${k.sumbatan.jumlah_saluran} saluran, ${k.sumbatan.jumlah_cek_manual} perlu cek manual`,
    },
    {
      nama: 'Kerentanan',
      c: k.kerentanan,
      ket: [
        k.kerentanan.elevasi_relatif != null && lokasi(k.kerentanan.elevasi_relatif),
        k.kerentanan.jarak_genangan_m != null &&
          `${k.kerentanan.jarak_genangan_m} m dari ${k.kerentanan.genangan_terdekat ?? 'titik genangan'}`,
      ]
        .filter(Boolean)
        .join(', '),
    },
  ]

  const salRw = saluran?.features.filter((f) => f.properties.rw_id === props.rw_id) ?? []

  return (
    <section className="panel-detail" style={{ '--w': l.warna }}>
      <div className="detail-kepala">
        <div>
          <div className="teks-redup kecil">Kenapa skor ini?</div>
          <h2>
            {props.nama} · <span className="angka">{belumAda ? '-' : angka2(props.skor)}</span>
          </h2>
        </div>
        <LencanaLevel props={props} />
        <button className="tombol-ikon" onClick={onTutup} aria-label="Tutup panel RW">
          <Ikon nama="tutup" />
        </button>
      </div>

      <div className="rincian">
        {baris.map(({ nama, c, ket }) => (
          <div key={nama} className="rincian-baris">
            <span className="rincian-nama">{nama}</span>
            <div className="meter" aria-hidden="true">
              <div className="meter-isi" style={{ width: `${Math.round((c.nilai ?? 0) * 100)}%` }} />
            </div>
            <span className="angka rincian-rumus">
              {angka2(c.nilai)} × {bobot(c.bobot)} = {angka2(c.kontribusi)}
            </span>
            <span className="rincian-ket teks-redup">{ket}</span>
          </div>
        ))}
      </div>

      {props.alasan && <blockquote className="alasan">{props.alasan}</blockquote>}

      <h3 className="subjudul">Saluran di {props.nama}</h3>
      {salRw.length === 0 && <p className="teks-redup kecil">Belum ada saluran yang dilaporkan di RW ini.</p>}
      <ul className="daftar-mini">
        {salRw.map((f) => {
          const p = f.properties
          const kelas = p.perlu_cek_manual || !p.kondisi ? 'tidak_terlihat' : p.kondisi.kelas
          return (
            <li key={p.saluran_id}>
              <button
                className="tautan-baris"
                onClick={() => onPilihSaluran(p.saluran_id, [f.geometry.coordinates[1], f.geometry.coordinates[0]])}
              >
                <span>{JENIS[p.jenis]}</span>
                {p.perlu_cek_manual ? <span className="teks-redup">Perlu cek manual</span> : <LencanaKelas kelas={kelas} />}
                <span className="teks-redup angka">{p.kondisi ? angka2(p.kondisi.skor_sumbatan) : ''}</span>
                <Ikon nama="panah" ukuran={14} />
              </button>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
