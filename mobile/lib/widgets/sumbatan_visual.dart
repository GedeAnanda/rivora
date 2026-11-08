import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../theme/app_theme.dart';

/// Penampang saluran yang terisi sampah sesuai tingkat sumbatan.
///
/// Pengganti "skor sumbatan 0,85": warga langsung melihat seberapa penuh
/// salurannya. Bersih = air mengalir; tidak terlihat = garis putus-putus
/// dan tanda tanya.
class SumbatanVisual extends StatelessWidget {
  const SumbatanVisual({super.key, required this.kelas, this.width = 104});

  final KelasSumbatan kelas;
  final double width;

  static double isi(KelasSumbatan k) => switch (k) {
    KelasSumbatan.berat => 0.86,
    KelasSumbatan.sedang => 0.56,
    KelasSumbatan.ringan => 0.24,
    KelasSumbatan.bersih || KelasSumbatan.tidakTerlihat => 0,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final warna = context.rivora.sumbatan(kelas);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.of(context, Motion.reveal),
        curve: Motion.enter,
        builder: (context, t, _) => CustomPaint(
          size: Size(width, width * 0.72),
          painter: _Painter(
            kelas: kelas,
            t: t,
            dinding: scheme.onSurfaceVariant,
            sampah: warna.fg,
            latar: warna.bg,
            air: const Color(0xFF35C1F4),
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  const _Painter({
    required this.kelas,
    required this.t,
    required this.dinding,
    required this.sampah,
    required this.latar,
    required this.air,
  });

  final KelasSumbatan kelas;
  final double t;
  final Color dinding;
  final Color sampah;
  final Color latar;
  final Color air;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final atas = h * 0.12;
    final bawah = h * 0.92;
    // Dinding miring: lebar atas 0.84 w, bawah 0.5 w.
    final kiriAtas = Offset(w * 0.08, atas);
    final kananAtas = Offset(w * 0.92, atas);
    final kiriBawah = Offset(w * 0.25, bawah);
    final kananBawah = Offset(w * 0.75, bawah);
    final rongga = Path()
      ..moveTo(kiriAtas.dx, kiriAtas.dy)
      ..lineTo(kiriBawah.dx, kiriBawah.dy)
      ..lineTo(kananBawah.dx, kananBawah.dy)
      ..lineTo(kananAtas.dx, kananAtas.dy)
      ..close();

    canvas.drawPath(rongga, Paint()..color = latar);

    double xKiri(double y) =>
        kiriAtas.dx +
        (kiriBawah.dx - kiriAtas.dx) * (y - atas) / (bawah - atas);
    double xKanan(double y) =>
        kananAtas.dx +
        (kananBawah.dx - kananAtas.dx) * (y - atas) / (bawah - atas);

    canvas.save();
    canvas.clipPath(rongga);

    final f = SumbatanVisual.isi(kelas) * t;
    if (kelas == KelasSumbatan.bersih || kelas == KelasSumbatan.ringan) {
      // Air mengalir di dasar.
      final yAir = bawah - (bawah - atas) * 0.32 * t;
      final gelombang = Path()..moveTo(0, yAir);
      const n = 4;
      for (var i = 0; i < n; i++) {
        final x0 = w * i / n;
        final x1 = w * (i + 1) / n;
        gelombang.quadraticBezierTo((x0 + x1) / 2, yAir - h * 0.05, x1, yAir);
      }
      gelombang
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(gelombang, Paint()..color = air.withValues(alpha: 0.85));
    }
    if (f > 0) {
      // Tumpukan sampah dengan permukaan tidak rata.
      final y = bawah - (bawah - atas) * f;
      final tumpukan = Path()..moveTo(0, h);
      tumpukan.lineTo(0, y + h * 0.04);
      const n = 6;
      for (var i = 0; i < n; i++) {
        final x0 = w * i / n;
        final x1 = w * (i + 1) / n;
        final naik = i.isEven ? -h * 0.07 : h * 0.03;
        tumpukan.quadraticBezierTo((x0 + x1) / 2, y + naik, x1, y + h * 0.01);
      }
      tumpukan
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(tumpukan, Paint()..color = sampah.withValues(alpha: 0.9));
      // Beberapa "kantong plastik" terang di dalam tumpukan.
      final terang = Paint()..color = latar.withValues(alpha: 0.9);
      for (final (fx, fy, r) in const [
        (0.38, 0.35, 0.045),
        (0.58, 0.55, 0.035),
        (0.48, 0.75, 0.04),
      ]) {
        final cy = y + (bawah - y) * fy;
        if (cy > y + h * 0.04) {
          final cx = xKiri(cy) + (xKanan(cy) - xKiri(cy)) * fx * 1.6 - w * 0.12;
          canvas.drawCircle(Offset(cx, cy), w * r, terang);
        }
      }
    }
    canvas.restore();

    final garis = Paint()
      ..color = dinding
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final tepi = Path()
      ..moveTo(0, atas)
      ..lineTo(kiriAtas.dx, kiriAtas.dy)
      ..lineTo(kiriBawah.dx, kiriBawah.dy)
      ..lineTo(kananBawah.dx, kananBawah.dy)
      ..lineTo(kananAtas.dx, kananAtas.dy)
      ..lineTo(w, atas);

    if (kelas == KelasSumbatan.tidakTerlihat) {
      // Garis putus-putus + tanda tanya.
      for (final m in tepi.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, d + w * 0.06), garis);
          d += w * 0.1;
        }
      }
      final tp = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            color: dinding,
            fontSize: h * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((w - tp.width) / 2, (atas + bawah - tp.height) / 2),
      );
    } else {
      canvas.drawPath(tepi, garis);
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.kelas != kelas || old.t != t;
}
