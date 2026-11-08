import { useEffect, useState } from 'react'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import { pasangPenanganan401, token } from './api/client'

/** Cek token -> Login atau Dashboard (SRS dasbor bagian 10). */
export default function App() {
  const [masuk, setMasuk] = useState(() => !!token.ambil())

  useEffect(() => {
    // Respons 401 di mana pun -> token dihapus client, kembali ke login (FR-DB-01)
    pasangPenanganan401(() => setMasuk(false))
  }, [])

  if (!masuk) return <Login onMasuk={() => setMasuk(true)} />
  return (
    <Dashboard
      onKeluar={() => {
        token.hapus()
        setMasuk(false)
      }}
    />
  )
}
