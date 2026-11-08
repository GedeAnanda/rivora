import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Indikator langkah alur lapor: Foto → Jenis saluran → Kirim.
/// Pola "step-based report flow" dari referensi app laporan warga
/// (mis. Gobojongsoang.id, 311 Calgary) supaya pelapor tahu sisa langkahnya.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.langkah,
    this.diAtasGelap = false,
  });

  /// 1-based.
  final int langkah;

  /// `true` di atas kamera (latar gelap).
  final bool diAtasGelap;

  static const label = ['Foto', 'Jenis saluran', 'Kirim'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aktif = diAtasGelap ? Colors.white : theme.colorScheme.primary;
    final pasif = diAtasGelap
        ? Colors.white.withValues(alpha: 0.3)
        : theme.colorScheme.outlineVariant;
    final teks = diAtasGelap
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      label: 'Langkah $langkah dari ${label.length}: ${label[langkah - 1]}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Langkah $langkah dari ${label.length} · ${label[langkah - 1]}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: teks,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Space.xs + 2),
          Row(
            children: [
              for (var i = 1; i <= label.length; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.normal),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= langkah ? aktif : pasif,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (i < label.length) const SizedBox(width: Space.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
