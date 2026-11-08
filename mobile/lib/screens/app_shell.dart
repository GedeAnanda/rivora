import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_keys.dart';
import '../models/task.dart';
import '../services/push_service.dart';
import '../services/repositories.dart';
import '../services/session_services.dart';
import '../services/session_store.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'reports_screen.dart';
import 'task_detail_screen.dart';
import 'tasks_screen.dart';
import '../theme/rivora_icons.dart';

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
    riskRepository.refresh();
    // Daftar tugas, cek berkala, dan push dinyalakan/dimatikan oleh
    // sessionServices mengikuti sesi. Shell hanya menampilkan hasilnya.
    if (_petugas) {
      _tugasMasuk = taskRepository.tugasMasuk.listen(_terimaTugasBaru);
      layarFokus.addListener(_tampilkanTertunda);
      pushService.onOpenTask = _bukaTugasDariNotifikasi;
      pushService.onForegroundMessage = _beriTahuPesan;
    }
  }

  /// Ketuk notifikasi → buka detail tugas (mobile SRS FR-MB-09).
  Future<void> _bukaTugasDariNotifikasi(String? tugasId) async {
    shellTab.value = Tabs.tugas;
    if (tugasId == null) return;
    // Kalau ada refresh yang sedang berjalan, tunggu itu. Refresh itu bisa
    // dimulai sebelum tugas ini dibuat, jadi kalau belum ketemu muat sekali
    // lagi.
    await taskRepository.refresh(silent: true);
    var t = taskRepository.byId(tugasId);
    if (t == null) {
      await taskRepository.refresh(silent: true);
      t = taskRepository.byId(tugasId);
    }
    if (t == null || !mounted) return;
    final tugas = t;
    await navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(task: tugas)),
    );
  }

  @override
  void dispose() {
    _tugasMasuk?.cancel();
    layarFokus.removeListener(_tampilkanTertunda);
    // Lepas callback hanya kalau masih milik shell ini; shell sesi baru
    // bisa sudah memasang miliknya sebelum shell lama di-dispose.
    if (pushService.onOpenTask == _bukaTugasDariNotifikasi) {
      pushService.onOpenTask = null;
    }
    if (pushService.onForegroundMessage == _beriTahuPesan) {
      pushService.onForegroundMessage = null;
    }
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
              Icon(RIcons.notifikasi, color: fg),
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
                        t.kelasSebelum.label,
                        ?t.catatanLurah,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  icon: Icon(RIcons.beranda),
                  selectedIcon: Icon(RIcons.berandaAktif),
                  label: 'Beranda',
                ),
                const NavigationDestination(
                  icon: Icon(RIcons.peta),
                  selectedIcon: Icon(RIcons.petaAktif),
                  label: 'Peta',
                ),
                const NavigationDestination(
                  icon: Icon(RIcons.laporan),
                  selectedIcon: Icon(RIcons.laporanAktif),
                  label: 'Laporan',
                ),
                if (_petugas)
                  NavigationDestination(
                    icon: Badge.count(
                      count: taskRepository.aktif.length,
                      isLabelVisible: taskRepository.aktif.isNotEmpty,
                      child: const Icon(RIcons.tugas),
                    ),
                    selectedIcon: Badge.count(
                      count: taskRepository.aktif.length,
                      isLabelVisible: taskRepository.aktif.isNotEmpty,
                      child: const Icon(RIcons.tugasAktif),
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

/// Keluar dari akun petugas → kembali sebagai warga. Laporan saya tetap
/// tersimpan di HP (dilacak per perangkat, mobile SRS FR-MB-06).
/// sessionServices menghentikan cek berkala, mengosongkan tugas, dan
/// menghapus token FCM.
Future<void> keluar() async {
  await sessionStore.logout();
  await sessionServices.selesai;
  shellTab.value = Tabs.beranda;
}
