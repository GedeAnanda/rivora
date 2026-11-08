import 'package:flutter/material.dart';

import '../config.dart';
import '../services/location_service.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _mulaiLapor(BuildContext context) async {
    try {
      // Minta izin lokasi sebelum kamera dibuka (lihat LocationService.ensureReady).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('RIVORA')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.water_drop,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'See the flood before you see the water.',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Foto saluran di sekitarmu. AI menilai sumbatannya, '
                'kelurahan tahu saluran mana yang perlu dibersihkan '
                'sebelum hujan.',
                style: theme.textTheme.bodyLarge,
              ),
              const Spacer(),
              _ModeInfo(theme: theme),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _mulaiLapor(context),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Lapor saluran'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menunjukkan app sedang memakai server asli atau data contoh.
class _ModeInfo extends StatelessWidget {
  const _ModeInfo({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final mock = AppConfig.useMockApi;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          mock ? Icons.science_outlined : Icons.cloud_done_outlined,
          size: 16,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            mock ? 'Mode contoh (tanpa server)' : 'Server: ${AppConfig.apiUrl}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
