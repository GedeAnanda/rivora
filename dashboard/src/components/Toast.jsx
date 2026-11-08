import Ikon from './Ikon'

/** Notifikasi singkat di bawah layar. jenis: 'sukses' | 'peringatan' | 'galat' | 'info' */
export default function Toast({ pesan }) {
  if (!pesan) return null
  const ikon = { sukses: 'cek', peringatan: 'seru', galat: 'segitiga', info: 'info' }[pesan.jenis] ?? 'info'
  return (
    <div className={`toast toast-${pesan.jenis ?? 'info'}`} role="status" aria-live="polite">
      <Ikon nama={ikon} ukuran={16} /> {pesan.teks}
    </div>
  )
}
