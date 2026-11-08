import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rivora/main.dart';
import 'package:rivora/models/report.dart';
import 'package:rivora/services/api_client.dart';
import 'package:rivora/services/location_service.dart';
import 'package:rivora/services/push_service.dart';
import 'package:rivora/services/repositories.dart';
import 'package:rivora/services/session_store.dart';
import 'package:rivora/services/task_watcher.dart';
import 'package:rivora/theme/app_theme.dart';
import 'package:rivora/widgets/report_photo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tahap 13: perbaikan temuan audit alur (sesi, laporan, GPS, respons).
class _TanpaLokasi extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
}

class _GpsTimeout extends GeolocatorPlatform {
  _GpsTimeout(this.terakhir);

  final Position terakhir;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  /// Habis waktu seperti geolocator dengan `timeLimit`.
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      Future<Position>.error(TimeoutException('GPS habis waktu'));

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => terakhir;
}

Position _posisi({required Duration umur, required double akurasi}) => Position(
  longitude: 107.689,
  latitude: -6.943,
  timestamp: DateTime.now().subtract(umur),
  accuracy: akurasi,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Sesi petugas (audit #1, #4)', () {
    testWidgets('warga masuk petugas: cek berkala tetap jalan; sesi '
        'berakhir mematikannya dan mengosongkan tugas', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.path,
          );
      final asli = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _TanpaLokasi();
      addTearDown(() => GeolocatorPlatform.instance = asli);

      await tester.pumpWidget(const RivoraApp());
      await tester.pump(const Duration(seconds: 1));
      expect(taskWatcher.aktif, isFalse);

      final masuk = sessionStore.login('petugas1', 'x');
      await tester.pump(const Duration(seconds: 3));
      await masuk;
      // Frame ini membuat shell petugas lalu men-dispose shell warga.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(taskWatcher.aktif, isTrue);
      expect(taskRepository.items, isNotEmpty);

      // Sesi berakhir (sama untuk tombol Keluar dan 401). keluar() juga
      // menunggu token FCM dihapus; plugin Firebase tidak ada di tes, jadi
      // di sini cukup logout.
      final logout = sessionStore.logout();
      await tester.pump();
      await logout;
      await tester.pump();
      expect(taskWatcher.aktif, isFalse);
      expect(taskRepository.items, isEmpty);

      // Biarkan muat laporan/cuaca shell warga yang baru selesai.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpWidget(const SizedBox());
    });

    test('respons dari sesi lama dibuang setelah clear', () async {
      final repo = TaskRepository();
      final berjalan = repo.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      repo.clear();
      await berjalan;
      expect(repo.items, isEmpty);
      // Sesi baru tidak terhalang permintaan lama.
      await repo.refresh();
      expect(repo.items, isNotEmpty);
    });

    test('refresh saat masih memuat mengembalikan permintaan yang sama '
        '(audit #8: ketuk notifikasi menunggu hasilnya)', () async {
      final repo = TaskRepository();
      final a = repo.refresh();
      final b = repo.refresh(silent: true);
      expect(identical(a, b), isTrue);
      await a;
      expect(repo.items, isNotEmpty);
    });
  });

  test('laporan yang dikirim saat refresh berjalan tidak hilang '
      '(audit #2)', () async {
    final repo = ReportRepository();
    await repo.load();
    final baru = Report.fromJson({
      ...repo.items.first.toJson(),
      'id': 'laporan-baru',
    });
    final berjalan = repo.refresh();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    repo.addSubmitted(baru, File('/tmp/rivora-tes.jpg'));
    await berjalan;
    expect(repo.byId('laporan-baru'), isNotNull);
    expect(repo.items.length, 3);
  });

  group('Lokasi foto (audit #3)', () {
    test('posisi cadangan harus segar dan akurat', () {
      expect(
        LocationService.layak(
          _posisi(umur: const Duration(seconds: 30), akurasi: 12),
        ),
        isTrue,
      );
      expect(
        LocationService.layak(
          _posisi(umur: const Duration(days: 1), akurasi: 12),
        ),
        isFalse,
      );
      expect(
        LocationService.layak(
          _posisi(umur: const Duration(seconds: 30), akurasi: 500),
        ),
        isFalse,
      );
    });

    test('GPS habis waktu + posisi terakhir sehari lalu → ditolak', () async {
      final asli = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _GpsTimeout(
        _posisi(umur: const Duration(days: 1), akurasi: 500),
      );
      addTearDown(() => GeolocatorPlatform.instance = asli);
      await expectLater(
        LocationService().currentPosition(),
        throwsA(isA<LocationException>()),
      );
    });

    test('GPS habis waktu + posisi terakhir 30 detik lalu → dipakai', () async {
      final asli = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _GpsTimeout(
        _posisi(umur: const Duration(seconds: 30), akurasi: 10),
      );
      addTearDown(() => GeolocatorPlatform.instance = asli);
      final p = await LocationService().currentPosition();
      expect(p.accuracy, 10);
    });
  });

  group('Respons server (audit #10)', () {
    HttpApiClient klien(http.Response respons) => HttpApiClient(
      'https://contoh.invalid',
      client: MockClient((_) async => respons),
    );

    test('HTTP 200 berisi HTML → ApiException, bukan daftar kosong', () async {
      await expectLater(
        klien(http.Response('<html>proxy</html>', 200)).myTasks(),
        throwsA(isA<ApiException>()),
      );
    });

    test('HTTP 200 kosong untuk daftar tugas → ApiException', () async {
      await expectLater(
        klien(http.Response('', 200)).myTasks(),
        throwsA(isA<ApiException>()),
      );
    });

    test('bentuk JSON salah → ApiException, bukan TypeError', () async {
      await expectLater(
        klien(http.Response('[1, 2]', 200)).getReport('1'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        klien(http.Response('{"data": "x"}', 200)).myTasks(),
        throwsA(isA<ApiException>()),
      );
    });

    test('operasi tanpa isi (201/204 kosong) tetap berhasil', () async {
      await klien(http.Response('', 204)).registerDevice('token');
    });
  });

  group('Notifikasi diketuk sebelum shell siap (audit #8)', () {
    test('disimpan lalu diteruskan saat callback dipasang', () async {
      final push = PushService()..terimaKetukan('7');
      String? dibuka;
      push.onOpenTask = (id) => dibuka = id;
      await Future<void>.delayed(Duration.zero);
      expect(dibuka, '7');
    });

    test('callback sudah ada → langsung dipanggil', () {
      String? dibuka;
      final push = PushService()..onOpenTask = (id) => dibuka = id;
      push.terimaKetukan('9');
      expect(dibuka, '9');
    });
  });

  testWidgets('file foto lokal hilang → pakai foto server (audit #9)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRivoraTheme(Brightness.light),
        home: ReportPhoto(
          file: File('/tmp/rivora-tidak-ada-${DateTime.now().microsecond}.jpg'),
          url: 'https://contoh.invalid/foto.jpg',
          width: 100,
          height: 100,
          semanticLabel: 'Foto saluran',
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is NetworkImage),
      findsOneWidget,
    );
  });
}
