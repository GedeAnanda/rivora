import 'package:flutter/material.dart';

/// Kunci global untuk menampilkan pemberitahuan dan membuka layar dari
/// luar pohon widget (notifikasi tugas, push FCM).
final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Jumlah layar "fokus" yang sedang terbuka (kamera, verifikasi). Selama
/// > 0, pemberitahuan ditunda supaya tidak menutupi tombol utama.
final layarFokus = ValueNotifier<int>(0);
