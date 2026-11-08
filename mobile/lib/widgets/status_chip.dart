import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/task.dart';
import '../models/verification.dart';
import '../theme/app_theme.dart';

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: Space.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Status laporan warga/petugas: dikirim → ditugaskan → ditangani.
class LaporanStatusChip extends StatelessWidget {
  const LaporanStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rv = context.rivora;
    final label = labelStatusLaporan[status] ?? status;
    return switch (status) {
      'ditangani' => _Chip(
        icon: Icons.task_alt_rounded,
        label: label,
        fg: rv.bersih.fg,
        bg: rv.bersih.bg,
      ),
      'ditugaskan' => _Chip(
        icon: Icons.engineering_rounded,
        label: label,
        fg: scheme.onSurface,
        bg: scheme.surfaceContainerHighest,
      ),
      'cek_manual' => _Chip(
        icon: Icons.visibility_off_rounded,
        label: label,
        fg: rv.tidakTerlihat.fg,
        bg: rv.tidakTerlihat.bg,
      ),
      _ => _Chip(
        icon: Icons.send_rounded,
        label: label,
        fg: scheme.onPrimaryContainer,
        bg: scheme.primaryContainer,
      ),
    };
  }
}

class TugasStatusChip extends StatelessWidget {
  const TugasStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rv = context.rivora;
    final label = labelStatusTugas[status] ?? status;
    return switch (status) {
      'selesai' => _Chip(
        icon: Icons.task_alt_rounded,
        label: label,
        fg: rv.bersih.fg,
        bg: rv.bersih.bg,
      ),
      'dikerjakan' => _Chip(
        icon: Icons.cleaning_services_rounded,
        label: label,
        fg: scheme.onSurface,
        bg: scheme.surfaceContainerHighest,
      ),
      _ => _Chip(
        icon: Icons.schedule_rounded,
        label: label,
        fg: scheme.onPrimaryContainer,
        bg: scheme.primaryContainer,
      ),
    };
  }
}

/// Level risiko RW: Aman / Waspada / Risiko tinggi (proposal 3.2).
class RisikoChip extends StatelessWidget {
  const RisikoChip({super.key, required this.level});

  final LevelRisiko level;

  @override
  Widget build(BuildContext context) {
    final c = context.rivora.risiko(level);
    return _Chip(
      icon: switch (level) {
        LevelRisiko.aman => Icons.shield_outlined,
        LevelRisiko.waspada => Icons.warning_amber_rounded,
        LevelRisiko.risikoTinggi => Icons.flood_outlined,
      },
      label: level.label,
      fg: c.fg,
      bg: c.bg,
    );
  }
}
