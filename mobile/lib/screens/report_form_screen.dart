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
import '../widgets/lokasi_mini.dart';
import '../widgets/motion.dart';
import '../widgets/pictogram.dart';
import '../widgets/step_progress.dart';
import 'camera_screen.dart';
import 'result_screen.dart';
import '../theme/rivora_icons.dart';

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
          // Layar sempit / huruf besar: ikon saja supaya judul tidak
          // terpotong.
          if (layarSempit(context))
            IconButton(
              tooltip: 'Foto ulang',
              onPressed: _sending ? null : _fotoUlang,
              icon: const Icon(RIcons.ulang),
            )
          else
            TextButton.icon(
              onPressed: _sending ? null : _fotoUlang,
              icon: const Icon(RIcons.ulang),
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
          StepProgress(langkah: _sending ? 3 : 2),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    widget.photo,
                    fit: BoxFit.cover,
                    semanticLabel: 'Foto saluran yang akan dilaporkan',
                  ),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.normal),
                    child: _sending
                        ? const ScanOverlay(
                            label: 'AI menilai tingkat sumbatan…',
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: LokasiMini(
              lat: pos.latitude,
              lng: pos.longitude,
              akurasi: pos.accuracy,
              keterangan: 'Difoto ${formatWaktu(widget.capturedAt)}',
              ringkas: true,
            ),
          ),
          const SizedBox(height: Space.xl),
          const SectionTitle('Jenis saluran'),
          // Tinggi ketiga kartu disamakan walau label ada yang dua baris.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    : const Icon(RIcons.kirim),
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

class _JenisOption extends StatelessWidget {
  const _JenisOption({
    required this.jenis,
    required this.selected,
    required this.onTap,
  });

  final JenisSaluran jenis;
  final bool selected;
  final VoidCallback? onTap;

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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                JenisPictogram(
                  jenis: jenis,
                  size: 32,
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
