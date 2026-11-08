import 'package:flutter/material.dart';

import '../models/verification.dart';
import '../theme/app_theme.dart';

/// Meteran risiko tiga warna (Aman · Waspada · Tinggi) dengan penanda posisi.
///
/// Pengganti angka 0–1 untuk warga: cukup lihat penanda ada di warna apa.
/// Lebar segmen mengikuti ambang skor (aman < 0,40, waspada < 0,70), jadi
/// posisinya tetap jujur terhadap angka aslinya. [dari] menggerakkan penanda
/// dari skor lama ke skor baru (mis. setelah saluran dibersihkan).
class RiskMeter extends StatelessWidget {
  const RiskMeter({super.key, required this.skor, this.dari});

  final double skor;
  final double? dari;

  static const _segmen = [
    (LevelRisiko.aman, 4, 'Aman'),
    (LevelRisiko.waspada, 3, 'Waspada'),
    (LevelRisiko.risikoTinggi, 3, 'Tinggi'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rv = context.rivora;
    final akhir = LevelRisiko.dariSkor(skor);

    return Semantics(
      label: dari == null
          ? 'Tingkat risiko ${akhir.label}'
          : 'Tingkat risiko berubah dari '
                '${LevelRisiko.dariSkor(dari!).label} ke ${akhir.label}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: dari ?? 0, end: skor.clamp(0, 1)),
        duration: Motion.of(
          context,
          dari == null ? Motion.reveal : const Duration(milliseconds: 1400),
        ),
        curve: dari == null ? Motion.enter : Curves.easeInOutCubic,
        builder: (context, v, _) {
          final level = LevelRisiko.dariSkor(v);
          return Column(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  const titik = 22.0;
                  final x = (v * w - titik / 2).clamp(0.0, w - titik);
                  return SizedBox(
                    height: titik,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        Row(
                          children: [
                            for (final (i, s) in _segmen.indexed) ...[
                              if (i > 0) const SizedBox(width: 3),
                              Expanded(
                                flex: s.$2,
                                child: AnimatedContainer(
                                  duration: Motion.of(context, Motion.normal),
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: s.$1 == level
                                        ? rv.risiko(s.$1).fg
                                        : rv.risiko(s.$1).bg,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(i == 0 ? 5 : 2),
                                      right: Radius.circular(
                                        i == _segmen.length - 1 ? 5 : 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Positioned(
                          left: x,
                          child: Container(
                            width: titik,
                            height: titik,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: rv.risiko(level).fg,
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  for (final (i, s) in _segmen.indexed) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: s.$2,
                      child: Text(
                        s.$3,
                        textAlign: i == 0
                            ? TextAlign.start
                            : i == _segmen.length - 1
                            ? TextAlign.end
                            : TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: s.$1 == level
                              ? rv.risiko(s.$1).fg
                              : scheme.onSurfaceVariant,
                          fontWeight: s.$1 == level
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kata sederhana untuk nilai komponen 0–1: rendah / sedang / tinggi.
enum TingkatFaktor {
  rendah('Rendah'),
  sedang('Sedang'),
  tinggi('Tinggi');

  const TingkatFaktor(this.label);
  final String label;

  static TingkatFaktor dari(double v) => v >= 0.7
      ? tinggi
      : v >= 0.4
      ? sedang
      : rendah;

  LevelRisiko get warna => switch (this) {
    rendah => LevelRisiko.aman,
    sedang => LevelRisiko.waspada,
    tinggi => LevelRisiko.risikoTinggi,
  };
}
