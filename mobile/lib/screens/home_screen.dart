import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../services/location_service.dart';
import '../services/repositories.dart';
import '../services/session_store.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/rain_card.dart';
import '../widgets/report_tile.dart';
import '../widgets/rivora_map.dart';
import '../widgets/sumbatan_style.dart';
import 'app_shell.dart';
import 'lapor_flow.dart';
import 'map_screen.dart';
import 'task_detail_screen.dart';

/// Beranda: kondisi hujan → aksi lapor → tugas terdekat → peta → status.
/// Urutannya mengikuti siklus proposal 3.2 (Prediksi, Lapor, Bertindak,
/// Verifikasi) dari sudut pandang pengguna di lapangan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _posisi;

  bool get _petugas => sessionStore.value?.isPetugas ?? false;

  @override
  void initState() {
    super.initState();
    locationService.lastKnown().then((p) {
      if (mounted && p != null) setState(() => _posisi = p);
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      reportRepository.refresh(),
      if (_petugas) taskRepository.refresh(),
      weatherService.refresh(paksa: true),
    ]);
  }

  double? _jarak(Task t) => _posisi == null
      ? null
      : Geolocator.distanceBetween(
          _posisi!.latitude,
          _posisi!.longitude,
          t.lat,
          t.lng,
        );

  @override
  Widget build(BuildContext context) {
    final session = sessionStore.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListenableBuilder(
            listenable: Listenable.merge([reportRepository, taskRepository]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.lg,
                Space.xxl,
              ),
              children: [
                _Header(session: session),
                const SizedBox(height: Space.lg),
                const RainCard(),
                const SizedBox(height: Space.md),
                _LaporCta(onTap: () => mulaiLapor(context)),
                if (_petugas) ...[
                  const SizedBox(height: Space.xl),
                  SectionTitle(
                    'Tugas terdekat',
                    trailing: TextButton(
                      onPressed: () => shellTab.value = Tabs.tugas,
                      child: const Text('Semua tugas'),
                    ),
                  ),
                  _TugasTerdekat(jarak: _jarak),
                ],
                const SizedBox(height: Space.xl),
                SectionTitle(
                  'Peta sekitarmu',
                  trailing: TextButton(
                    onPressed: () => shellTab.value = Tabs.peta,
                    child: const Text('Buka peta'),
                  ),
                ),
                _PratinjauPeta(
                  petugas: _petugas,
                  posisi: _posisi == null
                      ? null
                      : LatLng(_posisi!.latitude, _posisi!.longitude),
                ),
                const SizedBox(height: Space.xl),
                SectionTitle(
                  'Laporanmu',
                  trailing: TextButton(
                    onPressed: () => shellTab.value = Tabs.laporan,
                    child: const Text('Lihat semua'),
                  ),
                ),
                const _PelacakStatus(),
                const SizedBox(height: Space.md),
                ..._terbaru(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _terbaru() {
    final items = reportRepository.items.take(3).toList();
    if (items.isEmpty) {
      if (reportRepository.loading) {
        return const [SkeletonList(count: 2, padding: EdgeInsets.zero)];
      }
      return const [
        EmptyState(
          icon: Icons.photo_camera_outlined,
          title: 'Belum ada laporan',
          message:
              'Saluran yang kamu foto akan muncul di sini beserta statusnya.',
        ),
      ];
    }
    return [
      for (final r in items) ...[
        ReportTile(report: r),
        const SizedBox(height: Space.sm),
      ],
    ];
  }
}

String _salam(DateTime t) => t.hour < 11
    ? 'Selamat pagi'
    : t.hour < 15
    ? 'Selamat siang'
    : t.hour < 18
    ? 'Selamat sore'
    : 'Selamat malam';

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final Session? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const RivoraMark(size: 44),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_salam(DateTime.now())},',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                session?.nama ?? '',
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Akun',
          onPressed: () => _tampilkanAkun(context),
          icon: const Icon(Icons.person_rounded),
        ),
      ],
    );
  }

  void _tampilkanAkun(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session?.nama ?? '', style: theme.textTheme.titleLarge),
              Text(
                labelRole[session?.role] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: [
                  Icon(
                    AppConfig.useMockApi
                        ? Icons.science_outlined
                        : Icons.cloud_done_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      AppConfig.useMockApi
                          ? 'Mode contoh (tanpa server)'
                          : 'Server: ${AppConfig.apiUrl}',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  keluar();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aksi utama: lapor saluran.
class _LaporCta extends StatelessWidget {
  const _LaporCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Lapor saluran tersumbat. Foto, pilih jenis, kirim.',
      excludeSemantics: true,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: scheme.onPrimary,
                  ),
                ),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lapor saluran tersumbat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Foto · pilih jenis · kirim. Lokasi otomatis.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carousel tugas aktif, terdekat dulu (prioritas kalau posisi belum ada).
class _TugasTerdekat extends StatelessWidget {
  const _TugasTerdekat({required this.jarak});

  final double? Function(Task) jarak;

  @override
  Widget build(BuildContext context) {
    final aktif = taskRepository.aktif;
    if (aktif.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Icon(Icons.task_alt_rounded, color: context.rivora.bersih.fg),
              const SizedBox(width: Space.md),
              Text(
                taskRepository.loading
                    ? 'Memuat tugas…'
                    : 'Semua tugas selesai',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      );
    }
    final urut = [...aktif]
      ..sort((a, b) {
        final ja = jarak(a);
        final jb = jarak(b);
        if (ja != null && jb != null) return ja.compareTo(jb);
        return aktif.indexOf(a).compareTo(aktif.indexOf(b));
      });
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: urut.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.md),
        itemBuilder: (context, i) => _TugasMini(
          task: urut[i],
          urutan: aktif.indexOf(urut[i]) + 1,
          jarak: jarak(urut[i]),
        ),
      ),
    );
  }
}

class _TugasMini extends StatelessWidget {
  const _TugasMini({required this.task, required this.urutan, this.jarak});

  final Task task;
  final int urutan;
  final double? jarak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.rivora.sumbatan(task.ai.kelas);
    return SizedBox(
      width: 272,
      child: Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: c.fg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: urutan == 1
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Text(
                              '$urutan',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: urutan == 1
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: Text(
                              [?task.rw, task.jenisSaluran.label].join(' · '),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (task.ai.catatan.isNotEmpty) ...[
                        const SizedBox(height: Space.xs + 2),
                        Text(
                          task.ai.catatan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      SumbatanBadge(kelas: task.ai.kelas, compact: true),
                      const SizedBox(height: Space.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Space.xs),
                          Text(
                            jarak == null ? 'Jarak –' : formatJarak(jarak!),
                            style: theme.textTheme.labelMedium,
                          ),
                          const Spacer(),
                          if (task.skorPrioritas != null)
                            Text(
                              'Prioritas ${formatDesimal(task.skorPrioritas!)}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Peta kecil tanpa interaksi; ketuk untuk membuka tab Peta.
class _PratinjauPeta extends StatelessWidget {
  const _PratinjauPeta({required this.petugas, this.posisi});

  final bool petugas;
  final LatLng? posisi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jumlah =
        reportRepository.items.length +
        (petugas ? taskRepository.aktif.length : 0);
    return Semantics(
      button: true,
      label: 'Buka peta. $jumlah penanda di sekitarmu.',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 176,
          child: Stack(
            children: [
              Positioned.fill(
                child: RivoraMap(
                  center: pusatRingkas(petugas: petugas),
                  zoom: 14.6,
                  markers: penandaRingkas(context, petugas: petugas),
                  posisiSaya: posisi,
                  interaktif: false,
                ),
              ),
              Positioned(
                left: Space.md,
                bottom: Space.md,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(color: Color(0x260B1F2A), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: Space.xs),
                      Text(
                        '$jumlah penanda',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: () => shellTab.value = Tabs.peta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ringkasan status laporan seperti pelacak pengiriman:
/// Dikirim → Ditugaskan → Ditangani.
class _PelacakStatus extends StatelessWidget {
  const _PelacakStatus();

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: reportRepository, builder: _build);

  Widget _build(BuildContext context, Widget? _) {
    final r = reportRepository;
    final kolom = [
      (
        Icons.send_rounded,
        'Dikirim',
        r.count('dikirim') + r.count('cek_manual'),
      ),
      (Icons.engineering_rounded, 'Ditugaskan', r.count('ditugaskan')),
      (Icons.task_alt_rounded, 'Ditangani', r.count('ditangani')),
    ];
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.lg),
        child: Row(
          children: [
            for (var i = 0; i < kolom.length; i++) ...[
              Expanded(
                child: Semantics(
                  label: '${kolom[i].$2}: ${kolom[i].$3} laporan',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Icon(
                        kolom[i].$1,
                        size: 20,
                        color: i == 2
                            ? context.rivora.bersih.fg
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        '${kolom[i].$3}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        kolom[i].$2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < kolom.length - 1)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
