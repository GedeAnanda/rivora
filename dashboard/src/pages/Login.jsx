import { useState } from 'react'
import Ikon from '../components/Ikon'
import { api, token, USE_MOCK } from '../api/client'

/** Login lurah (FR-DB-01). Hanya role lurah yang boleh masuk. */
export default function Login({ onMasuk }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [kirim, setKirim] = useState(false)
  const [galat, setGalat] = useState(null)

  async function masuk(e) {
    e.preventDefault()
    setKirim(true)
    setGalat(null)
    try {
      const res = await api.login({ username: username.trim(), password })
      if (res.role !== 'lurah') {
        setGalat('Akun ini bukan akun kelurahan')
        setKirim(false)
        return
      }
      token.simpan(res.token)
      onMasuk(res.pengguna)
    } catch (err) {
      setGalat(err.status === 401 ? 'Username atau password salah' : err.message)
      setKirim(false)
    }
  }

  return (
    <div className="halaman-login">
      <form className="kartu-login" onSubmit={masuk}>
        <div className="merek merek-gelap">
          <span className="logo" aria-hidden="true">
            <Ikon nama="air" ukuran={20} />
          </span>
          <div>
            <div className="nama-produk">RIVORA</div>
            <div className="tagline">See The Flood Before You See The Water.</div>
          </div>
        </div>
        <h1>Masuk dasbor kelurahan</h1>

        <label className="label-isian">
          <span>Username</span>
          <input autoComplete="username" value={username} onChange={(e) => setUsername(e.target.value)} required autoFocus />
        </label>
        <label className="label-isian">
          <span>Password</span>
          <input
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </label>

        {galat && <p className="galat">{galat}</p>}

        <button className="tombol tombol-penuh" disabled={kirim}>
          {kirim ? 'Memeriksa...' : 'Masuk'}
        </button>

        {USE_MOCK && (
          <p className="catatan-kecil">
            <Ikon nama="info" ukuran={14} />
            <span>
              Mode data contoh: masuk dengan username <strong>lurah</strong> dan password apa saja.
            </span>
          </p>
        )}
      </form>
    </div>
  )
}
