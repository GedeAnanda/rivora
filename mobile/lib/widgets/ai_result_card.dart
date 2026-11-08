import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'motion.dart';
import 'sumbatan_style.dart';

/// Ringkasan hasil analisis AI (Lampiran C): kelas, skor, penyebab,
/// keyakinan (selalu tampil, Tabel 8), dan catatan.
class AiResultCard extends StatelessWidget {
  const AiResultCard({super.key, required this.ai});

  final AiResult ai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warna = context.rivora.sumbatan(ai.kelas);
    final skor = ai.skorSumbatan;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Analisis AI',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _Keyakinan(keyakinan: ai.keyakinan),
              ],
            ),
            const SizedBox(height: Space.md),
            SumbatanBadge(kelas: ai.kelas),
            if (skor != null) ...[
              const SizedBox(height: Space.lg),
              Semantics(
                label: 'Skor sumbatan ${formatDesimal(skor)} dari 1',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedScore(
                          value: skor,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            height: 1,
                          ),
                          color: warna.fg,
                        ),
                        const SizedBox(width: Space.sm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'skor sumbatan (0–1)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    AnimatedBar(
                      value: skor,
                      color: warna.fg,
                      background: warna.bg,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Space.lg),
            const Divider(),
            const SizedBox(height: Space.md),
            Text(
              'Penyebab',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),
            if (ai.penyebab.isEmpty)
              Text(
                'Tidak ada penyebab dominan',
                style: theme.textTheme.bodyMedium,
              )
            else
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final p in ai.penyebab)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.xs + 2,
                      ),
                      // Tag datar tanpa garis: bukan tombol, tidak bisa
                      // diketuk.
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        color: scheme.surfaceContainerHigh,
                      ),
                      child: Text(
                        labelPenyebab[p] ?? p,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            if (ai.catatan.isNotEmpty) ...[
              const SizedBox(height: Space.lg),
              Text(
                'Catatan',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(ai.catatan, style: theme.textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}

class _Keyakinan extends StatelessWidget {
  const _Keyakinan({required this.keyakinan});

  final String keyakinan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = switch (keyakinan) {
      'tinggi' => 3,
      'sedang' => 2,
      _ => 1,
    };
    final label = switch (keyakinan) {
      'tinggi' => 'Keyakinan tinggi',
      'sedang' => 'Keyakinan sedang',
      _ => 'Keyakinan rendah',
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 3; i++)
            Container(
              width: 6,
              height: 6 + i * 3,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: i <= level
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: Space.xs + 2),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
