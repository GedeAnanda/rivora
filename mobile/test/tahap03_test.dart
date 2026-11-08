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

  group('VerificationResult (backend SRS 7.10)', () {
    final tugas = {
      'id': 7,
      'status': 'selesai',
      'saluran': {
        'id': 31,
        'jenis': 'terbuka',
        'rw_nama': 'RW 05',
        'lat': -6.94,
        'lng': 107.69,
      },
      'kelas_sebelum': 'berat',
      'dibuat_at': '2026-11-08T02:30:00Z',
    };

    test('membaca verifikasi + tugas, skor RW ditambahkan app', () {
      final mentah = VerificationResult.fromJson({
        'tugas': tugas,
        'verifikasi': {
          'sudah_bersih': true,
          'kelas_sesudah': 'bersih',
          'skor_sumbatan_sesudah': 0.08,
          'keyakinan': 'tinggi',
          'catatan': 'Bersih',
        },
        'ai_sumber': 'model',
      });
      expect(mentah.dinilai, isTrue);
      expect(mentah.sudahBersih, isTrue);
      expect(mentah.kelasSesudah, KelasSumbatan.bersih);
      expect(mentah.tugas!.selesai, isTrue);
      expect(mentah.hasilDemo, isFalse);
      expect(mentah.adaPerubahanSkor, isFalse);

      final r = mentah.denganSkorRw('RW 05', 0.78, 0.41);
      expect(r.rw, 'RW 05');
      expect(r.adaPerubahanSkor, isTrue);
      expect(r.sudahBersih, isTrue);
      expect(LevelRisiko.dariSkor(r.skorRwSebelum!), LevelRisiko.risikoTinggi);
      expect(LevelRisiko.dariSkor(r.skorRwSesudah!), LevelRisiko.waspada);
    });

    test('verifikasi null: belum dinilai, tugas tidak selesai', () {
      final r = VerificationResult.fromJson({
        'tugas': {...tugas, 'status': 'dikerjakan'},
        'verifikasi': null,
        'ai_sumber': 'model',
        'pesan': 'Foto kurang jelas. Coba foto ulang.',
      });
      expect(r.dinilai, isFalse);
      expect(r.sudahBersih, isFalse);
      expect(r.pesan, isNotNull);
      expect(r.tugas!.selesai, isFalse);
    });

    test('ai_sumber demo diberi label', () {
      final r = VerificationResult.fromJson({
        'tugas': tugas,
        'verifikasi': {'sudah_bersih': true, 'kelas_sesudah': 'bersih'},
        'ai_sumber': 'demo',
      });
      expect(r.hasilDemo, isTrue);
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
        final sebelum = (await c.rwRisk(1)).rwBernama('RW 02')!.skor;
        final hasil = await verifikasi(c, 't2');
        expect(hasil.dinilai, isTrue);
        expect(hasil.sudahBersih, isTrue);
        expect(hasil.tugas!.selesai, isTrue);
        final sesudah = (await c.rwRisk(1)).rwBernama('RW 02')!.skor;
        expect(sesudah, lessThan(sebelum));

        final laporan = await c.getReport('contoh-102');
        expect(laporan.sudahDitangani, isTrue);
        expect(laporan.kelasSesudah, KelasSumbatan.bersih);
        expect(laporan.ditanganiAt, isNotNull);
        expect(laporan.petugasNama, 'Dedi');
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
