import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/verification.dart';
import 'package:rivora/theme/app_theme.dart';
import 'package:rivora/widgets/ai_result_card.dart';
import 'package:rivora/widgets/rain_card.dart';
import 'package:rivora/widgets/risk_meter.dart';
import 'package:rivora/widgets/sumbatan_style.dart';

/// Tahap 06: tampilan ramah warga. Kata dan gambar dulu, angka belakangan.
void main() {
  group('kataWaktu', () {
    final now = DateTime(2026, 11, 8, 12);
    test('bagian hari dalam bahasa sehari-hari', () {
      expect(
        kataWaktu(DateTime(2026, 11, 8, 12, 30), now: now),
        'sebentar lagi',
      );
      expect(kataWaktu(DateTime(2026, 11, 8, 13, 30), now: now), 'nanti siang');
      expect(kataWaktu(DateTime(2026, 11, 8, 16), now: now), 'nanti sore');
      expect(kataWaktu(DateTime(2026, 11, 8, 19), now: now), 'nanti malam');
      expect(kataWaktu(DateTime(2026, 11, 9, 7), now: now), 'besok pagi');
      expect(kataWaktu(DateTime(2026, 11, 9, 2), now: now), 'besok dini hari');
    });
  });

  test('TingkatFaktor: rendah < 0,40 ≤ sedang < 0,70 ≤ tinggi', () {
    expect(TingkatFaktor.dari(0.1), TingkatFaktor.rendah);
    expect(TingkatFaktor.dari(0.4), TingkatFaktor.sedang);
    expect(TingkatFaktor.dari(0.69), TingkatFaktor.sedang);
    expect(TingkatFaktor.dari(0.7), TingkatFaktor.tinggi);
    expect(TingkatFaktor.tinggi.warna, LevelRisiko.risikoTinggi);
  });

  test('setiap kelas sumbatan dan keyakinan punya kalimat', () {
    for (final k in KelasSumbatan.values) {
      expect(kataSumbatan(k), isNotEmpty);
    }
    expect(kataKeyakinan('tinggi'), 'AI yakin');
    expect(kataKeyakinan('sedang'), 'AI cukup yakin');
    expect(kataKeyakinan('rendah'), 'AI kurang yakin');
  });

  Widget bungkus(Widget child) => MaterialApp(
    theme: buildRivoraTheme(Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('kartu AI: kalimat kondisi, tanpa skor 0–1', (tester) async {
    await tester.pumpWidget(
      bungkus(
        const AiResultCard(
          ai: AiResult(
            saluranTerlihat: true,
            kelas: KelasSumbatan.berat,
            skorSumbatan: 0.85,
            penyebab: ['plastik'],
            keyakinan: 'sedang',
            catatan: 'Sampah plastik menutupi saluran',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(kataSumbatan(KelasSumbatan.berat)), findsOneWidget);
    expect(find.text('AI cukup yakin'), findsOneWidget);
    expect(find.textContaining('0–1'), findsNothing);
    expect(find.textContaining('0,85'), findsNothing);
    // Keyakinan bukan "tinggi": warga diberi tahu ada pengecekan petugas.
    expect(find.textContaining('Petugas kelurahan'), findsOneWidget);
  });

  testWidgets('meteran risiko menyebut level, bukan angka', (tester) async {
    await tester.pumpWidget(bungkus(const RiskMeter(skor: 0.72)));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Tingkat risiko Risiko tinggi'),
      findsOneWidget,
    );
    expect(find.text('Aman'), findsOneWidget);
    expect(find.text('Waspada'), findsOneWidget);
    expect(find.text('Tinggi'), findsOneWidget);

    await tester.pumpWidget(bungkus(const RiskMeter(dari: 0.54, skor: 0.35)));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Tingkat risiko berubah dari Waspada ke Aman'),
      findsOneWidget,
    );
  });
}
