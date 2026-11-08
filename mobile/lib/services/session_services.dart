import 'dart:async';

import 'package:flutter/foundation.dart';

import 'push_service.dart';
import 'repositories.dart';
import 'session_store.dart';
import 'task_watcher.dart';

/// Satu-satunya pemilik layanan petugas: daftar tugas, cek tugas berkala,
/// dan push FCM. Mengikuti [sessionStore], bukan siklus hidup widget.
///
/// Dulu `AppShell` yang menyalakan dan mematikannya. Saat warga masuk
/// sebagai petugas, shell warga lama baru di-dispose *sesudah* shell
/// petugas dibuat, lalu ikut mematikan cek berkala dan push milik sesi
/// baru. Di sini perubahan sesi diproses sekali, berurutan.
class SessionServices {
  String? _tokenAktif;
  bool _terpasang = false;
  Future<void> _antreanPush = Future<void>.value();

  /// Mulai mengikuti sesi. Aman dipanggil berkali-kali.
  void attach() {
    if (_terpasang) return;
    _terpasang = true;
    sessionStore.addListener(_ikutiSesi);
    _ikutiSesi();
  }

  void _ikutiSesi() {
    final s = sessionStore.value;
    final token = (s?.isPetugas ?? false) ? s!.token : null;
    if (token == _tokenAktif) return;
    final adaSesiLama = _tokenAktif != null;
    _tokenAktif = token;
    if (adaSesiLama) {
      // Semua jalur sesi berakhir: tombol Keluar maupun 401 dari server.
      taskWatcher.stop();
      taskRepository.clear();
      _push(pushService.stop);
    }
    if (token != null) {
      taskRepository.refresh();
      taskWatcher.start();
      _push(pushService.start);
    }
  }

  /// Push start/stop dijalankan berurutan: token FCM sesi lama selesai
  /// dihapus dulu sebelum sesi baru mendaftar.
  void _push(Future<void> Function() langkah) {
    _antreanPush = _antreanPush.then((_) => langkah()).catchError((Object e) {
      debugPrint('Push gagal diperbarui: $e');
    });
  }

  /// Selesai saat semua perubahan push yang diantre sudah dijalankan.
  Future<void> get selesai => _antreanPush;
}

final sessionServices = SessionServices();
