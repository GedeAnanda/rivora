import 'package:flutter/material.dart';

import '../models/report.dart';
import '../models/task.dart';
import '../models/verification.dart';
import '../theme/app_theme.dart';

/// Status ringan: titik berwarna + teks. Tidak berupa pil berikon, supaya
/// status tidak bersaing dengan kelas sumbatan di kartu yang sama.
class _Status extends StatelessWidget {
  const _Status({required this.label, required this.dot});

  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Status laporan: dikirim → ditugaskan → ditangani (atau cek manual).
class LaporanStatusChip extends StatelessWidget {
  const LaporanStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rv = context.rivora;
    return _Status(
      label: labelStatusLaporan[status] ?? status,
      dot: switch (status) {
        'ditangani' => rv.bersih.fg,
        'ditugaskan' => rv.waspada.fg,
        'cek_manual' => rv.tidakTerlihat.fg,
        _ => scheme.primary,
      },
    );
  }
}

class TugasStatusChip extends StatelessWidget {
  const TugasStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rv = context.rivora;
    return _Status(
      label: labelStatusTugas[status] ?? status,
      dot: switch (status) {
        'selesai' => rv.bersih.fg,
        'dikerjakan' => rv.waspada.fg,
        _ => scheme.primary,
      },
    );
  }
}

/// Level risiko RW: Aman / Waspada / Risiko tinggi (proposal 3.2).
class RisikoChip extends StatelessWidget {
  const RisikoChip({super.key, required this.level});

  final LevelRisiko level;

  @override
  Widget build(BuildContext context) {
    final c = context.rivora.risiko(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level.label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: c.fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
