import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/theme/app_theme.dart';
import 'package:rivora/widgets/common.dart';

/// Tahap 09: responsif di HP kecil dan huruf besar.
void main() {
  Future<void> pasang(
    WidgetTester tester, {
    required double lebar,
    double skala = 1,
  }) async {
    tester.view.physicalSize = Size(lebar * 2, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRivoraTheme(Brightness.light),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(lebar, 800),
            textScaler: TextScaler.linear(skala),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TombolBerpasangan(
                sekunder: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Mulai kerjakan'),
                ),
                utama: FilledButton(
                  onPressed: () {},
                  child: const Text('Foto sesudah'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('layar lebar: berdampingan', (tester) async {
    await pasang(tester, lebar: 412);
    final a = tester.getCenter(find.text('Mulai kerjakan'));
    final b = tester.getCenter(find.text('Foto sesudah'));
    expect(a.dy, closeTo(b.dy, 1));
    expect(a.dx, lessThan(b.dx));
  });

  testWidgets('HP kecil: ditumpuk, tombol utama di atas', (tester) async {
    await pasang(tester, lebar: 360);
    final a = tester.getCenter(find.text('Mulai kerjakan'));
    final b = tester.getCenter(find.text('Foto sesudah'));
    expect(b.dy, lessThan(a.dy));
  });

  testWidgets('huruf 130% di layar 412 dp: ditumpuk', (tester) async {
    await pasang(tester, lebar: 412, skala: 1.3);
    final a = tester.getCenter(find.text('Mulai kerjakan'));
    final b = tester.getCenter(find.text('Foto sesudah'));
    expect(b.dy, lessThan(a.dy));
    expect(tester.takeException(), isNull);
  });
}
