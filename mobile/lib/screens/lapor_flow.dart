import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/location_service.dart';
import 'camera_screen.dart';

/// Minta izin lokasi dulu (sebelum kamera dibuka, lihat
/// LocationService.ensureReady). `false` kalau belum bisa lanjut.
Future<bool> _siapkanLokasi(BuildContext context) async {
  try {
    await locationService.ensureReady();
    return true;
  } on LocationException catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        action: e.fix == LocationFix.none
            ? null
            : SnackBarAction(
                label: 'Pengaturan',
                onPressed: () => locationService.openFix(e.fix),
              ),
      ),
    );
    return false;
  }
}

/// Mulai alur lapor dari mana saja.
Future<void> mulaiLapor(BuildContext context) async {
  if (!await _siapkanLokasi(context) || !context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const CameraScreen()));
}

/// Mulai foto sesudah dibersihkan untuk [tugas] (proposal 3.2 langkah 4).
/// `ganti: true` mengganti layar sekarang (dipakai tombol "Foto ulang").
Future<void> mulaiVerifikasi(
  BuildContext context,
  Task tugas, {
  bool ganti = false,
}) async {
  if (!await _siapkanLokasi(context) || !context.mounted) return;
  final route = MaterialPageRoute<void>(
    builder: (_) => CameraScreen(tugas: tugas),
  );
  final nav = Navigator.of(context);
  ganti ? await nav.pushReplacement(route) : await nav.push(route);
}
