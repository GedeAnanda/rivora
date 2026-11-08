import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../models/jenis_saluran.dart';
import '../services/api_client.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'camera_screen.dart';
import 'result_screen.dart';

/// Konfirmasi laporan: foto, lokasi & waktu otomatis, pilih jenis saluran.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.photo,
    required this.position,
    required this.capturedAt,
  });

  final File photo;
  final Position position;
  final DateTime capturedAt;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  JenisSaluran? _jenis;
  bool _sending = false;

  Future<void> _kirim() async {
    final jenis = _jenis;
    if (jenis == null || _sending) return;
    setState(() => _sending = true);
    try {
      final report = await api.submitReport(
        foto: widget.photo,
        lat: widget.position.latitude,
        lng: widget.position.longitude,
        capturedAt: widget.capturedAt,
        jenisSaluran: jenis,
      );
      reportRepository.addSubmitted(report, widget.photo);
      HapticFeedback.lightImpact();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(report: report, photo: widget.photo),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _fotoUlang() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pos = widget.position;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kirim laporan'),
        actions: [
          TextButton.icon(
            onPressed: _sending ? null : _fotoUlang,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Foto ulang'),
          ),
          const SizedBox(width: Space.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xl,
        ),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(
                widget.photo,
                fit: BoxFit.cover,
                semanticLabel: 'Foto saluran yang akan dilaporkan',
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.md,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Column(
              children: [
                _Meta(
                  icon: Icons.place_outlined,
                  text: formatKoordinat(pos.latitude, pos.longitude),
                  trailing: '±${pos.accuracy.round()} m',
                ),
                const SizedBox(height: Space.sm),
                _Meta(
                  icon: Icons.schedule_rounded,
                  text: formatWaktu(widget.capturedAt),
                  trailing: 'otomatis',
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          const SectionTitle('Jenis saluran'),
          Row(
            children: [
              for (final jenis in JenisSaluran.values) ...[
                Expanded(
                  child: _JenisOption(
                    jenis: jenis,
                    selected: _jenis == jenis,
                    onTap: _sending
                        ? null
                        : () => setState(() => _jenis = jenis),
                  ),
                ),
                if (jenis != JenisSaluran.values.last)
                  const SizedBox(width: Space.sm),
              ],
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.lg,
            Space.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_jenis == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Text(
                    'Pilih jenis saluran untuk mengirim.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _jenis == null || _sending ? null : _kirim,
                icon: _sending
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending ? 'AI sedang menganalisis…' : 'Kirim laporan',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.trailing});

  final IconData icon;
  final String text;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 20, color: muted),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        Text(
          trailing,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _JenisOption extends StatelessWidget {
  const _JenisOption({
    required this.jenis,
    required this.selected,
    required this.onTap,
  });

  final JenisSaluran jenis;
  final bool selected;
  final VoidCallback? onTap;

  IconData get _icon => switch (jenis) {
    JenisSaluran.terbuka => Icons.water_rounded,
    JenisSaluran.gorongGorong => Icons.panorama_fish_eye_rounded,
    JenisSaluran.inletJalan => Icons.grid_4x4_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: jenis.label,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: Space.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icon,
                  size: 28,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: Space.sm),
                Text(
                  jenis.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
