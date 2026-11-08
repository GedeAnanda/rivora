import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';
import 'camera_screen.dart';

const _kunciIzin = 'rivora.izin_dijelaskan';

/// Penjelasan singkat sebelum dialog izin sistem (mobile SRS NFR-04).
/// Ditampilkan sekali; `false` kalau pengguna menutupnya.
Future<bool> _jelaskanIzin(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kunciIzin) ?? false) return true;
  if (!context.mounted) return false;
  final lanjut = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      Widget alasan(IconData ikon, String judul, String isi) => Padding(
        padding: const EdgeInsets.only(bottom: Space.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, color: theme.colorScheme.primary),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isi,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sebelum memotret', style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.lg),
              alasan(
                RIcons.kamera,
                'Kamera',
                'Foto diambil langsung dari kamera, bukan galeri, supaya laporan '
                    'bisa dipercaya.',
              ),
              alasan(
                RIcons.lokasi,
                'Lokasi',
                'Titik GPS dicatat otomatis agar kelurahan tahu saluran mana yang '
                    'perlu dibersihkan.',
              ),
              FilledButton(
                onPressed: () => Navigator.of(sheet).pop(true),
                child: const Text('Lanjut'),
              ),
            ],
          ),
        ),
      );
    },
  );
  if (lanjut ?? false) {
    await prefs.setBool(_kunciIzin, true);
    return true;
  }
  return false;
}

/// Minta izin lokasi dulu (sebelum kamera dibuka, lihat
/// LocationService.ensureReady). `false` kalau belum bisa lanjut.
Future<bool> _siapkanLokasi(BuildContext context) async {
  if (!await _jelaskanIzin(context) || !context.mounted) return false;
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
