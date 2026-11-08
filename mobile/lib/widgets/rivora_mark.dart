import 'package:flutter/material.dart';

/// Logo RIVORA "Mata Air" (docs/BRAND.md bagian 1): mata dengan iris berisi
/// air dan kilau berbentuk tetes. Digambar ulang dari
/// `brand/logo/rivora-mark.svg` (viewBox 120×84) tanpa dependensi SVG.
class MataAirPainter extends CustomPainter {
  const MataAirPainter({this.reverse = false});

  /// `true` = kelopak terang, untuk latar gelap (rivora-mark-reverse.svg).
  final bool reverse;

  static const _malam = Color(0xFF0B1F2A);
  static const _kabut = Color(0xFFF3F6F5);
  static const _arus = Color(0xFF0B6E79);
  static const _bening = Color(0xFF5FC3CF);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    canvas
      ..save()
      ..scale(s, s);

    final kelopak = Path()
      ..moveTo(4, 42)
      ..cubicTo(21, 13, 43, 4, 60, 4)
      ..cubicTo(77, 4, 99, 13, 116, 42)
      ..cubicTo(99, 71, 77, 80, 60, 80)
      ..cubicTo(43, 80, 21, 71, 4, 42)
      ..close();
    canvas
      ..drawPath(kelopak, Paint()..color = reverse ? _kabut : _malam)
      ..drawCircle(const Offset(60, 42), 25, Paint()..color = _arus);

    final air = Path()
      ..moveTo(35.03, 43.31)
      ..cubicTo(36.7, 42.68, 38.36, 41.85, 40.03, 41.42)
      ..cubicTo(41.69, 40.98, 43.36, 40.7, 45.02, 40.7)
      ..cubicTo(46.68, 40.7, 48.35, 40.99, 50.01, 41.43)
      ..cubicTo(51.68, 41.87, 53.34, 42.62, 55.01, 43.33)
      ..cubicTo(56.67, 44.04, 58.33, 44.97, 60, 45.67)
      ..cubicTo(61.66, 46.38, 63.33, 47.13, 64.99, 47.57)
      ..cubicTo(66.66, 48.01, 68.32, 48.3, 69.99, 48.3)
      ..cubicTo(71.65, 48.3, 73.31, 48.02, 74.98, 47.58)
      ..cubicTo(76.64, 47.14, 78.31, 46.39, 79.97, 45.69)
      ..cubicTo(81.64, 44.98, 83.3, 44.12, 84.96, 43.34)
      ..arcToPoint(
        const Offset(35.03, 43.31),
        radius: const Radius.circular(25),
      )
      ..close();
    canvas.drawPath(air, Paint()..color = _bening);

    final tetes = Path()
      ..moveTo(50.5, 21.5)
      ..cubicTo(50.5, 21.5, 45.7, 26.9, 45.7, 30.1)
      ..arcToPoint(
        const Offset(55.3, 30.1),
        radius: const Radius.circular(4.8),
        clockwise: false,
      )
      ..cubicTo(55.3, 26.9, 50.5, 21.5, 50.5, 21.5)
      ..close();
    canvas
      ..drawPath(tetes, Paint()..color = Colors.white)
      ..restore();
  }

  @override
  bool shouldRepaint(MataAirPainter oldDelegate) =>
      oldDelegate.reverse != reverse;
}

/// Ikon aplikasi RIVORA (brand/logo/rivora-app-icon.svg): kotak membulat
/// bergradien Arus dengan simbol Mata Air. Sama dengan ikon launcher.
class RivoraAppIcon extends StatelessWidget {
  const RivoraAppIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.2227),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF11808C), Color(0xFF0A4E57)],
          ),
        ),
        // Posisi simbol sama dengan ikon 1024 px: lebar 62,5 %, mulai 18,75 %.
        padding: EdgeInsets.fromLTRB(
          size * 0.1875,
          size * 0.28125,
          size * 0.1875,
          size * 0.28125,
        ),
        child: const CustomPaint(painter: MataAirPainter()),
      ),
    );
  }
}
