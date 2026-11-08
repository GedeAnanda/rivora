import 'package:flutter/material.dart';

import '../models/jenis_saluran.dart';
import '../theme/rivora_icons.dart';

/// Ikon jenis saluran dari keluarga Lucide yang sama dengan ikon lain:
/// gelombang (saluran terbuka), pipa silinder mendatar (gorong-gorong),
/// kisi (inlet jalan).
class JenisPictogram extends StatelessWidget {
  const JenisPictogram({
    super.key,
    required this.jenis,
    this.size = 32,
    this.color,
  });

  final JenisSaluran jenis;
  final double size;
  final Color? color;

  static IconData ikon(JenisSaluran j) => switch (j) {
    JenisSaluran.terbuka => RIcons.saluranTerbuka,
    JenisSaluran.gorongGorong => RIcons.gorongGorong,
    JenisSaluran.inletJalan => RIcons.inletJalan,
  };

  @override
  Widget build(BuildContext context) {
    final icon = Icon(ikon(jenis), size: size, color: color);
    return ExcludeSemantics(
      // Silinder Lucide berdiri seperti kaleng; diputar jadi pipa mendatar.
      child: jenis == JenisSaluran.gorongGorong
          ? RotatedBox(quarterTurns: 1, child: icon)
          : icon,
    );
  }
}
