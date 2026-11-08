import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/services/api_client.dart';

void main() {
  test(
    'MockApiClient bergiliran: berat, sedang, tidak terlihat, bersih',
    () async {
      final client = MockApiClient(delay: Duration.zero);
      final kelas = <KelasSumbatan>[];
      final status = <String>[];

      for (var i = 0; i < 4; i++) {
        final report = await client.submitReport(
          foto: File('contoh.jpg'),
          lat: -6.94,
          lng: 107.69,
          capturedAt: DateTime.utc(2026, 11, 8, 2, 30),
          jenisSaluran: JenisSaluran.inletJalan,
        );
        kelas.add(report.ai.kelas);
        status.add(report.status);
        expect(report.jenisSaluran, JenisSaluran.inletJalan);
      }

      expect(kelas, [
        KelasSumbatan.berat,
        KelasSumbatan.sedang,
        KelasSumbatan.tidakTerlihat,
        KelasSumbatan.bersih,
      ]);
      expect(status, ['dikirim', 'dikirim', 'cek_manual', 'dikirim']);
    },
  );
}
