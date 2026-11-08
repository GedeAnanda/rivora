import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_keys.dart';
import '../models/task.dart';
import '../services/push_service.dart';
import '../services/repositories.dart';
import '../services/session_store.dart';
import '../services/task_watcher.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'reports_screen.dart';
import 'task_detail_screen.dart';
import 'tasks_screen.dart';

/// Tab aktif. Bisa diganti dari layar mana saja, mis. tombol
/// "Lihat status laporan" di layar hasil.
final shellTab = ValueNotifier<int>(0);

abstract final class Tabs {
  static const beranda = 0;
  static const peta = 1;
  static const laporan = 2;
  static const tugas = 3;
}

/// Navigasi bawah: Beranda, Laporan, dan Tugas (khusus petugas).
/// Juga menyalakan notifikasi tugas: cek berkala + push FCM kalau ada.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StreamSubscription<Task>? _tugasMasuk;
  final List<Task> _tertunda = [];

  bool get _petugas => sessionStore.value?.isPetugas ?? false;

  @override
  void initState() {
    super.initState();
    shellTab.value = Tabs.beranda;
    reportRepository.refresh();
    weatherService.refresh();
    if (_petugas) {
      taskRepository.refresh();
      taskWatcher.start();
      _tugasMasuk = taskRepository.tugasMasuk.listen(_terimaTugasBaru);
      layarFokus.addListener(_tampilkanTertunda);
    }
    pushService.onOpenTasks = () =>
        shellTab.value = _petugas ? Tabs.tugas : Tabs.laporan;
    pushService.onForegroundMessage = _beriTahuPesan;
    pushService.start();
  }

  @override
  void dispose() {
    _tugasMasuk?.cancel();
    layarFokus.removeListener(_tampilkanTertunda);
    taskWatcher.stop();
    // Juga terjadi saat sesi berakhir (401), bukan hanya tombol Keluar.
    pushService.stop();
    super.dispose();
  }

  void _terimaTugasBaru(Task t) {
    if (layarFokus.value > 0) {
      _tertunda.add(t);
    } else {
      _beriTahuTugasBaru(t);
    }
  }

  void _tampilkanTertunda() {
    if (layarFokus.value > 0 || _tertunda.isEmpty || !mounted) return;
    // Tampilkan yang terbaru; sisanya tetap terlihat di daftar dan badge.
    final t = _tertunda.last;
    _tertunda.clear();
    _beriTahuTugasBaru(t);
  }

  /// Notifikasi di dalam aplikasi saat lurah menugaskan petugas
  /// (proposal Tabel 3: penugasan dan notifikasi).
  void _beriTahuTugasBaru(Task t) {
    HapticFeedback.mediumImpact();
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onInverseSurface;
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          // Flutter membuat snackbar beraksi menetap secara bawaan; di sini
          // harus hilang sendiri supaya tidak menutupi tombol kamera.
          persist: false,
          showCloseIcon: true,
          content: Row(
            children: [
              Icon(Icons.assignment_late_rounded, color: fg),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tugas baru dari kelurahan',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        ?t.rw,
                        t.ai.kelas.label,
                        if (t.skorPrioritas != null)
                          'prioritas ${formatDesimal(t.skorPrioritas!)}',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => navigatorKey.currentState?.push(
              MaterialPageRoute<void>(
                builder: (_) => TaskDetailScreen(task: t),
              ),
            ),
          ),
        ),
      );
  }

  void _beriTahuPesan(String title, String body) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(body.isEmpty ? title : '$title: $body')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, tab, _) {
        final pages = [
          const HomeScreen(),
          const MapScreen(),
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
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Peta',
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
  await pushService.stop();
  taskWatcher.stop();
  await sessionStore.logout();
  reportRepository.clear();
  taskRepository.clear();
  shellTab.value = Tabs.beranda;
}
