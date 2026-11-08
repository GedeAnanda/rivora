import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../models/jenis_saluran.dart';
import '../theme/app_theme.dart';
import 'sumbatan_style.dart';

/// Foto saluran: file lokal (laporan sendiri), URL server, atau pengganti
/// bergaya kalau belum ada foto. Pengganti memakai warna kelas sumbatan dan
/// ikon jenis saluran, jadi daftar tetap terbaca walau tanpa foto.
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
    required this.semanticLabel,
  });

  final File? file;
  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final KelasSumbatan? kelas;
  final JenisSaluran? jenis;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Placeholder(
      width: width,
      height: height,
      kelas: kelas,
      jenis: jenis,
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
  const _Placeholder({this.width, this.height, this.kelas, this.jenis});

  final double? width;
  final double? height;
  final KelasSumbatan? kelas;
  final JenisSaluran? jenis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = kelas == null ? null : context.rivora.sumbatan(kelas!);
    final bg = c?.bg ?? scheme.surfaceContainerHigh;
    final fg = c?.fg ?? scheme.onSurfaceVariant;
    final besar = (height ?? 0) >= 120;
    return Container(
      width: width,
      height: height,
      color: bg,
      child: CustomPaint(
        painter: _GarisAir(fg.withValues(alpha: 0.10)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                jenis == null ? Icons.image_outlined : ikonJenis(jenis!),
                color: fg,
                size: besar ? 40 : 26,
              ),
              if (besar) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'Belum ada foto',
                  style: theme.textTheme.labelMedium?.copyWith(color: fg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Garis gelombang tipis sebagai tekstur latar pengganti foto.
class _GarisAir extends CustomPainter {
  const _GarisAir(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const jarak = 14.0;
    for (var y = jarak / 2; y < size.height + jarak; y += jarak) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width; x += 24) {
        path.quadraticBezierTo(x + 6, y - 4, x + 12, y);
        path.quadraticBezierTo(x + 18, y + 4, x + 24, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_GarisAir oldDelegate) => oldDelegate.color != color;
}
