import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/models/report.dart';

void main() {
  group('AiResult', () {
    test('membaca contoh Lampiran C proposal', () {
      final ai = AiResult.fromJson({
        'jenis_saluran': 'terbuka',
        'saluran_terlihat': true,
        'kelas_sumbatan': 'berat',
        'skor_sumbatan': 0.85,
        'penyebab': ['plastik', 'sedimen'],
        'keyakinan': 'tinggi',
        'catatan': 'Sampah plastik menutupi sebagian besar lebar saluran',
      });

      expect(ai.kelas, KelasSumbatan.berat);
      expect(ai.skorSumbatan, 0.85);
      expect(ai.penyebab, ['plastik', 'sedimen']);
      expect(ai.keyakinan, 'tinggi');
      expect(ai.perluCekManual, isFalse);
    });

    test('saluran tidak terlihat masuk jalur cek manual', () {
      final ai = AiResult.fromJson({
        'saluran_terlihat': false,
        'kelas_sumbatan': 'tidak_terlihat',
        'skor_sumbatan': null,
        'penyebab': <String>[],
        'keyakinan': 'rendah',
        'catatan': '',
      });

      expect(ai.kelas, KelasSumbatan.tidakTerlihat);
      expect(ai.skorSumbatan, isNull);
      expect(ai.perluCekManual, isTrue);
    });

    test('kelas tidak dikenal dianggap tidak terlihat, bukan bersih', () {
      final ai = AiResult.fromJson({
        'saluran_terlihat': true,
        'kelas_sumbatan': 'parah_banget',
        'keyakinan': 'sedang',
      });

      expect(ai.kelas, KelasSumbatan.tidakTerlihat);
      expect(ai.perluCekManual, isTrue);
    });
  });

  test('Report menerima id angka dari Postgres', () {
    final report = Report.fromJson({
      'id': 42,
      'status': 'dikirim',
      'jenis_saluran': 'gorong_gorong',
      'lat': -6.94,
      'lng': 107.69,
      'captured_at': '2026-11-08T02:30:00Z',
      'ai': {
        'saluran_terlihat': true,
        'kelas_sumbatan': 'sedang',
        'skor_sumbatan': 0.5,
        'penyebab': ['daun_ranting'],
        'keyakinan': 'sedang',
        'catatan': '',
      },
    });

    expect(report.id, '42');
    expect(report.jenisSaluran, JenisSaluran.gorongGorong);
    expect(report.capturedAt.isUtc, isFalse);
  });
}
