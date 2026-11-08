import 'package:flutter/material.dart';

import '../services/location_service.dart';
import 'camera_screen.dart';

/// Mulai alur lapor dari mana saja: minta izin lokasi dulu (sebelum kamera
/// dibuka, lihat LocationService.ensureReady), lalu buka kamera.
Future<void> mulaiLapor(BuildContext context) async {
  try {
    await locationService.ensureReady();
  } on LocationException catch (e) {
    if (!context.mounted) return;
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
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const CameraScreen()));
}
