import { useCallback, useEffect, useRef, useState } from 'react'

/**
 * Memuat data lewat `muat()` saat awal, lalu tiap `jeda` ms (FR-DB-13).
 * Bila gagal, data terakhir tetap dipakai dan `galat` + `terakhirOk` diisi untuk banner.
 */
export function usePolling(muat, jeda) {
  const [data, setData] = useState(null)
  const [galat, setGalat] = useState(null)
  const [terakhirOk, setTerakhirOk] = useState(null)
  const muatRef = useRef(muat)
  useEffect(() => {
    muatRef.current = muat
  }, [muat])

  const muatUlang = useCallback(async () => {
    try {
      const hasil = await muatRef.current()
      setData(hasil)
      setGalat(null)
      setTerakhirOk(new Date().toISOString())
    } catch (e) {
      setGalat(e)
    }
  }, [])

  useEffect(() => {
    let aktif = true
    const jalan = () => aktif && muatUlang()
    jalan()
    const t = setInterval(jalan, jeda)
    return () => {
      aktif = false
      clearInterval(t)
    }
  }, [muatUlang, jeda])

  return { data, galat, terakhirOk, muatUlang }
}
