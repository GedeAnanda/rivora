import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/models/report.dart';
import 'package:rivora/models/task.dart';
import 'package:rivora/services/api_client.dart';
import 'package:rivora/utils/format.dart';

void main() {
  group('Report (backend SRS 7.3)', () {
    test('membaca tugas, bukti, rw_nama, dan label demo', () {
      final r = Report.fromJson({
        'id': 1,
        'status': 'ditangani',
        'jenis_saluran': 'terbuka',
        'lat': -6.94,
        'lng': 107.69,
        'captured_at': '2026-11-07T01:00:00Z',
        'rw_nama': 'RW 05',
        'ai_sumber': 'demo',
        'lokasi_demo': true,
        'digabung': true,
        'tugas': {'id': 9, 'status': 'selesai', 'petugas_nama': 'Dedi'},
        'bukti': {
          'foto_sesudah_url': 'https://contoh/1-sesudah.jpg',
          'kelas_sesudah': 'bersih',
          'selesai_at': '2026-11-07T05:00:00Z',
        },
        'ai': {'kelas_sumbatan': 'berat', 'saluran_terlihat': true},
      });
      expect(r.sudahDitangani, isTrue);
      expect(r.ditugaskan, isTrue);
      expect(r.rw, 'RW 05');
      expect(r.petugasNama, 'Dedi');
      expect(r.fotoSesudahUrl, isNotNull);
      expect(r.kelasSesudah, KelasSumbatan.bersih);
      expect(r.ditanganiAt!.isAfter(r.capturedAt), isTrue);
      expect(r.hasilDemo, isTrue);
      expect(r.lokasiDemo, isTrue);
      expect(r.digabung, isTrue);
    });

    test('field opsional boleh tidak ada', () {
      final r = Report.fromJson({
        'id': 'a',
        'jenis_saluran': 'inlet_jalan',
        'lat': 0,
        'lng': 0,
        'captured_at': '2026-11-08T01:00:00Z',
        'ai': {'kelas_sumbatan': 'ringan', 'saluran_terlihat': true},
      });
      expect(r.status, 'dikirim');
      expect(r.ditugaskan, isFalse);
      expect(r.rw, isNull);
      expect(r.hasilDemo, isFalse);
      expect(r.digabung, isFalse);
    });

    test('toJson lalu fromJson menghasilkan laporan yang sama', () {
      final asal = Report.fromJson({
        'id': 'x1',
        'status': 'ditugaskan',
        'jenis_saluran': 'gorong_gorong',
        'lat': -6.94,
        'lng': 107.69,
        'captured_at': '2026-11-08T01:00:00Z',
        'rw_nama': 'RW 02',
        'tugas': {'status': 'baru', 'petugas_nama': 'Dedi'},
        'ai': {
          'kelas_sumbatan': 'sedang',
          'saluran_terlihat': true,
          'skor_sumbatan': 0.5,
          'penyebab': ['sampah_plastik'],
          'keyakinan': 'sedang',
          'catatan': 'x',
        },
      });
      final ulang = Report.fromJson(asal.toJson());
      expect(ulang.id, asal.id);
      expect(ulang.status, asal.status);
      expect(ulang.jenisSaluran, JenisSaluran.gorongGorong);
      expect(ulang.capturedAt, asal.capturedAt);
      expect(ulang.rw, 'RW 02');
      expect(ulang.petugasNama, 'Dedi');
      expect(ulang.ai.kelas, KelasSumbatan.sedang);
      expect(ulang.ai.penyebab, ['sampah_plastik']);
    });
  });

  test('Task membaca bentuk backend SRS 7.9', () {
    final t = Task.fromJson({
      'id': 7,
      'status': 'baru',
      'saluran': {
        'id': 31,
        'jenis': 'gorong_gorong',
        'rw_nama': 'RW 05',
        'lat': -6.94,
        'lng': 107.69,
      },
      'laporan_id': 42,
      'foto_sebelum_url': 'https://contoh/42.jpg',
      'kelas_sebelum': 'berat',
      'skor_sebelum': 0.82,
      'catatan': 'Prioritas sebelum hujan sore.',
      'dibuat_at': '2026-11-08T02:00:00Z',
      'selesai_at': null,
    });
    expect(t.id, '7');
    expect(t.jenisSaluran, JenisSaluran.gorongGorong);
    expect(t.rw, 'RW 05');
    expect(t.saluranId, '31');
    expect(t.laporanId, '42');
    expect(t.kelasSebelum, KelasSumbatan.berat);
    expect(t.ai.kelas, KelasSumbatan.berat);
    expect(t.skorSebelum, 0.82);
    expect(t.catatanLurah, startsWith('Prioritas'));
    expect(t.createdAt, DateTime.utc(2026, 11, 8, 2).toLocal());
    expect(t.selesai, isFalse);
  });

  group('MockApiClient tahap 02', () {
    MockApiClient buat() => MockApiClient(
      delay: Duration.zero,
      listDelay: Duration.zero,
      tugasBaruSetelah: const Duration(days: 1),
    );

    test('login memakai bentuk respons backend (pengguna.nama)', () async {
      final client = buat();
      final petugas = await client.login('petugas', 'x');
      expect(petugas.isPetugas, isTrue);
      expect(petugas.nama, 'Dedi');
      expect(petugas.kelurahanId, 1);
      expect((await client.login('warga01', 'x')).role, 'warga');
      expect((await client.login('lurah', 'x')).role, 'lurah');
      expect(() => client.login('  ', 'x'), throwsA(isA<ApiException>()));
    });

    test('laporan terkirim bisa diambil lagi lewat getReport', () async {
      final client = buat();
      final sent = await client.submitReport(
        foto: File('contoh.jpg'),
        lat: -6.9500,
        lng: 107.7000,
        capturedAt: DateTime.utc(2026, 11, 8),
        jenisSaluran: JenisSaluran.terbuka,
      );
      final lagi = await client.getReport(sent.id);
      expect(lagi.id, sent.id);
      expect(lagi.rw, isNotNull);
      expect(() => client.getReport('tidak-ada'), throwsA(isA<ApiException>()));
    });

    test('laporan dalam 15 m dari laporan lain ditandai digabung', () async {
      final client = buat();
      // Titik laporan contoh-102 (RW 02).
      final dekat = await client.submitReport(
        foto: File('contoh.jpg'),
        lat: -6.94181,
        lng: 107.68701,
        capturedAt: DateTime.utc(2026, 11, 8),
        jenisSaluran: JenisSaluran.terbuka,
      );
      expect(dekat.digabung, isTrue);
      expect(dekat.rw, 'RW 02');
    });

    test('tugas contoh: skor sebelum, catatan, satu selesai', () async {
      final tasks = await buat().myTasks();
      expect(tasks, isNotEmpty);
      expect(tasks.where((t) => t.selesai), hasLength(1));
      expect(tasks.every((t) => t.skorSebelum != null), isTrue);
      expect(tasks.any((t) => t.catatanLurah != null), isTrue);
    });

    test('Mulai kerjakan mengubah status tugas', () async {
      final client = buat();
      final t = await client.updateTaskStatus('t1', 'dikerjakan');
      expect(t.status, 'dikerjakan');
      final semua = await client.myTasks();
      expect(semua.firstWhere((x) => x.id == 't1').status, 'dikerjakan');
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
