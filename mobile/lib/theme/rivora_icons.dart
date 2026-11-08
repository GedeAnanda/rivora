import 'package:flutter/widgets.dart';

/// Ikon semantik RIVORA. Satu keluarga: Phosphor (rekomendasi
/// ui-ux-pro-max), garis tipis seragam; versi Fill hanya untuk tab aktif.
/// Ganti di sini, berubah di seluruh aplikasi.
///
/// Font Phosphor (MIT, assets/fonts/Phosphor-LICENSE.txt) dipasang langsung
/// sebagai aset: paket phosphor_flutter 2.1.0 tidak bisa dikompilasi di
/// Flutter 3.47 karena `IconData` sekarang `final`. Kode titik diambil dari
/// paket itu; nama ikon Phosphor ditulis di komentar.
abstract final class RIcons {
  static const _regular = 'PhosphorRegular';
  static const _fill = 'PhosphorFill';

  // Navigasi
  static const beranda = IconData(0xe2c2, fontFamily: _regular); // house
  static const berandaAktif = IconData(0xe2c2, fontFamily: _fill); // house
  static const peta = IconData(0xe31a, fontFamily: _regular); // mapTrifold
  static const petaAktif = IconData(0xe31a, fontFamily: _fill); // mapTrifold
  static const laporan = IconData(
    0xe198,
    fontFamily: _regular,
  ); // clipboardText
  static const laporanAktif = IconData(
    0xe198,
    fontFamily: _fill,
  ); // clipboardText
  static const tugas = IconData(0xeadc, fontFamily: _regular); // listChecks
  static const tugasAktif = IconData(0xeadc, fontFamily: _fill); // listChecks

  // Aksi
  static const kamera = IconData(0xe10e, fontFamily: _regular); // camera
  static const kirim = IconData(0xe398, fontFamily: _regular); // paperPlaneTilt
  static const arahkan = IconData(
    0xe73a,
    fontFamily: _regular,
  ); // personSimpleWalk
  static const bukaPeta = IconData(
    0xe5de,
    fontFamily: _regular,
  ); // arrowSquareOut
  static const ulang = IconData(
    0xe038,
    fontFamily: _regular,
  ); // arrowCounterClockwise
  static const verifikasi = IconData(0xe606, fontFamily: _regular); // sealCheck
  static const mulai = IconData(0xec54, fontFamily: _regular); // broom
  static const posisiSaya = IconData(0xe1d6, fontFamily: _regular); // crosshair
  static const panah = IconData(0xe06c, fontFamily: _regular); // arrowRight
  static const chevron = IconData(0xe13a, fontFamily: _regular); // caretRight
  static const tutup = IconData(0xe4f6, fontFamily: _regular); // x
  static const centang = IconData(0xe182, fontFamily: _regular); // check
  static const bandingkan = IconData(
    0xe0a0,
    fontFamily: _regular,
  ); // arrowsLeftRight
  static const ketuk = IconData(0xec90, fontFamily: _regular); // handTap

  // Informasi
  static const lokasi = IconData(0xe316, fontFamily: _regular); // mapPin
  static const waktu = IconData(0xe19a, fontFamily: _regular); // clock
  static const jarak = IconData(
    0xeade,
    fontFamily: _regular,
  ); // navigationArrow
  static const hujan = IconData(0xe1b4, fontFamily: _regular); // cloudRain
  static const catatan = IconData(0xe34c, fontFamily: _regular); // notePencil
  static const ai = IconData(0xe6a2, fontFamily: _regular); // sparkle
  static const petugas = IconData(0xed46, fontFamily: _regular); // hardHat
  static const gps = IconData(0xedd6, fontFamily: _regular); // gpsFix
  static const gpsCari = IconData(0xedd8, fontFamily: _regular); // gps
  static const gpsMati = IconData(0xedd4, fontFamily: _regular); // gpsSlash
  static const notifikasi = IconData(0xe0ce, fontFamily: _regular); // bell

  // Status
  static const selesai = IconData(0xe184, fontFamily: _regular); // checkCircle
  static const peringatan = IconData(0xe4e0, fontFamily: _regular); // warning
  static const bahaya = IconData(0xe4e2, fontFamily: _regular); // warningCircle
  static const info = IconData(0xe2ce, fontFamily: _regular); // info
  static const tidakTerlihat = IconData(
    0xe224,
    fontFamily: _regular,
  ); // eyeSlash
  static const offline = IconData(0xe1b6, fontFamily: _regular); // cloudSlash
  static const kosong = IconData(0xe268, fontFamily: _regular); // funnelSimple
  static const contoh = IconData(0xe79e, fontFamily: _regular); // flask
  static const server = IconData(0xe1b0, fontFamily: _regular); // cloudCheck

  // Akun
  static const akun = IconData(0xe4c2, fontFamily: _regular); // user
  static const keluar = IconData(0xe42a, fontFamily: _regular); // signOut
  static const kunci = IconData(0xe2fa, fontFamily: _regular); // lock
  static const lihat = IconData(0xe220, fontFamily: _regular); // eye
  static const sembunyi = IconData(0xe224, fontFamily: _regular); // eyeSlash
}
