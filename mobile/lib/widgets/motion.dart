import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Angka skor yang "terungkap" dari nilai awal ke nilai akhir. Langsung
/// tampil nilai akhir kalau animasi dimatikan pengguna.
class AnimatedScore extends StatelessWidget {
  const AnimatedScore({
    super.key,
    required this.value,
    this.from = 0,
    this.style,
    this.color,
  });

  final double value;
  final double from;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from, end: value),
      duration: Motion.of(context, Motion.reveal),
      curve: Motion.enter,
      builder: (context, v, _) => Text(
        formatDesimal(v),
        style: style?.copyWith(
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Bar 0–1 yang terisi dengan animasi.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    super.key,
    required this.value,
    required this.color,
    required this.background,
    this.from = 0,
    this.height = 8,
  });

  final double value;
  final double from;
  final Color color;
  final Color background;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: from, end: value.clamp(0, 1)),
        duration: Motion.of(context, Motion.reveal),
        curve: Motion.enter,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: background,
        ),
      ),
    );
  }
}

/// Garis pindai yang menyapu foto saat AI sedang menganalisis. Saat animasi
/// dimatikan, foto cukup digelapkan dengan label status.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key, required this.label});

  final String label;

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Warna brand "Tirta" (air), docs/BRAND.md.
  static const _tirta = Color(0xFF35C1F4);

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return Semantics(
      liveRegion: true,
      label: widget.label,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0x66000000)),
          if (!reduced)
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Align(
                alignment: Alignment(
                  0,
                  Curves.easeInOut.transform(_c.value) * 2 - 1,
                ),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _tirta,
                    boxShadow: [
                      BoxShadow(
                        color: _tirta.withValues(alpha: 0.7),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.sm,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC07111F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Flexible(
                      child: Text(
                        widget.label,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak abu-abu berdenyut halus pengganti konten yang sedang dimuat.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 14, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerHighest,
            math.sin(_c.value * math.pi / 2),
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Tiga kartu kerangka untuk daftar laporan/tugas yang sedang dimuat.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.fromLTRB(
      Space.lg,
      Space.sm,
      Space.lg,
      Space.xxl,
    ),
  });

  final int count;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat',
      child: ListView.separated(
        padding: padding,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
        itemBuilder: (_, _) => const Card(
          child: Padding(
            padding: EdgeInsets.all(Space.md),
            child: Row(
              children: [
                Skeleton(width: 72, height: 72, radius: Radii.sm),
                SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 140, height: 16),
                      SizedBox(height: Space.sm),
                      Skeleton(width: 200, height: 12),
                      SizedBox(height: Space.md),
                      Skeleton(width: 110, height: 20, radius: Radii.sm),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
