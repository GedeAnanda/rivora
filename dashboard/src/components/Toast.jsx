/** Notifikasi singkat di bawah layar. jenis: 'sukses' | 'peringatan' | 'galat' | 'info' */
export default function Toast({ pesan }) {
  if (!pesan) return null
  return (
    <div className={`toast toast-${pesan.jenis ?? 'info'}`} role="status" aria-live="polite">
      {pesan.teks}
    </div>
  )
}
