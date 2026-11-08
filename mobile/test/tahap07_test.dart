import 'package:flutter_test/flutter_test.dart';
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
}
