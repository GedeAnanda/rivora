import 'package:flutter/material.dart';

/// Garis muka ombak logo RIVORA (docs/BRAND.md bagian 1) di kotak 100×100,
/// diperpanjang lurus ke kiri-kanan lalu ditutup ke bawah supaya jadi bidang
/// air. Angka dari `python3 brand/tools/build_logo.py <dir> --dart`, digambar
/// tanpa dependensi SVG.
Path _ombak() => Path()
  ..moveTo(-60, 74)
  ..cubicTo(-41.67, 74, -23.33, 74, -5, 74)
  ..cubicTo(12, 74, 22, 64, 28, 50)
  ..cubicTo(36, 32, 50, 22, 64, 24)
  ..cubicTo(78, 26, 88, 38, 86, 52)
  ..cubicTo(85.5, 58.5, 81, 63.5, 75.5, 63.5)
  ..cubicTo(71.5, 63.5, 70.3, 59, 72.8, 56.6)
  ..cubicTo(76.3, 53.3, 76, 47, 70, 44)
  ..cubicTo(62, 40, 50, 42, 48, 52)
  ..cubicTo(46, 62, 56, 71, 68, 71)
  ..cubicTo(80, 71, 92, 69, 105, 67)
  ..cubicTo(125, 63.92, 145, 60.85, 165, 57.77)
  ..lineTo(165, 200)
  ..lineTo(-60, 200)
  ..close();

/// Simbol RIVORA "Ombak": ombak menggulung di dalam lingkaran
/// (`brand/logo/rivora-mark.svg`).
class OmbakPainter extends CustomPainter {
  const OmbakPainter({this.reverse = false});

  /// `true` = lingkaran putih dan ombak biru, untuk latar gelap
  /// (`rivora-mark-reverse.svg`).
  final bool reverse;

  static const _laut = Color(0xFF0361C3);
  static const _tirta = Color(0xFF35C1F4);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    final lingkaran = Rect.fromCircle(center: const Offset(50, 50), radius: 46);
    canvas
      ..save()
      ..translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2)
      ..scale(s, s)
      ..drawOval(lingkaran, Paint()..color = reverse ? Colors.white : _laut)
      ..clipPath(Path()..addOval(lingkaran))
      ..drawPath(_ombak(), Paint()..color = reverse ? _laut : _tirta)
      ..restore();
  }

  @override
  bool shouldRepaint(OmbakPainter oldDelegate) =>
      oldDelegate.reverse != reverse;
}

/// Ikon aplikasi RIVORA (`brand/logo/rivora-app-icon.svg`): kotak membulat
/// bergradien biru dengan ombak putih memenuhi ikon. Sama dengan ikon
/// launcher Android.
class RivoraAppIcon extends StatelessWidget {
  const RivoraAppIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: const _IkonPainter(),
      ),
    );
  }
}

class _IkonPainter extends CustomPainter {
  const _IkonPainter();

  static const _bidang = Rect.fromLTWH(0, 0, 100, 100);
  static const _gradien = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22B2F2), Color(0xFF0347A8)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas
      ..save()
      ..scale(s, s)
      // Sudut 22,3 % sama dengan ikon 1024 px (radius 228 px).
      ..clipRRect(RRect.fromRectAndRadius(_bidang, const Radius.circular(22.3)))
      ..drawRect(_bidang, Paint()..shader = _gradien.createShader(_bidang))
      // Posisi ombak sama dengan ikon SVG: geser (-6, 8), skala 1,12.
      ..translate(-6, 8)
      ..scale(1.12, 1.12)
      ..drawPath(_ombak(), Paint()..color = Colors.white)
      ..restore();
  }

  @override
  bool shouldRepaint(_IkonPainter oldDelegate) => false;
}
