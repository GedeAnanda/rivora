import 'package:flutter/material.dart';

import '../models/ai_result.dart';

Color warnaSumbatan(KelasSumbatan kelas) => switch (kelas) {
  KelasSumbatan.bersih => Colors.green.shade600,
  KelasSumbatan.ringan => Colors.lime.shade800,
  KelasSumbatan.sedang => Colors.orange.shade700,
  KelasSumbatan.berat => Colors.red.shade700,
  KelasSumbatan.tidakTerlihat => Colors.blueGrey.shade500,
};

IconData ikonSumbatan(KelasSumbatan kelas) => switch (kelas) {
  KelasSumbatan.bersih => Icons.check_circle,
  KelasSumbatan.ringan => Icons.info,
  KelasSumbatan.sedang => Icons.warning_amber_rounded,
  KelasSumbatan.berat => Icons.dangerous,
  KelasSumbatan.tidakTerlihat => Icons.visibility_off,
};

/// Label kelas sumbatan berwarna, dipakai di layar hasil.
class SumbatanBadge extends StatelessWidget {
  const SumbatanBadge({super.key, required this.kelas});

  final KelasSumbatan kelas;

  @override
  Widget build(BuildContext context) {
    final color = warnaSumbatan(kelas);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikonSumbatan(kelas), size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            kelas.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
