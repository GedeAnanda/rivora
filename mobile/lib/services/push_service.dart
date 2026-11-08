import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'repositories.dart';
import 'task_watcher.dart';

/// Notifikasi push lewat Firebase Cloud Messaging (proposal Tabel 12).
///
/// Aktif hanya kalau `android/app/google-services.json` ada saat build.
/// Tanpa itu `Firebase.initializeApp()` gagal, [enabled] tetap `false`,
/// dan aplikasi memakai [TaskWatcher] (cek berkala) sebagai pengganti.
/// `tugas_id` kalau [data] adalah notifikasi tugas baru, selain itu `null`.
///
/// Backend SRS bagian 11 memakai `type: "tugas_baru"`, implementasi backend
/// (`notify/fcm.js`) memakai `jenis: "tugas_baru"`. Keduanya diterima.
String? tugasIdDariNotifikasi(Map<String, dynamic> data) {
  final jenis = data['type'] ?? data['jenis'];
  if (jenis != 'tugas_baru') return null;
  final id = data['tugas_id'];
  return id?.toString();
}

/// `true` kalau [data] adalah notifikasi tugas baru.
bool notifikasiTugasBaru(Map<String, dynamic> data) =>
    (data['type'] ?? data['jenis']) == 'tugas_baru';

class PushService {
  bool _enabled = false;
  bool _started = false;
  final List<StreamSubscription<Object?>> _subs = [];

  bool get enabled => _enabled;

  /// Dipanggil saat pengguna membuka notifikasi "tugas baru" dari luar
  /// aplikasi. Argumen = `data.tugas_id` (mobile SRS FR-MB-09).
  void Function(String? tugasId)? onOpenTask;

  /// Dipanggil saat pesan masuk ketika aplikasi sedang terbuka.
  void Function(String title, String body)? onForegroundMessage;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } on Exception catch (e) {
      debugPrint('FCM nonaktif (google-services.json belum ada): $e');
      return;
    }
    _enabled = true;

    final messaging = FirebaseMessaging.instance;
    // Android 13+ menampilkan dialog izin notifikasi.
    await messaging.requestPermission();

    // Sengaja memakai registration token (API lama), bukan register()/FID:
    // backend mengirim lewat firebase-admin `messaging.send({ token })`.
    // ignore: deprecated_member_use
    final token = await messaging.getToken();
    if (token != null) await _register(token);
    // ignore: deprecated_member_use
    _subs.add(messaging.onTokenRefresh.listen(_register));

    _subs.add(
      FirebaseMessaging.onMessage.listen((message) {
        // Data terbaru: tugas baru akan memicu notifikasi di dalam app
        // lewat taskRepository.tugasMasuk.
        taskWatcher.checkNow();
        reportRepository.refresh(silent: true);
        final n = message.notification;
        if (n != null && !notifikasiTugasBaru(message.data)) {
          onForegroundMessage?.call(n.title ?? 'RIVORA', n.body ?? '');
        }
      }),
    );
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_buka));
    final initial = await messaging.getInitialMessage();
    if (initial != null) _buka(initial);
  }

  /// Payload backend: `data.type` (atau `data.jenis`) = `"tugas_baru"`,
  /// `data.tugas_id`. Pesan lain cukup membuka aplikasi.
  void _buka(RemoteMessage m) =>
      onOpenTask?.call(tugasIdDariNotifikasi(m.data));

  Future<void> _register(String token) async {
    try {
      await api.registerDevice(token);
    } on ApiException catch (e) {
      debugPrint('Token FCM gagal disimpan: ${e.message}');
    }
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _started = false;
    if (_enabled) {
      // Token lama tidak boleh menerima notifikasi untuk pengguna berikutnya.
      try {
        // ignore: deprecated_member_use
        await FirebaseMessaging.instance.deleteToken();
      } on Exception catch (e) {
        debugPrint('Token FCM gagal dihapus: $e');
      }
    }
    _enabled = false;
  }
}

final pushService = PushService();
