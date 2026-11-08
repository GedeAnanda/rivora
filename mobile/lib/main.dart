import 'package:flutter/material.dart';

import 'models/session.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sessionStore.load();
  runApp(const RivoraApp());
}

class RivoraApp extends StatelessWidget {
  const RivoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIVORA',
      debugShowCheckedModeBanner: false,
      theme: buildRivoraTheme(Brightness.light),
      darkTheme: buildRivoraTheme(Brightness.dark),
      home: ValueListenableBuilder<Session?>(
        valueListenable: sessionStore,
        builder: (_, session, _) => session == null
            ? const LoginScreen()
            : AppShell(key: ValueKey(session.token)),
      ),
    );
  }
}
