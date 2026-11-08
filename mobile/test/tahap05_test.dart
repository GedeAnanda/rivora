import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:rivora/models/jenis_saluran.dart';
import 'package:rivora/models/rw_risk.dart';
import 'package:rivora/models/session.dart';
import 'package:rivora/models/verification.dart';
import 'package:rivora/services/api_client.dart';
import 'package:rivora/services/repositories.dart';
import 'package:rivora/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tahap 05: audit QA. Kontrak backend SRS bagian 7 dan alur mobile SRS.
void main() {
  group('Session (backend SRS 7.1)', () {
    test('membaca pengguna bersarang dan menyimpan bentuk yang sama', () {
      final s = Session.fromJson({
        'token': 'jwt',
        'role': 'petugas',
        'pengguna': {'id': 4, 'nama': 'Dedi', 'kelurahan_id': 1},
      });
      expect(s.nama, 'Dedi');
      expect(s.penggunaId, 4);
      expect(s.kelurahanId, 1);
      expect(s.isPetugas, isTrue);
      final ulang = Session.fromJson(s.toJson());
      expect(ulang.nama, 'Dedi');
      expect(ulang.kelurahanId, 1);
    });

    test('bentuk datar lama tetap terbaca', () {
      final s = Session.fromJson({
        'token': 't',
        'role': 'petugas',
        'nama': 'Lama',
      });
      expect(s.nama, 'Lama');
    });
  });

  group('Masuk petugas (mobile SRS FR-MB-07)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('akun warga dan lurah ditolak, petugas diterima', () async {
      final store = SessionStore();
      await expectLater(
        store.login('warga01', 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Akun ini bukan akun petugas.',
          ),
        ),
      );
      await expectLater(
        store.login('lurah', 'x'),
        throwsA(isA<ApiException>()),
      );
      expect(store.value, isNull);

      await store.login('petugas1', 'x');
      expect(store.value!.isPetugas, isTrue);

      final dimuatUlang = SessionStore();
      await dimuatUlang.load();
      expect(dimuatUlang.value?.nama, 'Dedi');
    });

    test('sesi non-petugas yang tersimpan dibuang saat dimuat', () async {
      SharedPreferences.setMockInitialValues({
        'rivora.session':
            '{"token":"t","role":"warga","pengguna":{"nama":"W"}}',
      });
      final store = SessionStore();
      await store.load();
      expect(store.value, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('rivora.session'), isNull);
    });
  });

  group('Laporan dari HP ini (mobile SRS FR-MB-06)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('tersimpan di HP dan tetap ada setelah app dibuka lagi', () async {
      final repo = ReportRepository();
      await repo.load();
      // Mode contoh: dua laporan contoh diisi sekali.
      expect(repo.items.map((r) => r.id), MockApiClient.idLaporanContoh);

      final baru = await api.submitReport(
        foto: File('contoh.jpg'),
        lat: -6.9500,
        lng: 107.7000,
        capturedAt: DateTime.utc(2026, 11, 8, 2),
        jenisSaluran: JenisSaluran.inletJalan,
      );
      repo.addSubmitted(baru, File('/tmp/foto.jpg'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final dibukaLagi = ReportRepository();
      await dibukaLagi.load();
      expect(dibukaLagi.items.first.id, baru.id);
      expect(dibukaLagi.items.first.jenisSaluran, JenisSaluran.inletJalan);
      expect(dibukaLagi.localPhoto(baru.id)?.path, '/tmp/foto.jpg');
      expect(dibukaLagi.items, hasLength(3));
    });

    test('logout petugas tidak menghapus laporan warga', () async {
      final repo = ReportRepository();
      await repo.load();
      final jumlah = repo.items.length;
      await sessionStore.logout();
      final lagi = ReportRepository();
      await lagi.load();
      expect(lagi.items, hasLength(jumlah));
    });
  });

  group('Risiko RW (backend SRS 7.4, proposal Tabel 4)', () {
    Map<String, dynamic> fitur(
      String nama,
      double skor,
      List<List<double>> c,
    ) => {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [c],
      },
      'properties': {
        'rw_id': nama,
        'nama': nama,
        'skor': skor,
        'level': LevelRisiko.dariSkor(skor).apiValue,
        'komponen': {
          'hujan': {'nilai': 0.5, 'bobot': 0.4},
          'sumbatan': {'nilai': 0.7, 'bobot': 0.4},
          'kerentanan': {'nilai': 0.6, 'bobot': 0.2},
        },
        'alasan': 'contoh',
      },
    };

    // Persegi lng 107.68–107.69, lat -6.95–-6.94 (urutan GeoJSON [lng, lat]).
    final peta = PetaRisiko.fromJson({
      'type': 'FeatureCollection',
      'meta': {'hujan_24j_mm': 50, 'hujan_sumber': 'simulasi_demo'},
      'features': [
        fitur('RW A', 0.72, [
          [107.68, -6.95],
          [107.69, -6.95],
          [107.69, -6.94],
          [107.68, -6.94],
          [107.68, -6.95],
        ]),
      ],
    });

    test('koordinat GeoJSON dibalik ke LatLng dan komponen terbaca', () {
      final rw = peta.rw.single;
      expect(rw.polygon.first, const LatLng(-6.95, 107.68));
      expect(rw.level, LevelRisiko.risikoTinggi);
      expect(rw.sumbatan, 0.7);
      expect(peta.hujanSumber, 'simulasi_demo');
    });

    test('titik di dalam / di luar poligon RW', () {
      expect(peta.rwDiTitik(const LatLng(-6.945, 107.685))?.nama, 'RW A');
      expect(peta.rwDiTitik(const LatLng(-6.935, 107.685)), isNull);
      expect(peta.rwDiTitik(const LatLng(-6.945, 107.70)), isNull);
    });

    test('mock: skor = 0,4 hujan + 0,4 sumbatan + 0,2 kerentanan', () async {
      final c = MockApiClient(delay: Duration.zero, listDelay: Duration.zero);
      final data = await c.rwRisk(1);
      expect(data.rw, isNotEmpty);
      for (final rw in data.rw) {
        final skor =
            0.4 * rw.hujan! + 0.4 * rw.sumbatan! + 0.2 * rw.kerentanan!;
        expect(rw.skor, closeTo(skor, 1e-9));
        expect(rw.level, LevelRisiko.dariSkor(rw.skor));
        expect(rw.alasan, isNotEmpty);
      }
      // Tiap saluran tugas contoh berada di dalam poligon RW-nya.
      for (final t in await c.myTasks()) {
        expect(data.rwDiTitik(LatLng(t.lat, t.lng))?.nama, t.rw);
      }
    });
  });
}
