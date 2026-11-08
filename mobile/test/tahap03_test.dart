import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/verification.dart';
import 'package:rivora/services/api_client.dart';

void main() {
  group('LevelRisiko (batas RENCANA_FINAL bagian 4)', () {
    test('aman < 0,40 · waspada < 0,70 · risiko tinggi ≥ 0,70', () {
      expect(LevelRisiko.dariSkor(0.0), LevelRisiko.aman);
      expect(LevelRisiko.dariSkor(0.399), LevelRisiko.aman);
      expect(LevelRisiko.dariSkor(0.40), LevelRisiko.waspada);
      expect(LevelRisiko.dariSkor(0.699), LevelRisiko.waspada);
      expect(LevelRisiko.dariSkor(0.70), LevelRisiko.risikoTinggi);
      expect(LevelRisiko.dariSkor(1.0), LevelRisiko.risikoTinggi);
    });
  });

  group('VerificationResult', () {
    test('membaca respons lengkap: verifikasi, tugas, skor RW', () {
      final r = VerificationResult.fromJson({
        'verifikasi': {
          'sudah_bersih': true,
          'kelas_sesudah': 'bersih',
          'skor_sumbatan_sesudah': 0.08,
          'keyakinan': 'tinggi',
          'catatan': 'Bersih',
        },
        'tugas': {
          'id': 7,
          'status': 'selesai',
          'created_at': '2026-11-08T02:30:00Z',
          'saluran': {'jenis_saluran': 'terbuka', 'lat': -6.94, 'lng': 107.69},
          'laporan': {
            'id': 42,
            'ai': {'kelas_sumbatan': 'berat', 'saluran_terlihat': true},
          },
        },
        'rw': {'nama': 'RW 05', 'skor_sebelum': 0.78, 'skor_sesudah': 0.41},
        'foto_sesudah_url': 'https://contoh/7.jpg',
      });
      expect(r.sudahBersih, isTrue);
      expect(r.kelasSesudah, KelasSumbatan.bersih);
      expect(r.tugas!.selesai, isTrue);
      expect(r.adaPerubahanSkor, isTrue);
      expect(LevelRisiko.dariSkor(r.skorRwSebelum!), LevelRisiko.risikoTinggi);
      expect(LevelRisiko.dariSkor(r.skorRwSesudah!), LevelRisiko.waspada);
    });

    test('respons datar tanpa pembungkus "verifikasi" juga diterima', () {
      final r = VerificationResult.fromJson({
        'sudah_bersih': false,
        'kelas_sesudah': 'sedang',
        'keyakinan': 'sedang',
      });
      expect(r.sudahBersih, isFalse);
      expect(r.kelasSesudah, KelasSumbatan.sedang);
      expect(r.adaPerubahanSkor, isFalse);
      expect(r.tugas, isNull);
    });
  });

  group('MockApiClient verifikasi', () {
    MockApiClient buat() => MockApiClient(
      delay: Duration.zero,
      listDelay: Duration.zero,
      tugasBaruSetelah: const Duration(days: 1),
    );

    Future<VerificationResult> verifikasi(MockApiClient c, String id) =>
        c.verifyTask(
          taskId: id,
          foto: File('sesudah.jpg'),
          lat: -6.94,
          lng: 107.69,
          capturedAt: DateTime.utc(2026, 11, 8, 3),
        );

    test(
      't2 bersih: tugas selesai, skor RW turun, laporan warga ditangani',
      () async {
        final c = buat();
        final hasil = await verifikasi(c, 't2');
        expect(hasil.sudahBersih, isTrue);
        expect(hasil.tugas!.selesai, isTrue);
        expect(hasil.skorRwSesudah!, lessThan(hasil.skorRwSebelum!));

        final laporan = (await c.myReports()).firstWhere(
          (r) => r.id == 'contoh-102',
        );
        expect(laporan.sudahDitangani, isTrue);
        expect(laporan.ditanganiAt, isNotNull);
      },
    );

    test(
      't3 gagal di percobaan pertama, berhasil di percobaan kedua',
      () async {
        final c = buat();
        final pertama = await verifikasi(c, 't3');
        expect(pertama.sudahBersih, isFalse);
        expect(pertama.tugas!.status, 'dikerjakan');

        final kedua = await verifikasi(c, 't3');
        expect(kedua.sudahBersih, isTrue);
        expect(kedua.tugas!.selesai, isTrue);
      },
    );

    test('tugas yang tidak ada ditolak', () async {
      expect(
        () => verifikasi(buat(), 'tidak-ada'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  test(
    'tugas baru contoh muncul setelah jeda (untuk demo notifikasi)',
    () async {
      final c = MockApiClient(
        delay: Duration.zero,
        listDelay: Duration.zero,
        tugasBaruSetelah: const Duration(milliseconds: 30),
      );
      final awal = await c.myTasks();
      expect(awal.any((t) => t.id == 't5'), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final nanti = await c.myTasks();
      expect(nanti.any((t) => t.id == 't5'), isTrue);
    },
  );
}
