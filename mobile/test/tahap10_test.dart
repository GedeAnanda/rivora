import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/theme/app_theme.dart';
import 'package:rivora/widgets/ai_result_card.dart';

/// Tahap 10: temuan uji ujung ke ujung dengan backend dan AI asli.
void main() {
  Widget bungkus(Widget child) => MaterialApp(
    theme: buildRivoraTheme(Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('foto bukan saluran: bagian Penyebab disembunyikan', (
    tester,
  ) async {
    await tester.pumpWidget(
      bungkus(
        const AiResultCard(
          ai: AiResult(
            saluranTerlihat: false,
            kelas: KelasSumbatan.tidakTerlihat,
            skorSumbatan: null,
            penyebab: [],
            keyakinan: 'tinggi',
            catatan:
                'Foto ini bukan saluran drainase, melainkan ruang dalam '
                'rumah dengan televisi.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Penyebab'), findsNothing);
    expect(find.text('Tidak ada penyebab dominan'), findsNothing);
    expect(find.textContaining('bukan saluran drainase'), findsOneWidget);
  });

  testWidgets('foto saluran: bagian Penyebab tetap tampil', (tester) async {
    await tester.pumpWidget(
      bungkus(
        const AiResultCard(
          ai: AiResult(
            saluranTerlihat: true,
            kelas: KelasSumbatan.berat,
            skorSumbatan: 0.8,
            penyebab: ['plastik'],
            keyakinan: 'tinggi',
            catatan: 'Sampah plastik menutupi saluran',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Penyebab'), findsOneWidget);
    expect(find.text('Plastik'), findsOneWidget);
  });
}
