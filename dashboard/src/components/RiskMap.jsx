import { Fragment, useEffect, useMemo, useRef } from 'react'
import { MapContainer, TileLayer, Polygon, CircleMarker, Tooltip, useMap } from 'react-leaflet'
import L from 'leaflet'
import { KELAS, WARNA_DITUGASKAN, angka2, infoLevel } from '../format'
import Legend from './Legend'

const keLatLng = (ring) => ring.map(([lng, lat]) => [lat, lng])

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
  useEffect(() => {
    if (fokus) map.flyTo(fokus.titik, Math.max(map.getZoom(), 16), { duration: 0.6 })
  }, [map, fokus])
  return null
}

function RwLayer({ rw, rwTerpilih, rwBerkedip, onPilihRw }) {
  return rw.features.map((f) => {
    const p = f.properties
    const l = infoLevel(p)
    const belumAda = p.komponen?.sumbatan?.data_cukup === false
    const pilih = p.rw_id === rwTerpilih
    const kedip = rwBerkedip.has(p.rw_id)
    return (
      <Polygon
        key={p.rw_id}
        positions={keLatLng(f.geometry.coordinates[0])}
        pathOptions={{
          color: pilih || kedip ? '#0F2A44' : l.warna,
          weight: kedip ? 5 : pilih ? 3.5 : 2,
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
      </Polygon>
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
        {p.tugas_aktif && (
          <CircleMarker
            center={[lat, lng]}
            radius={pilih ? 15 : 12}
            interactive={false}
            pathOptions={{ color: WARNA_DITUGASKAN, weight: 3, fill: false }}
          />
        )}
        <CircleMarker
          center={[lat, lng]}
          radius={pilih ? 10 : 7}
          pathOptions={{ color: pilih ? '#0F2A44' : '#ffffff', weight: pilih ? 3 : 2, fillColor: warna, fillOpacity: 1 }}
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

export default function RiskMap({ rw, saluran, rwTerpilih, saluranTerpilih, rwBerkedip, fokus, onPilihRw, onPilihSaluran }) {
  const batas = useMemo(() => {
    if (!rw?.features?.length) return null
    return L.latLngBounds(rw.features.flatMap((f) => keLatLng(f.geometry.coordinates[0])))
  }, [rw])

  return (
    <div className="peta-bungkus">
      <MapContainer center={[-6.9455, 107.6905]} zoom={15} className="peta">
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <Kamera batas={batas} fokus={fokus} />
        {rw && <RwLayer rw={rw} rwTerpilih={rwTerpilih} rwBerkedip={rwBerkedip} onPilihRw={onPilihRw} />}
        {saluran && <SaluranLayer saluran={saluran} saluranTerpilih={saluranTerpilih} onPilihSaluran={onPilihSaluran} />}
      </MapContainer>
      <Legend />
    </div>
  )
}
