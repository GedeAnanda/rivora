import { useRef, useState } from 'react'
import Ikon from '../components/Ikon'
import { api, token, USE_MOCK } from '../api/client'

// Foto dari Wikimedia Commons (CC BY-SA), kredit wajib tampil: lihat KREDIT_FOTO di kaki halaman.
const FITUR = [
  { foto: '/login/kartu-1.jpg', teks: <>Petugas dan warga <b>memotret saluran</b>, AI menilai sumbatannya.</> },
  { foto: '/login/kartu-2.jpg', teks: <>Daftar saluran yang <b>perlu dibersihkan</b> sebelum hujan turun.</> },
  { foto: '/login/kartu-3.jpg', teks: <><b>Bukti foto</b> sebelum dan sesudah pembersihan.</> },
]

const KREDIT_FOTO = [
  ['Galeri ega', 'Gotong_Royong_Membersihkan_Sungai.jpg', 'CC BY-SA 4.0'],
  ['DayakSibiriak', 'Waste_in_rain_gutter_near_school_Bali.jpg', 'CC BY-SA 4.0'],
  ['Komarudin0412', 'Cuaca_hukan_sore_hari_jalan_baru_babakan_raden_2014-01-18_17-49.jpg', 'CC BY-SA 3.0'],
  ['Macdanpets', 'Man_cleaning_drainage_in_Agbara,_Lagos_Badagry_Expressway.jpg', 'CC BY-SA 4.0'],
]

/** Login lurah (FR-DB-01). Hanya role lurah yang boleh masuk. */
export default function Login({ onMasuk }) {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [lihat, setLihat] = useState(false)
  const [kirim, setKirim] = useState(false)
  const [galat, setGalat] = useState(null)
  const inputPertama = useRef(null)

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
      <section className="hero">
        <div className="hero-foto" aria-hidden="true" />
        <header className="login-nav">
          <img className="logo-login" src="/brand/rivora-logo-putih.svg" alt="RIVORA" />
        </header>

        <div className="hero-isi">
          <div className="hero-teks">
            <h1>Lihat Genangan Sebelum Airnya Datang.</h1>
            <p>
              Masuk untuk melihat saluran mana yang perlu dibersihkan lebih dulu sebelum hujan turun di kelurahan Anda.
            </p>
          </div>

          <div className="hero-form">
            <form className="kartu-login" onSubmit={masuk}>
              <h2>Masuk dasbor kelurahan</h2>

              <label className="isian-label" htmlFor="login-username">Username</label>
              <input id="login-username" ref={inputPertama} className="isian" autoComplete="username"
                value={username} onChange={(e) => setUsername(e.target.value)} required autoFocus />

              <label className="isian-label" htmlFor="login-password">Password</label>
              <div className="isian-bungkus">
                <input id="login-password" className="isian" type={lihat ? 'text' : 'password'} autoComplete="current-password"
                  value={password} onChange={(e) => setPassword(e.target.value)} required />
                <button type="button" className="tombol-ikon isian-mata" onClick={() => setLihat((x) => !x)}
                  aria-label={lihat ? 'Sembunyikan password' : 'Tampilkan password'}>
                  <Ikon nama={lihat ? 'mata_tutup' : 'mata'} ukuran={20} />
                </button>
              </div>

              {galat && <p className="galat" role="alert">{galat}</p>}

              <button className="tombol tombol-pill" disabled={kirim}>
                {kirim ? 'Memeriksa...' : 'Masuk'}
              </button>

              <p className="login-kecil">Khusus akun lurah atau koordinator lapangan kelurahan.</p>
              {USE_MOCK && (
                <p className="login-kecil">
                  Mode data contoh: username <strong>lurah</strong>, password apa saja.
                </p>
              )}
            </form>
            <p className="kartu-login kedua">Petugas atau warga? Pakai aplikasi RIVORA di Android.</p>
          </div>
        </div>

        <a className="hero-kredit" href="https://commons.wikimedia.org/wiki/File:Gotong_Royong_Membersihkan_Sungai.jpg" target="_blank" rel="noreferrer">
          Foto: Galeri ega, Wikimedia Commons, CC BY-SA 4.0
        </a>
      </section>

      <section className="fitur">
        {FITUR.map((f, i) => (
          <div key={i} className="fitur-kartu" style={{ '--foto': `url(${f.foto})` }}>
            <img className="fitur-foto" src={f.foto} alt="" loading="lazy" />
            <p>{f.teks}</p>
          </div>
        ))}
      </section>

      <section className="login-ajak">
        <h2>Saluran lancar, genangan berkurang.</h2>
        <button className="tombol tombol-pill" onClick={() => inputPertama.current?.focus()}>
          Masuk ke dasbor
        </button>
      </section>

      <footer className="login-kaki">
        <div className="kaki-dalam">
          <div className="kaki-kolom">
            <h3>RIVORA</h3>
            <span>Sistem prediksi dan pencegahan genangan berbasis kondisi saluran drainase</span>
          </div>
          <div className="kaki-kolom">
            <h3>Produk</h3>
            <span>Dasbor kelurahan</span>
            <span>Aplikasi pelapor (Android)</span>
          </div>
          <div className="kaki-kolom">
            <h3>Sumber data</h3>
            <span>Open-Meteo dan BMKG</span>
            <span>OpenStreetMap</span>
            <span>DEMNAS (BIG)</span>
          </div>
          <div className="kaki-kolom">
            <h3>Tim Abis Ini ke WDP</h3>
            <span>I Gede Ananda Bela Persada</span>
            <span>Fatih Akram Wicaksono</span>
            <span>Wildan Panji Maulana</span>
          </div>
        </div>
        <div className="kaki-bawah">© RIVORA 2026 · Telkom University · CR YOUTH 2026 Hackathon</div>
        <div className="kaki-kredit">
          Foto dari Wikimedia Commons:{' '}
          {KREDIT_FOTO.map(([nama, file, lisensi], i) => (
            <span key={file}>
              {i > 0 && ' · '}
              <a href={`https://commons.wikimedia.org/wiki/File:${file}`} target="_blank" rel="noreferrer">
                {nama}
              </a>{' '}
              ({lisensi})
            </span>
          ))}
        </div>
      </footer>
    </div>
  )
}
