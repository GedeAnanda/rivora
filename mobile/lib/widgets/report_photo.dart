import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../models/jenis_saluran.dart';
import '../theme/app_theme.dart';
import 'pictogram.dart';

/// Foto saluran: file lokal (laporan sendiri), URL server, atau pengganti
/// kalau belum ada foto. Pengganti = latar warna kelas sumbatan + piktogram
/// jenis saluran, jadi tetap informatif tanpa foto.
class ReportPhoto extends StatelessWidget {
  const ReportPhoto({
    super.key,
    this.file,
    this.url,
    this.width,
    this.height,
    this.radius = Radii.md,
    this.kelas,
    this.jenis,
    this.placeholderAlignment = Alignment.center,
    required this.semanticLabel,
  });

  final File? file;
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final KelasSumbatan? kelas;
  final JenisSaluran? jenis;

  /// Posisi piktogram pengganti. Pembanding sebelum/sesudah memakai
  /// setengah kiri supaya tidak tertutup tuas di tengah.
  final Alignment placeholderAlignment;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
      width: width,
      height: height,
      kelas: kelas,
      jenis: jenis,
      alignment: placeholderAlignment,
    );
    final Widget image;
    if (file != null) {
      image = Image.file(
        file!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => placeholder,
      );
    } else if (url != null && url!.isNotEmpty) {
      image = Image.network(
        url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        semanticLabel: semanticLabel,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder,
      );
    } else {
      image = Semantics(label: semanticLabel, image: true, child: placeholder);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    this.width,
    this.height,
    this.kelas,
    this.jenis,
    this.alignment = Alignment.center,
  });

  final double? width;
  final double? height;
  final KelasSumbatan? kelas;
  final JenisSaluran? jenis;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = kelas == null ? null : context.rivora.sumbatan(kelas!);
    final bg = c?.bg ?? scheme.surfaceContainerHigh;
    final fg = c?.fg ?? scheme.onSurfaceVariant;
    return Container(
      width: width,
      height: height,
      color: bg,
      alignment: alignment,
      // Ukuran ikut ruang yang tersedia (juga saat mengisi induknya).
      child: LayoutBuilder(
        builder: (context, c) {
          final tinggi = height ?? c.maxHeight;
          final besar = tinggi.isFinite && tinggi >= 120;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              JenisPictogram(
                jenis: jenis ?? JenisSaluran.terbuka,
                size: besar ? 56 : 34,
                color: fg,
              ),
              if (besar) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'Belum ada foto',
                  style: theme.textTheme.labelMedium?.copyWith(color: fg),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
