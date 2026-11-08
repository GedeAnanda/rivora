import 'package:flutter/material.dart';

import '../services/repositories.dart';
import '../services/session_store.dart';
import 'home_screen.dart';
import 'reports_screen.dart';
import 'tasks_screen.dart';

/// Tab aktif. Bisa diganti dari layar mana saja, mis. tombol
/// "Lihat status laporan" di layar hasil.
final shellTab = ValueNotifier<int>(0);

abstract final class Tabs {
  static const beranda = 0;
  static const laporan = 1;
  static const tugas = 2;
}

/// Navigasi bawah: Beranda, Laporan, dan Tugas (khusus petugas).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool get _petugas => sessionStore.value?.isPetugas ?? false;

  @override
  void initState() {
    super.initState();
    shellTab.value = Tabs.beranda;
    reportRepository.refresh();
    if (_petugas) taskRepository.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, tab, _) {
        final pages = [
          const HomeScreen(),
          const ReportsScreen(),
          if (_petugas) const TasksScreen(),
        ];
        final index = tab.clamp(0, pages.length - 1);
        return Scaffold(
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: ListenableBuilder(
            listenable: taskRepository,
            builder: (context, _) => NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => shellTab.value = i,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Beranda',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Laporan',
                ),
                if (_petugas)
                  NavigationDestination(
                    icon: Badge.count(
                      count: taskRepository.aktif.length,
                      isLabelVisible: taskRepository.aktif.isNotEmpty,
                      child: const Icon(Icons.assignment_outlined),
                    ),
                    selectedIcon: Badge.count(
                      count: taskRepository.aktif.length,
                      isLabelVisible: taskRepository.aktif.isNotEmpty,
                      child: const Icon(Icons.assignment_rounded),
                    ),
                    label: 'Tugas',
                    tooltip: '${taskRepository.aktif.length} tugas aktif',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> keluar() async {
  await sessionStore.logout();
  reportRepository.clear();
  taskRepository.clear();
  shellTab.value = Tabs.beranda;
}
