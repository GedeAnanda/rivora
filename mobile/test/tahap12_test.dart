import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/models/rw_risk.dart';
import 'package:rivora/models/verification.dart';
import 'package:rivora/services/weather_service.dart';
import 'package:rivora/theme/app_theme.dart';
import 'package:rivora/theme/rivora_icons.dart';
import 'package:rivora/widgets/pictogram.dart';
import 'package:rivora/widgets/rain_card.dart';

/// Tahap 12: ikon Lucide, font Plus Jakarta Sans, RW sebagai lingkaran.
void main() {
  // RW persegi seperti seed backend: sel 0,004° (±440 m).
  const x0 = 107.684, y0 = -6.936, sel = 0.004;
  const rw = RwRisk(
    rwId: '5',
    nama: 'RW 05',
    skor: 0.7,
    level: LevelRisiko.risikoTinggi,
    polygon: [
      LatLng(y0, x0),
      LatLng(y0, x0 + sel),
      LatLng(y0 - sel, x0 + sel),
      LatLng(y0 - sel, x0),
      LatLng(y0, x0),
    ],
  );

  test('lingkaran RW: pusat di tengah kotak, jari-jari ±0,44 × lebar', () {
    final p = rw.pusat!;
    expect(p.latitude, closeTo(y0 - sel / 2, 1e-9));
    expect(p.longitude, closeTo(x0 + sel / 2, 1e-9));
    final lebar = const Distance().as(
      LengthUnit.Meter,
      const LatLng(y0, x0),
      const LatLng(y0, x0 + sel),
    );
    expect(rw.radiusMeter / lebar, closeTo(0.44, 0.02));
  });

  test('label RW di tepi selatan lingkaran', () {
    final label = rw.titikLabel!;
    final p = rw.pusat!;
    expect(label.latitude, lessThan(p.latitude));
    expect(label.longitude, closeTo(p.longitude, 1e-6));
    expect(
      const Distance().as(LengthUnit.Meter, p, label),
      closeTo(rw.radiusMeter, 2),
    );
  });

  test('RW tanpa poligon tidak digambar', () {
    const kosong = RwRisk(
      rwId: '1',
      nama: 'RW 01',
      skor: 0,
      level: LevelRisiko.aman,
      polygon: [],
    );
    expect(kosong.pusat, isNull);
    expect(kosong.radiusMeter, 0);
    expect(kosong.titikLabel, isNull);
  });

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
