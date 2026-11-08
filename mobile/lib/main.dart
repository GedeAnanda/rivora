import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const RivoraApp());
}

class RivoraApp extends StatelessWidget {
  const RivoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIVORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E7490)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
