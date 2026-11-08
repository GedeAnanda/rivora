import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/services/weather_service.dart';
import 'package:rivora/theme/app_theme.dart';
import 'package:rivora/theme/rivora_icons.dart';
import 'package:rivora/widgets/pictogram.dart';
import 'package:rivora/widgets/rain_card.dart';

/// Tahap 12: ikon Lucide dan font Plus Jakarta Sans.
void main() {
  test('ikon dari satu keluarga Lucide', () {
    for (final i in [RIcons.beranda, RIcons.kamera, RIcons.saluranTerbuka]) {
      expect(i.fontFamily, 'Lucide');
      expect(i.fontPackage, 'lucide_icons_flutter');
    }
    expect(RIcons.berandaAktif.fontFamily, 'Lucide600');
    expect(RIcons.cuacaHujan.fontFamily, 'Lucide300');
  });

  test('ikon cuaca ikut kategori hujan', () {
    expect(CuacaIlustrasi.ikon(KategoriHujan.tidak), RIcons.cuacaCerah);
    expect(CuacaIlustrasi.ikon(KategoriHujan.ringan), RIcons.cuacaGerimis);
    expect(CuacaIlustrasi.ikon(KategoriHujan.sedang), RIcons.cuacaHujan);
    expect(CuacaIlustrasi.ikon(KategoriHujan.lebat), RIcons.cuacaLebat);
    expect(CuacaIlustrasi.ikon(KategoriHujan.ekstrem), RIcons.cuacaLebat);
  });

  testWidgets('gorong-gorong: silinder diputar jadi pipa mendatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRivoraTheme(Brightness.light),
        home: const Row(
          children: [
            JenisPictogram(jenis: JenisSaluran.gorongGorong),
            JenisPictogram(jenis: JenisSaluran.terbuka),
          ],
        ),
      ),
    );
    expect(find.byType(RotatedBox), findsOneWidget);
    expect(find.byIcon(RIcons.gorongGorong), findsOneWidget);
    expect(find.byIcon(RIcons.saluranTerbuka), findsOneWidget);
  });

  test('teks memakai Plus Jakarta Sans dengan angka selebar sama', () {
    final t = buildRivoraTheme(Brightness.light).textTheme;
    expect(t.bodyMedium?.fontFamily, 'PlusJakartaSans');
    expect(
      t.headlineMedium?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });
}
