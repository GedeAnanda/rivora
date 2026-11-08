import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

enum LocationFix { none, appSettings, locationSettings }

class LocationException implements Exception {
  const LocationException(this.message, {this.fix = LocationFix.none});

  final String message;

  /// Pengaturan yang perlu dibuka pengguna untuk memperbaiki masalahnya.
  final LocationFix fix;

  @override
  String toString() => message;
}

/// GPS untuk laporan. Lokasi diambil otomatis saat memotret (proposal 3.2),
/// pengguna tidak bisa mengetik koordinat sendiri.
class LocationService {
  /// Posisi cadangan (posisi terakhir yang diketahui) hanya dipakai kalau
  /// masih segar dan cukup akurat. Posisi lama bisa menempelkan laporan ke
  /// saluran lain, dan membuat cek radius verifikasi 30 m tidak bermakna.
  static const umurMaks = Duration(minutes: 2);
  static const akurasiMaksMeter = 50.0;

  /// `true` kalau [p] boleh dipakai sebagai lokasi foto.
  static bool layak(Position p, {DateTime? sekarang}) {
    final umur = (sekarang ?? DateTime.now()).difference(p.timestamp);
    return umur <= umurMaks && p.accuracy <= akurasiMaksMeter;
  }

  /// Pastikan GPS menyala dan izin lokasi diberikan.
  /// Dipanggil sebelum membuka kamera supaya dialog izin tidak
  /// mengganggu kamera yang sedang aktif.
  Future<void> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'GPS mati. Nyalakan lokasi di HP dulu.',
        fix: LocationFix.locationSettings,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Izin lokasi dibutuhkan supaya laporan tercatat di titik yang benar.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Izin lokasi ditolak permanen. Izinkan lewat pengaturan aplikasi.',
        fix: LocationFix.appSettings,
      );
    }
  }

  Future<Position> currentPosition() async {
    await ensureReady();
    try {
      return await Geolocator.getCurrentPosition(locationSettings: _settings);
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: Platform.isAndroid,
      );
      if (last != null && layak(last)) return last;
      throw const LocationException(
        'Lokasi belum didapat. Coba pindah ke tempat lebih terbuka.',
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'GPS mati. Nyalakan lokasi di HP dulu.',
        fix: LocationFix.locationSettings,
      );
    } on PermissionDeniedException {
      throw const LocationException(
        'Izin lokasi dibutuhkan supaya laporan tercatat di titik yang benar.',
        fix: LocationFix.appSettings,
      );
    } on Exception {
      throw const LocationException('Lokasi gagal dibaca. Coba foto ulang.');
    }
  }

  /// Di Android memakai LocationManager (GPS) langsung, bukan Google Play
  /// Services. Tanpa ini, setiap pengambilan posisi bisa memunculkan dialog
  /// "Location Accuracy" dari Google, dan kalau ditolak posisinya gagal.
  static LocationSettings get _settings => Platform.isAndroid
      ? AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
          forceLocationManager: true,
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );

  /// Posisi terakhir yang diketahui, tanpa menunggu GPS dan tanpa dialog
  /// izin. Dipakai untuk menampilkan jarak ke lokasi tugas.
  Future<Position?> lastKnown() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    try {
      return await Geolocator.getLastKnownPosition(
        forceAndroidLocationManager: Platform.isAndroid,
      );
    } on Exception {
      return null;
    }
  }

  Future<void> openFix(LocationFix fix) async {
    switch (fix) {
      case LocationFix.appSettings:
        await Geolocator.openAppSettings();
      case LocationFix.locationSettings:
        await Geolocator.openLocationSettings();
      case LocationFix.none:
        break;
    }
  }
}

final locationService = LocationService();
