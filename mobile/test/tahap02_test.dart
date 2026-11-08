import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/models/report.dart';
import 'package:rivora/models/task.dart';
import 'package:rivora/services/api_client.dart';
import 'package:rivora/utils/format.dart';

void main() {
  group('Report timeline', () {
    test('membaca field ditugaskan/ditangani dan foto bukti', () {
      final r = Report.fromJson({
        'id': 1,
        'status': 'ditangani',
        'jenis_saluran': 'terbuka',
        'lat': -6.94,
        'lng': 107.69,
        'captured_at': '2026-11-07T01:00:00Z',
        'ditugaskan_at': '2026-11-07T02:00:00Z',
        'ditangani_at': '2026-11-07T05:00:00Z',
        'petugas_nama': 'Dedi',
        'foto_sesudah_url': 'https://contoh/1-sesudah.jpg',
        'rw': 'RW 05',
        'ai': {'kelas_sumbatan': 'berat', 'saluran_terlihat': true},
      });
      expect(r.sudahDitangani, isTrue);
      expect(r.petugasNama, 'Dedi');
      expect(r.fotoSesudahUrl, isNotNull);
      expect(r.ditanganiAt!.isAfter(r.ditugaskanAt!), isTrue);
    });

    test('field timeline boleh tidak ada', () {
      final r = Report.fromJson({
        'id': 'a',
        'jenis_saluran': 'inlet_jalan',
        'lat': 0,
        'lng': 0,
        'captured_at': '2026-11-08T01:00:00Z',
        'ai': {'kelas_sumbatan': 'ringan', 'saluran_terlihat': true},
      });
      expect(r.status, 'dikirim');
      expect(r.ditugaskanAt, isNull);
      expect(r.rw, isNull);
    });
  });

  test('Task membaca saluran dan laporan bersarang', () {
    final t = Task.fromJson({
      'id': 7,
      'status': 'baru',
      'created_at': '2026-11-08T02:00:00Z',
      'skor_prioritas': 0.82,
      'rw': 'RW 05',
      'saluran': {
        'jenis_saluran': 'gorong_gorong',
        'lat': -6.94,
        'lng': 107.69,
      },
      'laporan': {
        'id': 42,
        'foto_url': 'https://contoh/42.jpg',
        'ai': {'kelas_sumbatan': 'berat', 'saluran_terlihat': true},
      },
    });
    expect(t.id, '7');
    expect(t.jenisSaluran, JenisSaluran.gorongGorong);
    expect(t.ai.kelas, KelasSumbatan.berat);
    expect(t.laporanId, '42');
    expect(t.selesai, isFalse);
  });

  group('MockApiClient tahap 02', () {
    final client = MockApiClient(
      delay: Duration.zero,
      listDelay: Duration.zero,
    );

    test('login menentukan peran dari nama pengguna', () async {
      expect((await client.login('petugas', 'x')).isPetugas, isTrue);
      expect((await client.login('warga01', 'x')).role, 'warga');
      expect((await client.login('lurah', 'x')).role, 'lurah');
      expect(() => client.login('  ', 'x'), throwsA(isA<ApiException>()));
    });

    test('laporan yang dikirim muncul paling atas di laporan saya', () async {
      final before = await client.myReports();
      final sent = await client.submitReport(
        foto: File('contoh.jpg'),
        lat: -6.94,
        lng: 107.69,
        capturedAt: DateTime.utc(2026, 11, 8),
        jenisSaluran: JenisSaluran.terbuka,
      );
      final after = await client.myReports();
      expect(after.length, before.length + 1);
      expect(after.first.id, sent.id);
    });

    test('tugas contoh punya prioritas dan satu tugas selesai', () async {
      final tasks = await client.myTasks();
      expect(tasks, isNotEmpty);
      expect(tasks.where((t) => t.selesai), hasLength(1));
      expect(tasks.every((t) => t.skorPrioritas != null), isTrue);
    });
  });

  group('format', () {
    final now = DateTime(2026, 11, 8, 12, 0);
    test('formatRelatif', () {
      expect(
        formatRelatif(now.subtract(const Duration(seconds: 20)), now: now),
        'baru saja',
      );
      expect(
        formatRelatif(now.subtract(const Duration(minutes: 12)), now: now),
        '12 menit lalu',
      );
      expect(
        formatRelatif(now.subtract(const Duration(hours: 3)), now: now),
        '3 jam lalu',
      );
      expect(
        formatRelatif(DateTime(2026, 11, 7, 20, 5), now: now),
        'kemarin, 20:05',
      );
    });

    test('formatJarak', () {
      expect(formatJarak(350.4), '350 m');
      expect(formatJarak(1234), '1,2 km');
    });
  });
}
