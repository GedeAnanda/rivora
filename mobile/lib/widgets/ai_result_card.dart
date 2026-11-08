import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../theme/rivora_icons.dart';
import 'sumbatan_style.dart';
import 'sumbatan_visual.dart';

/// Ringkasan hasil analisis AI (Lampiran C) untuk warga: gambar tingkat
/// sumbatan + kalimat, penyebab, keyakinan dalam kata (selalu tampil,
/// Tabel 8), dan catatan. Skor 0–1 hanya untuk pembaca layar.
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
                    'Hasil pemeriksaan AI',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                KeyakinanAi(keyakinan: ai.keyakinan),
              ],
            ),
            const SizedBox(height: Space.lg),
            // Kondisi dalam gambar + kalimat, bukan angka 0–1.
            Semantics(
              label:
                  '${ai.kelas.label}. ${kataSumbatan(ai.kelas)}'
                  '${skor == null ? '' : '. Skor ${formatDesimal(skor)} dari 1'}',
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SumbatanVisual(kelas: ai.kelas),
                  const SizedBox(width: Space.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ai.kelas.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: warna.fg,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          kataSumbatan(ai.kelas),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (ai.keyakinan != 'tinggi' ||
                ai.kelas == KelasSumbatan.tidakTerlihat) ...[
              const SizedBox(height: Space.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    RIcons.petugas,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Petugas kelurahan akan memastikan langsung di lokasi.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
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

/// Keyakinan AI: tiga batang + kata ("AI yakin").
class KeyakinanAi extends StatelessWidget {
  const KeyakinanAi({super.key, required this.keyakinan});

  final String keyakinan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = switch (keyakinan) {
      'tinggi' => 3,
      'sedang' => 2,
      _ => 1,
    };
    final label = kataKeyakinan(keyakinan);
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
