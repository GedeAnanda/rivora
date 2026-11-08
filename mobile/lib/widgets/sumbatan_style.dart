import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../models/jenis_saluran.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';

IconData ikonSumbatan(KelasSumbatan kelas) => switch (kelas) {
  KelasSumbatan.bersih => RIcons.selesai,
  KelasSumbatan.ringan => RIcons.info,
  KelasSumbatan.sedang => RIcons.peringatan,
  KelasSumbatan.berat => RIcons.bahaya,
  KelasSumbatan.tidakTerlihat => RIcons.tidakTerlihat,
};

/// Label kelas sumbatan: teks tebal di atas latar berwarna. Warna + teks
/// (tidak hanya warna); tanpa ikon dekoratif supaya kartu tidak ramai.
class SumbatanBadge extends StatelessWidget {
  const SumbatanBadge({super.key, required this.kelas, this.compact = false});

  final KelasSumbatan kelas;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = context.rivora.sumbatan(kelas);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.sm : Space.md,
        vertical: compact ? 2 : Space.xs + 1,
      ),
      decoration: BoxDecoration(
        color: color.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        compact ? _pendek(kelas) : kelas.label,
        style: (compact ? text.labelMedium : text.labelLarge)?.copyWith(
          color: color.fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _pendek(KelasSumbatan k) => switch (k) {
    KelasSumbatan.bersih => 'Bersih',
    KelasSumbatan.ringan => 'Ringan',
    KelasSumbatan.sedang => 'Sedang',
    KelasSumbatan.berat => 'Berat',
    KelasSumbatan.tidakTerlihat => 'Tidak terlihat',
  };
}

/// Nama jenis saluran untuk aksesibilitas/ringkasan.
String namaJenis(JenisSaluran j) => j.label;
