import 'package:flutter/material.dart';

import '../models/jenis_saluran.dart';

/// Piktogram jenis saluran, digambar khusus untuk RIVORA (bukan ikon
/// generik): penampang saluran terbuka, gorong-gorong di bawah jalan, dan
/// kisi inlet jalan. Garis seragam 7 % dari ukuran, ujung membulat.
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

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _Painter(
          jenis,
          color ?? IconTheme.of(context).color ?? Colors.black,
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  const _Painter(this.jenis, this.color);

  final JenisSaluran jenis;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final garis = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final tipis = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;

    Path air(double x0, double x1, double y) {
      final path = Path()..moveTo(x0 * s, y * s);
      const n = 3;
      final w = (x1 - x0) / n;
      for (var i = 0; i < n; i++) {
        final x = x0 + w * i;
        path.quadraticBezierTo(
          (x + w / 4) * s,
          (y - 0.05) * s,
          (x + w / 2) * s,
          y * s,
        );
        path.quadraticBezierTo(
          (x + 3 * w / 4) * s,
          (y + 0.05) * s,
          (x + w) * s,
          y * s,
        );
      }
      return path;
    }

    switch (jenis) {
      // Penampang saluran terbuka: tanah kiri-kanan, dinding miring, air.
      case JenisSaluran.terbuka:
        canvas
          ..drawPath(
            Path()
              ..moveTo(p(0.06, 0.34).dx, p(0.06, 0.34).dy)
              ..lineTo(p(0.26, 0.34).dx, p(0.26, 0.34).dy)
              ..lineTo(p(0.34, 0.76).dx, p(0.34, 0.76).dy)
              ..lineTo(p(0.66, 0.76).dx, p(0.66, 0.76).dy)
              ..lineTo(p(0.74, 0.34).dx, p(0.74, 0.34).dy)
              ..lineTo(p(0.94, 0.34).dx, p(0.94, 0.34).dy),
            garis,
          )
          ..drawPath(air(0.33, 0.67, 0.58), tipis);
      // Gorong-gorong: permukaan jalan di atas, pipa bulat di bawahnya.
      case JenisSaluran.gorongGorong:
        canvas
          ..drawLine(p(0.06, 0.26), p(0.94, 0.26), garis)
          ..drawLine(p(0.2, 0.14), p(0.32, 0.14), tipis)
          ..drawLine(p(0.68, 0.14), p(0.8, 0.14), tipis)
          ..drawCircle(p(0.5, 0.6), s * 0.22, garis)
          ..drawPath(air(0.36, 0.64, 0.68), tipis);
      // Inlet jalan: kisi dengan bilah tegak, panah air masuk.
      case JenisSaluran.inletJalan:
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(0.16 * s, 0.3 * s, 0.84 * s, 0.78 * s),
              Radius.circular(0.08 * s),
            ),
            garis,
          )
          ..drawLine(p(0.33, 0.42), p(0.33, 0.66), tipis)
          ..drawLine(p(0.5, 0.42), p(0.5, 0.66), tipis)
          ..drawLine(p(0.67, 0.42), p(0.67, 0.66), tipis)
          ..drawLine(p(0.5, 0.06), p(0.5, 0.2), tipis)
          ..drawPath(
            Path()
              ..moveTo(p(0.43, 0.14).dx, p(0.43, 0.14).dy)
              ..lineTo(p(0.5, 0.21).dx, p(0.5, 0.21).dy)
              ..lineTo(p(0.57, 0.14).dx, p(0.57, 0.14).dy),
            tipis,
          );
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.jenis != jenis || old.color != color;
}
