import 'package:flutter/material.dart';

import '../models/ai_result.dart';

/// Token desain RIVORA. Rasional dan rasio kontras:
/// docs/mobile/00-design-system.md
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
}

/// Pasangan warna teks/ikon di atas latar berwarna. Semua pasangan
/// sudah dicek kontrasnya ≥ 4,5:1.
@immutable
class StatusColor {
  const StatusColor(this.fg, this.bg);

  final Color fg;
  final Color bg;
}

/// Warna semantik di luar ColorScheme bawaan Material.
@immutable
class RivoraColors extends ThemeExtension<RivoraColors> {
  const RivoraColors({
    required this.bersih,
    required this.ringan,
    required this.sedang,
    required this.berat,
    required this.tidakTerlihat,
  });

  final StatusColor bersih;
  final StatusColor ringan;
  final StatusColor sedang;
  final StatusColor berat;
  final StatusColor tidakTerlihat;

  StatusColor sumbatan(KelasSumbatan kelas) => switch (kelas) {
    KelasSumbatan.bersih => bersih,
    KelasSumbatan.ringan => ringan,
    KelasSumbatan.sedang => sedang,
    KelasSumbatan.berat => berat,
    KelasSumbatan.tidakTerlihat => tidakTerlihat,
  };

  static const light = RivoraColors(
    bersih: StatusColor(Color(0xFF17663F), Color(0xFFE3F3EA)),
    ringan: StatusColor(Color(0xFF5C6B0A), Color(0xFFF1F4DC)),
    sedang: StatusColor(Color(0xFF9A4A06), Color(0xFFFCEBD9)),
    berat: StatusColor(Color(0xFFA51C14), Color(0xFFFBE4E1)),
    tidakTerlihat: StatusColor(Color(0xFF4A5A62), Color(0xFFE7ECEE)),
  );

  static const dark = RivoraColors(
    bersih: StatusColor(Color(0xFF7BD8A6), Color(0xFF12301F)),
    ringan: StatusColor(Color(0xFFC9D86A), Color(0xFF2A2F0E)),
    sedang: StatusColor(Color(0xFFF5B26B), Color(0xFF3A2410)),
    berat: StatusColor(Color(0xFFFF9A8F), Color(0xFF3D1714)),
    tidakTerlihat: StatusColor(Color(0xFFB4C2C8), Color(0xFF243034)),
  );

  @override
  RivoraColors copyWith() => this;

  @override
  RivoraColors lerp(RivoraColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension RivoraThemeContext on BuildContext {
  RivoraColors get rivora => Theme.of(this).extension<RivoraColors>()!;
}

ThemeData buildRivoraTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: light ? const Color(0xFF0B6E79) : const Color(0xFF5FC3CF),
    onPrimary: light ? Colors.white : const Color(0xFF00363D),
    primaryContainer: light ? const Color(0xFFD3ECEE) : const Color(0xFF0E4A52),
    onPrimaryContainer: light
        ? const Color(0xFF052F35)
        : const Color(0xFFCDEFF3),
    secondary: light ? const Color(0xFF0B1F2A) : const Color(0xFFE6EEF0),
    onSecondary: light ? Colors.white : const Color(0xFF0B1F2A),
    // Dipakai SegmentedButton/filter terpilih: samakan dengan aksen teal.
    secondaryContainer: light
        ? const Color(0xFFD3ECEE)
        : const Color(0xFF0E4A52),
    onSecondaryContainer: light
        ? const Color(0xFF052F35)
        : const Color(0xFFCDEFF3),
    error: light ? const Color(0xFFB42318) : const Color(0xFFFF9A8F),
    onError: light ? Colors.white : const Color(0xFF3D1714),
    surface: light ? const Color(0xFFF3F6F5) : const Color(0xFF0D1417),
    onSurface: light ? const Color(0xFF0B1F2A) : const Color(0xFFE6EEF0),
    onSurfaceVariant: light ? const Color(0xFF46575D) : const Color(0xFFA7B6BB),
    surfaceContainerLowest: light ? Colors.white : const Color(0xFF152024),
    surfaceContainerLow: light
        ? const Color(0xFFF8FAF9)
        : const Color(0xFF172327),
    surfaceContainer: light ? const Color(0xFFEDF1F0) : const Color(0xFF1B282C),
    surfaceContainerHigh: light
        ? const Color(0xFFE6ECEA)
        : const Color(0xFF213034),
    surfaceContainerHighest: light
        ? const Color(0xFFDCE3E1)
        : const Color(0xFF283A3F),
    outline: light ? const Color(0xFF7A8B90) : const Color(0xFF6F8186),
    outlineVariant: light ? const Color(0xFFDCE3E1) : const Color(0xFF2A3A3F),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'AtkinsonHyperlegible',
    scaffoldBackgroundColor: scheme.surface,
    extensions: [light ? RivoraColors.light : RivoraColors.dark],
  );
  // base.textTheme baru berisi warna + font; ukuran huruf baru diisi Flutter
  // saat runtime. Gabungkan dengan geometri M3 supaya gaya di tema ini
  // (judul AppBar, tombol, chip) punya ukuran yang benar.
  final text = Typography.englishLike2021.merge(base.textTheme);
  const bold = FontWeight.w700;
  final buttonText = text.titleMedium?.copyWith(fontWeight: bold);
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: bold),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: bold),
      titleLarge: text.titleLarge?.copyWith(fontWeight: bold),
      titleMedium: text.titleMedium?.copyWith(fontWeight: bold),
      labelLarge: text.labelLarge?.copyWith(fontWeight: bold),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: bold,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: buttonShape,
        side: BorderSide(color: scheme.outline),
        foregroundColor: scheme.onSurface,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: text.labelLarge?.copyWith(fontWeight: bold),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? bold
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.outline),
      labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      space: 1,
      thickness: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
