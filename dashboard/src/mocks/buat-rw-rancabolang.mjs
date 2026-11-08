// Membuat ulang src/mocks/rw-rancabolang.json (data contoh). Tidak dipakai saat dasbor berjalan.
// Cara pakai (di folder terpisah): npm i d3-delaunay@6 polygon-clipping@0.15, simpan batas kelurahan dari
// https://nominatim.openstreetmap.org/lookup?osm_ids=R13290131&format=geojson&polygon_geojson=1 sebagai kelurahan.json,
// lalu node buat-rw-rancabolang.mjs. Batas kelurahan: OpenStreetMap (ODbL). Pembagian RW: ilustrasi Voronoi.
import fs from 'node:fs'
import { Delaunay } from 'd3-delaunay'
import pc from 'polygon-clipping'

const kel = JSON.parse(fs.readFileSync('kelurahan.json', 'utf8')).features[0].geometry.coordinates[0] // [lng, lat]
const N = 12

function acak(seed) {
  return () => {
    seed |= 0
    seed = (seed + 0x6d2b79f5) | 0
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
const r = acak(20261108)

function dalam([x, y], poly) {
  let isi = false
  for (let i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    const [xi, yi] = poly[i]
    const [xj, yj] = poly[j]
    if (yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) isi = !isi
  }
  return isi
}

const xs = kel.map((p) => p[0])
const ys = kel.map((p) => p[1])
const [x0, x1, y0, y1] = [Math.min(...xs), Math.max(...xs), Math.min(...ys), Math.max(...ys)]

// Titik benih tersebar (jarak minimum), lalu Lloyd 2 kali supaya ukuran RW tidak terlalu timpang
let benih = []
let jarakMin = 0.0028
while (benih.length < N) {
  for (let coba = 0; coba < 5000 && benih.length < N; coba++) {
    const p = [x0 + r() * (x1 - x0), y0 + r() * (y1 - y0)]
    if (dalam(p, kel) && benih.every((q) => Math.hypot(p[0] - q[0], p[1] - q[1]) > jarakMin)) benih.push(p)
  }
  jarakMin *= 0.9
}

function sel(benih) {
  const v = Delaunay.from(benih).voronoi([x0 - 0.01, y0 - 0.01, x1 + 0.01, y1 + 0.01])
  return benih.map((_, i) => {
    const hasil = pc.intersection([v.cellPolygon(i)], [kel])
    // ambil potongan terbesar bila terpecah
    const terbesar = hasil.sort((a, b) => luas(b[0]) - luas(a[0]))[0]
    return terbesar[0]
  })
}
function luas(ring) {
  let s = 0
  for (let i = 0; i < ring.length - 1; i++) s += ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1]
  return Math.abs(s / 2)
}
function titikBerat(ring) {
  let a = 0, cx = 0, cy = 0
  for (let i = 0; i < ring.length - 1; i++) {
    const f = ring[i][0] * ring[i + 1][1] - ring[i + 1][0] * ring[i][1]
    a += f
    cx += (ring[i][0] + ring[i + 1][0]) * f
    cy += (ring[i][1] + ring[i + 1][1]) * f
  }
  return [cx / (3 * a), cy / (3 * a)]
}

let cincin = sel(benih)
for (let i = 0; i < 2; i++) {
  benih = cincin.map(titikBerat)
  cincin = sel(benih)
}

// Urutkan utara ke selatan per pita, lalu barat ke timur, supaya RW 01 di barat laut
const urut = cincin
  .map((c) => ({ c, p: titikBerat(c) }))
  .sort((a, b) => Math.round((b.p[1] - a.p[1]) / 0.003) || a.p[0] - b.p[0])

const bulat = (n) => Math.round(n * 1e6) / 1e6
const keluaran = {
  sumber: 'Batas kelurahan: OpenStreetMap relation 13290131 (ODbL). Pembagian RW: ilustrasi Voronoi, bukan batas resmi.',
  kelurahan: kel.map(([x, y]) => [bulat(x), bulat(y)]),
  rw: urut.map(({ c }) => c.map(([x, y]) => [bulat(x), bulat(y)])),
}
fs.writeFileSync('rw-rancabolang.json', JSON.stringify(keluaran))
console.log('RW:', keluaran.rw.length, 'titik per RW:', keluaran.rw.map((c) => c.length).join(','))
console.log('luas relatif:', urut.map(({ c }) => (luas(c) / luas(kel) * 100).toFixed(1)).join(' '))
