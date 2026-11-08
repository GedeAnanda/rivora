import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/models/ai_result.dart';
import 'package:rivora/models/verification.dart';
import 'package:rivora/services/api_client.dart';
import 'package:rivora/services/push_service.dart';

/// Tahap 07: FCM dan mode lokasi demo.
void main() {
  group('payload notifikasi tugas baru', () {
    test('backend SRS bagian 11: data.type', () {
      final data = {'type': 'tugas_baru', 'tugas_id': '12', 'saluran_id': '7'};
      expect(notifikasiTugasBaru(data), isTrue);
      expect(tugasIdDariNotifikasi(data), '12');
    });

    test('implementasi backend (notify/fcm.js): data.jenis', () {
      final data = {
        'jenis': 'tugas_baru',
        'tugas_id': '12',
        'saluran_id': '7',
        'lat': '-6.94',
        'lng': '107.69',
      };
      expect(notifikasiTugasBaru(data), isTrue);
      expect(tugasIdDariNotifikasi(data), '12');
    });

    test('pesan lain tidak membuka tugas', () {
      expect(notifikasiTugasBaru({'type': 'pengumuman'}), isFalse);
      expect(tugasIdDariNotifikasi({'type': 'pengumuman'}), isNull);
      expect(tugasIdDariNotifikasi(<String, dynamic>{}), isNull);
    });

    test('tugas_id kosong tetap aman', () {
      expect(tugasIdDariNotifikasi({'jenis': 'tugas_baru'}), isNull);
    });
  });

  group('verifikasi: AI tidak bisa menilai', () {
    final tugas = {
      'id': 12,
      'status': 'dikerjakan',
      'saluran': {
        'id': 7,
        'jenis': 'terbuka',
        'rw_nama': 'RW 05',
        'lat': -6.94,
        'lng': 107.69,
      },
      'kelas_sebelum': 'berat',
      'dibuat_at': '2026-11-08T05:00:00Z',
    };

    test('backend routes/tasks.js: ai_sumber "gagal" + objek cadangan', () {
      final r = VerificationResult.fromJson({
        'tugas': tugas,
        'verifikasi': {
          'sudah_bersih': false,
          'kelas_sesudah': 'tidak_terlihat',
          'skor_sumbatan_sesudah': null,
          'keyakinan': 'rendah',
          'catatan': 'Penilaian AI gagal, perlu dicek manual oleh lurah',
        },
        'ai_sumber': 'gagal',
      });
      expect(r.dinilai, isFalse);
      expect(r.sudahBersih, isFalse);
      // Catatan untuk lurah tidak ditampilkan ke petugas.
      expect(r.pesan, isNull);
      expect(r.tugas!.selesai, isFalse);
    });

    test('model menjawab tidak_terlihat: pakai catatan AI sebagai pesan', () {
      final r = VerificationResult.fromJson({
        'tugas': tugas,
        'verifikasi': {
          'sudah_bersih': false,
          'kelas_sesudah': 'tidak_terlihat',
          'keyakinan': 'sedang',
          'catatan': 'Foto terlalu gelap, dasar saluran tidak terlihat',
        },
        'ai_sumber': 'model',
      });
      expect(r.dinilai, isFalse);
      expect(r.pesan, startsWith('Foto terlalu gelap'));
    });

    test('SRS 7.10: verifikasi null', () {
      final r = VerificationResult.fromJson({
        'tugas': tugas,
        'verifikasi': null,
        'ai_sumber': 'model',
      });
      expect(r.dinilai, isFalse);
    });

    test('penilaian normal tetap dinilai', () {
      final masihKotor = VerificationResult.fromJson({
        'tugas': tugas,
        'verifikasi': {
          'sudah_bersih': false,
          'kelas_sesudah': 'sedang',
          'skor_sumbatan_sesudah': 0.42,
          'keyakinan': 'tinggi',
          'catatan': 'Masih ada sedimen',
        },
        'ai_sumber': 'model',
      });
      expect(masihKotor.dinilai, isTrue);
      expect(masihKotor.sudahBersih, isFalse);
      expect(masihKotor.kelasSesudah, KelasSumbatan.sedang);

      final bersih = VerificationResult.fromJson({
        'tugas': {...tugas, 'status': 'selesai'},
        'verifikasi': {'sudah_bersih': true, 'kelas_sesudah': 'bersih'},
        'ai_sumber': 'demo',
      });
      expect(bersih.dinilai, isTrue);
      expect(bersih.sudahBersih, isTrue);
      expect(bersih.hasilDemo, isTrue);
    });
  });

  test('mode contoh: t5 gagal dinilai dulu, lalu berhasil', () async {
    final c = MockApiClient(
      delay: Duration.zero,
      listDelay: Duration.zero,
      tugasBaruSetelah: Duration.zero,
    );
    await c.myTasks(); // memunculkan t5
    Future<VerificationResult> kirim() => c.verifyTask(
      taskId: 't5',
      foto: File('sesudah.jpg'),
      lat: -6.9432,
      lng: 107.6881,
      capturedAt: DateTime.utc(2026, 11, 8, 7),
    );
    final pertama = await kirim();
    expect(pertama.dinilai, isFalse);
    expect(pertama.tugas!.status, 'dikerjakan');
    final kedua = await kirim();
    expect(kedua.dinilai, isTrue);
    expect(kedua.tugas!.selesai, isTrue);
  });
}
