import { Fragment, useEffect, useMemo, useRef } from 'react'
import { MapContainer, TileLayer, Polygon, CircleMarker, Tooltip, useMap, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import { KELAS, WARNA_DITUGASKAN, angka2, infoLevel } from '../format'
import Legend from './Legend'

const keLatLng = (ring) => ring.map(([lng, lat]) => [lat, lng])

// Area gambar SVG selebar 1 layar di tiap sisi (bawaan 0,1), supaya poligon dan pin tidak terpotong lalu
// muncul tiba-tiba saat peta digeser. Pin punya renderer sendiri di markerPane (di atas poligon).
const rendererPoligon = L.svg({ padding: 1 })
const rendererPin = L.svg({ padding: 1, pane: 'markerPane' })

/** fitBounds hanya sekali di awal (SRS dasbor 10), lalu terbang ke target saat dipilih. */
function Kamera({ batas, fokus }) {
  const map = useMap()
  const sudah = useRef(false)
  useEffect(() => {
    if (batas && !sudah.current) {
      map.fitBounds(batas, { padding: [24, 24] })
      sudah.current = true
    }
  }, [map, batas])
  // Geser biasa, bukan flyTo: flyTo mengecil lalu membesar sehingga poligon tampak bergeser lalu melompat.
  useEffect(() => {
    if (!fokus) return
    if (map.getZoom() >= 16) map.panTo(fokus.titik, { animate: true, duration: 0.45 })
    else map.setView(fokus.titik, 16, { animate: true })
  }, [map, fokus])
  return null
}

/** Klik di area kosong peta (bukan titik atau poligon) melepas pilihan. Klik pada titik/poligon juga
 *  diteruskan Leaflet ke peta, jadi klik yang mengenai elemen interaktif diabaikan di sini. */
function KlikKosong({ onKlikKosong }) {
  useMapEvents({
    click: (e) => {
      if (!e.originalEvent.target.closest?.('.leaflet-interactive')) onKlikKosong()
    },
  })
  return null
}

/** Poligon RW. Yang dipilih atau berkedip dibawa ke depan supaya garis tepinya tidak tertimpa RW tetangga. */
function RwPoligon({ diDepan, ...props }) {
  const ref = useRef(null)
  useEffect(() => {
    if (diDepan) ref.current?.bringToFront()
  }, [diDepan])
  return <Polygon ref={ref} {...props} />
}

function RwLayer({ rw, rwTerpilih, rwBerkedip, onPilihRw }) {
  return rw.features.map((f) => {
    const p = f.properties
    const l = infoLevel(p)
    const belumAda = p.komponen?.sumbatan?.data_cukup === false
    const pilih = p.rw_id === rwTerpilih
    const kedip = rwBerkedip.has(p.rw_id)
    return (
      <RwPoligon
        key={p.rw_id}
        diDepan={pilih || kedip}
        positions={keLatLng(f.geometry.coordinates[0])}
        pathOptions={{
          color: pilih || kedip ? '#04214B' : l.warna,
          weight: kedip ? 5 : pilih ? 3.5 : 1.6,
          dashArray: belumAda ? '6 5' : undefined,
          fillColor: l.warna,
          fillOpacity: l.isi + (pilih ? 0.12 : 0),
        }}
        eventHandlers={{ click: () => onPilihRw(p.rw_id) }}
      >
        <Tooltip sticky>
          {p.nama} · {l.label}
          {!belumAda && ` · ${angka2(p.skor)}`}
        </Tooltip>
      </RwPoligon>
    )
  })
}

function SaluranLayer({ saluran, saluranTerpilih, onPilihSaluran }) {
  return saluran.features.map((f) => {
    const p = f.properties
    const [lng, lat] = f.geometry.coordinates
    const kelas = p.perlu_cek_manual || !p.kondisi ? 'tidak_terlihat' : p.kondisi.kelas
    const warna = KELAS[kelas].warna
    const pilih = p.saluran_id === saluranTerpilih
    return (
      <Fragment key={p.saluran_id}>
        {/* Bayangan tipis: titik terangkat dari warna wilayah di bawahnya */}
        <CircleMarker
          renderer={rendererPin}
          center={[lat, lng]}
          radius={pilih ? 15 : 11}
          interactive={false}
          pathOptions={{ stroke: false, fillColor: '#04214B', fillOpacity: pilih ? 0.22 : 0.16 }}
        />
        {p.tugas_aktif && (
          <CircleMarker
            renderer={rendererPin}
            center={[lat, lng]}
            radius={pilih ? 17 : 14}
            interactive={false}
            pathOptions={{ color: WARNA_DITUGASKAN, weight: 3, fill: false }}
          />
        )}
        <CircleMarker
          renderer={rendererPin}
          center={[lat, lng]}
          radius={pilih ? 11 : 8}
          pathOptions={{ color: pilih ? '#04214B' : '#ffffff', weight: pilih ? 3.5 : 2.5, fillColor: warna, fillOpacity: 1 }}
          eventHandlers={{ click: () => onPilihSaluran(p.saluran_id, [lat, lng]) }}
        >
          <Tooltip direction="top" offset={[0, -6]}>
            {p.rw_nama} · {p.perlu_cek_manual ? 'Perlu cek manual' : KELAS[kelas].label}
            {p.tugas_aktif && ` · ditugaskan ke ${p.tugas_aktif.petugas_nama}`}
          </Tooltip>
        </CircleMarker>
      </Fragment>
    )
  })
}

export default function RiskMap({ rw, saluran, rwTerpilih, saluranTerpilih, rwBerkedip, fokus, onPilihRw, onPilihSaluran, onKlikKosong }) {
  const batas = useMemo(() => {
    if (!rw?.features?.length) return null
    return L.latLngBounds(rw.features.flatMap((f) => keLatLng(f.geometry.coordinates[0])))
  }, [rw])

  return (
    <div className="peta-bungkus">
      <MapContainer center={[-6.965, 107.695]} zoom={15} className="peta" renderer={rendererPoligon}>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <Kamera batas={batas} fokus={fokus} />
        <KlikKosong onKlikKosong={onKlikKosong} />
        {rw && <RwLayer rw={rw} rwTerpilih={rwTerpilih} rwBerkedip={rwBerkedip} onPilihRw={onPilihRw} />}
        {saluran && <SaluranLayer saluran={saluran} saluranTerpilih={saluranTerpilih} onPilihSaluran={onPilihSaluran} />}
      </MapContainer>
      <Legend />
    </div>
  )
}
