import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config.dart';
import 'repositories.dart';

/// Memeriksa tugas baru secara berkala selama aplikasi terbuka, dan
/// langsung saat aplikasi kembali dibuka. Ini jalur notifikasi yang selalu
/// jalan, juga tanpa Firebase; push FCM (PushService) mempercepatnya.
class TaskWatcher with WidgetsBindingObserver {
  Timer? _timer;
  bool _resumed = true;

  /// Mode contoh lebih sering supaya notifikasi cepat terlihat saat demo.
  static Duration get interval => AppConfig.useMockApi
      ? const Duration(seconds: 10)
      : const Duration(seconds: 30);

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(interval, (_) {
      if (_resumed) checkNow();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<void> checkNow() => taskRepository.refresh(silent: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) checkNow();
  }
}

final taskWatcher = TaskWatcher();
