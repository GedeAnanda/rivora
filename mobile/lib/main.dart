import 'package:flutter/material.dart';

import 'app_keys.dart';
import 'models/session.dart';
import 'screens/app_shell.dart';
import 'services/session_services.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sessionStore.load();
  runApp(const RivoraApp());
}

class RivoraApp extends StatefulWidget {
  const RivoraApp({super.key});

  @override
  State<RivoraApp> createState() => _RivoraAppState();
}

class _RivoraAppState extends State<RivoraApp> {
  @override
  void initState() {
    super.initState();
    // Layanan petugas (tugas, cek berkala, push) mengikuti sesi.
    sessionServices.attach();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIVORA',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: buildRivoraTheme(Brightness.light),
      darkTheme: buildRivoraTheme(Brightness.dark),
      // Warga langsung ke Beranda tanpa login; petugas masuk lewat tombol
      // "Masuk petugas" (mobile SRS bagian 2 dan 5).
      home: ValueListenableBuilder<Session?>(
        valueListenable: sessionStore,
        builder: (_, session, _) =>
            AppShell(key: ValueKey(session?.token ?? 'tamu')),
      ),
    );
  }
}
