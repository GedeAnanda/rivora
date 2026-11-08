// Ikon garis sederhana (stroke = currentColor). Status selalu ikon + teks, tidak hanya warna.
const JALUR = {
  cek: <path d="M5 12.5l4.5 4.5L19 7.5" />,
  seru: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.5v5.5M12 16.5v.01" />
    </>
  ),
  segitiga: (
    <>
      <path d="M12 3.5L21.5 20h-19z" />
      <path d="M12 10v4.5M12 17.5v.01" />
    </>
  ),
  tanya: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M9.6 9.3a2.5 2.5 0 1 1 3.4 2.4c-.6.3-1 .8-1 1.5v.3M12 16.8v.01" />
    </>
  ),
  hujan: (
    <>
      <path d="M7 15a4.5 4.5 0 1 1 1.2-8.8A5.5 5.5 0 0 1 18.5 9 3.5 3.5 0 0 1 17.5 15z" />
      <path d="M8 18l-1 2.5M12 18l-1 2.5M16 18l-1 2.5" />
    </>
  ),
  tutup: <path d="M6 6l12 12M18 6L6 18" />,
  orang: (
    <>
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 20c.8-3.6 3.6-5.5 7-5.5s6.2 1.9 7 5.5" />
    </>
  ),
  kamera: (
    <>
      <path d="M4 8h3.5L9 5.5h6L16.5 8H20v11H4z" />
      <circle cx="12" cy="13.5" r="3.5" />
    </>
  ),
  mata_tutup: (
    <>
      <path d="M3 12s3.5-6 9-6c1.6 0 3 .5 4.2 1.2M21 12s-3.5 6-9 6c-1.6 0-3-.5-4.2-1.2" />
      <path d="M4 20L20 4" />
    </>
  ),
  air: <path d="M12 3.5s-6 6.6-6 10.7a6 6 0 0 0 12 0C18 10.1 12 3.5 12 3.5z" />,
  info: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v5.5M12 7.5v.01" />
    </>
  ),
  ulang: (
    <>
      <path d="M4.5 12a7.5 7.5 0 1 0 2.2-5.3" />
      <path d="M4.5 4v4h4" />
    </>
  ),
  keluar: (
    <>
      <path d="M14 5h4.5v14H14" />
      <path d="M10 8l-4 4 4 4M6 12h9" />
    </>
  ),
  panah: <path d="M9 6l6 6-6 6" />,
  awan_putus: (
    <>
      <path d="M7 17a4.5 4.5 0 1 1 1.2-8.8A5.5 5.5 0 0 1 18.5 11 3.5 3.5 0 0 1 17.5 17z" />
      <path d="M4 4l16 16" />
    </>
  ),
}

export default function Ikon({ nama, ukuran = 16, className, label }) {
  return (
    <svg
      width={ukuran}
      height={ukuran}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      {JALUR[nama]}
    </svg>
  )
}
