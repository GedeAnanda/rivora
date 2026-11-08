import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

/// Ikon semantik RIVORA dari satu keluarga: Lucide (ISC), garis 2 px di
/// grid 24 px, ujung membulat. Pustaka ikon bawaan shadcn/ui.
/// Tab aktif memakai bobot 600 (garis lebih tebal) karena Lucide tidak
/// punya versi isi. Ganti di sini, berubah di seluruh aplikasi.
abstract final class RIcons {
  // Navigasi
  static const IconData beranda = LucideIcons.house;
  static const IconData berandaAktif = LucideIcons600.house;
  static const IconData peta = LucideIcons.map;
  static const IconData petaAktif = LucideIcons600.map;
  static const IconData laporan = LucideIcons.clipboardList;
  static const IconData laporanAktif = LucideIcons600.clipboardList;
  static const IconData tugas = LucideIcons.listChecks;
  static const IconData tugasAktif = LucideIcons600.listChecks;

  // Aksi
  static const IconData kamera = LucideIcons.camera;
  static const IconData kirim = LucideIcons.send;
  static const IconData arahkan = LucideIcons.navigation;
  static const IconData bukaPeta = LucideIcons.squareArrowOutUpRight;
  static const IconData ulang = LucideIcons.rotateCcw;
  static const IconData verifikasi = LucideIcons.badgeCheck;
  static const IconData mulai = LucideIcons.brushCleaning;
  static const IconData posisiSaya = LucideIcons.locateFixed;
  static const IconData panah = LucideIcons.arrowRight;
  static const IconData chevron = LucideIcons.chevronRight;
  static const IconData tutup = LucideIcons.x;
  static const IconData centang = LucideIcons.check;
  static const IconData bandingkan = LucideIcons.arrowLeftRight;
  static const IconData ketuk = LucideIcons.pointer;

  // Informasi
  static const IconData lokasi = LucideIcons.mapPin;
  static const IconData waktu = LucideIcons.clock;
  static const IconData jarak = LucideIcons.route;
  static const IconData hujan = LucideIcons.cloudRain;
  static const IconData catatan = LucideIcons.notebookPen;
  static const IconData ai = LucideIcons.sparkles;
  static const IconData petugas = LucideIcons.hardHat;
  static const IconData gps = LucideIcons.locateFixed;
  static const IconData gpsCari = LucideIcons.locate;
  static const IconData gpsMati = LucideIcons.locateOff;
  static const IconData notifikasi = LucideIcons.bell;

  // Faktor risiko dan cuaca (bahasa warga)
  static const IconData sampah = LucideIcons.trash2;
  static const IconData genangan = LucideIcons.wavesArrowUp; // air naik
  static const IconData tetes = LucideIcons.droplet;
  static const IconData cerah = LucideIcons.sun;
  static const IconData saran = LucideIcons.lightbulb;
  static const IconData tanya = LucideIcons.circleQuestionMark;
  static const IconData aman = LucideIcons.shieldCheck;

  // Cuaca untuk kartu hujan (ukuran besar, garis 300 supaya tidak berat)
  static const IconData cuacaCerah = LucideIcons300.sun;
  static const IconData cuacaGerimis = LucideIcons300.cloudDrizzle;
  static const IconData cuacaHujan = LucideIcons300.cloudRain;
  static const IconData cuacaLebat = LucideIcons300.cloudLightning;

  // Jenis saluran
  static const IconData saluranTerbuka = LucideIcons.waves;
  static const IconData gorongGorong = LucideIcons.cylinder;
  static const IconData inletJalan = LucideIcons.grid3x3;

  // Status
  static const IconData selesai = LucideIcons.circleCheck;
  static const IconData peringatan = LucideIcons.triangleAlert;
  static const IconData bahaya = LucideIcons.circleAlert;
  static const IconData info = LucideIcons.info;
  static const IconData tidakTerlihat = LucideIcons.eyeOff;
  static const IconData offline = LucideIcons.cloudOff;
  static const IconData kosong = LucideIcons.inbox;
  static const IconData contoh = LucideIcons.flaskConical;
  static const IconData server = LucideIcons.cloudCheck;

  // Akun
  static const IconData akun = LucideIcons.userRound;
  static const IconData keluar = LucideIcons.logOut;
  static const IconData kunci = LucideIcons.lock;
  static const IconData lihat = LucideIcons.eye;
  static const IconData sembunyi = LucideIcons.eyeOff;
}
