import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Pembanding foto sebelum dan sesudah dibersihkan (proposal 3.2 langkah 4).
///
/// Geser garis tengah untuk membandingkan. Alternatif tanpa geser: ketuk
/// bagian foto mana pun untuk memindah garis ke titik itu, dan TalkBack
/// bisa menaikkan/menurunkan posisinya (aksi slider).
class BeforeAfterCompare extends StatefulWidget {
  const BeforeAfterCompare({
    super.key,
    required this.before,
    required this.after,
    this.aspectRatio = 4 / 3,
  });

  final Widget before;
  final Widget after;
  final double aspectRatio;

  @override
  State<BeforeAfterCompare> createState() => _BeforeAfterCompareState();
}

class _BeforeAfterCompareState extends State<BeforeAfterCompare> {
  double _pos = 0.5;

  void _set(double v) {
    final next = v.clamp(0.0, 1.0);
    if ((next - _pos).abs() < 0.001) return;
    setState(() => _pos = next);
  }

  void _step(double delta) {
    HapticFeedback.selectionClick();
    _set(_pos + delta);
  }

  @override
  Widget build(BuildContext context) {
    final persen = (_pos * 100).round();
    return Semantics(
      slider: true,
      label: 'Bandingkan foto sebelum dan sesudah',
      value: '$persen persen foto sebelum',
      increasedValue: '${(persen + 10).clamp(0, 100)} persen foto sebelum',
      decreasedValue: '${(persen - 10).clamp(0, 100)} persen foto sebelum',
      onIncrease: () => _step(0.1),
      onDecrease: () => _step(-0.1),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _set(d.localPosition.dx / w),
                onHorizontalDragUpdate: (d) => _set(d.localPosition.dx / w),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ExcludeSemantics(child: widget.after),
                    ClipRect(
                      clipper: _LeftClipper(_pos),
                      child: ExcludeSemantics(child: widget.before),
                    ),
                    const Positioned(
                      left: Space.md,
                      top: Space.md,
                      child: _Tag('Sebelum'),
                    ),
                    const Positioned(
                      right: Space.md,
                      top: Space.md,
                      child: _Tag('Sesudah'),
                    ),
                    Positioned(
                      left: _pos * w - 1,
                      top: 0,
                      bottom: 0,
                      child: const SizedBox(
                        width: 2,
                        child: ColoredBox(color: Colors.white),
                      ),
                    ),
                    Positioned(
                      left: _pos * w - 22,
                      top: 0,
                      bottom: 0,
                      child: const Center(child: _Handle()),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  const _LeftClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.fraction != fraction;
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFF0B6E79), width: 2),
      ),
      child: const Icon(
        Icons.compare_arrows_rounded,
        color: Color(0xFF0B6E79),
        size: 22,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1F2A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}
