// Cek cepat modul AI di server: node src/ai/cek-ai.js <foto.jpg>
// Menampilkan apakah env terbaca dan apakah Claude benar-benar dipanggil (sumber 'model').
try {
  require('dotenv').config()
} catch {
  console.log('dotenv tidak terpasang, env hanya dari proses')
}
const fs = require('fs')
const { analyzeReport } = require('./index')

const foto = process.argv[2]
if (!foto) {
  console.error('Pakai: node src/ai/cek-ai.js <foto.jpg>')
  process.exit(1)
}

console.log('AI_API_KEY terbaca :', process.env.AI_API_KEY ? `ya (${process.env.AI_API_KEY.slice(0, 7)}...)` : 'TIDAK')
console.log('AI_MODEL           :', process.env.AI_MODEL || '(kosong, pakai claude-opus-5-5)')
console.log('DEMO_MODE          :', process.env.DEMO_MODE || '(kosong)')
delete process.env.DEMO_MODE // supaya kegagalan tidak tertutup hasil demo

analyzeReport({ foto: fs.readFileSync(foto), mimeType: 'image/jpeg', jenisSaluran: 'terbuka' }).then((r) => {
  console.log(JSON.stringify(r, null, 2))
  console.log(r.ok && r.sumber === 'model' ? 'BERHASIL: Claude asli terpanggil' : `GAGAL: ${r.alasan ?? r.sumber}`)
})
