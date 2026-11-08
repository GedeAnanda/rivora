import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rivora_mark.dart';

/// Tanda merek RIVORA di dalam aplikasi = ikon aplikasi "Ombak".
class RivoraMark extends StatelessWidget {
  const RivoraMark({super.key, this.size = 40});

  final double size;

  /// Ombak putih logo menyentuh tepi bawah; di latar terang tepinya
  /// menyatu dengan halaman. Garis tipis menjaga bentuk kotak ikon tetap
  /// terbaca (radius sama dengan ikon, 22,3 %).
  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.223),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: RivoraAppIcon(size: size),
  );
}

/// Judul bagian di dalam halaman.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Keadaan kosong / gagal: ikon, judul, penjelasan, aksi opsional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xxl,
        vertical: Space.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Space.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Space.lg),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lebar layar dibagi skala huruf. Di bawah 380 dp, label dua tombol
/// berdampingan mulai terlipat (HP kecil atau huruf besar).
bool layarSempit(BuildContext context) =>
    MediaQuery.sizeOf(context).width /
        MediaQuery.textScalerOf(context).scale(1) <
    380;

/// Tombol sekunder + utama. Berdampingan (2 : 3) di layar lebar; ditumpuk
/// (utama di atas) di layar sempit supaya label tidak terlipat dua baris.
class TombolBerpasangan extends StatelessWidget {
  const TombolBerpasangan({
    super.key,
    required this.sekunder,
    required this.utama,
    this.rata = false,
  });

  final Widget sekunder;
  final Widget utama;

  /// `true` = lebar sama (1 : 1).
  final bool rata;

  @override
  Widget build(BuildContext context) {
    if (layarSempit(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          utama,
          const SizedBox(height: Space.sm),
          sekunder,
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: rata ? 1 : 2, child: sekunder),
        const SizedBox(width: Space.md),
        Expanded(flex: rata ? 1 : 3, child: utama),
      ],
    );
  }
}
