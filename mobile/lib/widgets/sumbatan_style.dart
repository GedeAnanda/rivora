import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../theme/app_theme.dart';

IconData ikonSumbatan(KelasSumbatan kelas) => switch (kelas) {
  KelasSumbatan.bersih => Icons.check_circle_rounded,
  KelasSumbatan.ringan => Icons.info_rounded,
  KelasSumbatan.sedang => Icons.warning_rounded,
  KelasSumbatan.berat => Icons.error_rounded,
  KelasSumbatan.tidakTerlihat => Icons.visibility_off_rounded,
};

/// Label kelas sumbatan: ikon + teks + warna (tidak hanya warna).
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
        vertical: compact ? 2 : Space.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.bg,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikonSumbatan(kelas), size: compact ? 14 : 18, color: color.fg),
          SizedBox(width: compact ? Space.xs : 6),
          Flexible(
            child: Text(
              kelas.label,
              overflow: TextOverflow.ellipsis,
              style: (compact ? text.labelMedium : text.labelLarge)?.copyWith(
                color: color.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
