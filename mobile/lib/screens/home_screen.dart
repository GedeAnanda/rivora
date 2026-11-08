import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../config.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../services/location_service.dart';
import '../services/repositories.dart';
import '../services/session_store.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/pictogram.dart';
import '../widgets/rain_card.dart';
import '../widgets/report_tile.dart';
import '../widgets/risk_card.dart';
import '../widgets/rivora_map.dart';
import '../widgets/status_chip.dart';
import '../widgets/sumbatan_style.dart';
import 'app_shell.dart';
import 'lapor_flow.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'task_detail_screen.dart';

/// Beranda: Prediksi (hujan + risiko RW) → Lapor → Bertindak (tugas
/// terdekat, petugas) → peta → status laporan. Urutan siklus proposal 3.2.
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

  LatLng? get _titik =>
      _posisi == null ? null : LatLng(_posisi!.latitude, _posisi!.longitude);

  Future<void> _refresh() async {
    await Future.wait([
      reportRepository.refresh(),
      if (_petugas) taskRepository.refresh(),
      weatherService.refresh(paksa: true),
      riskRepository.refresh(),
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
                // Urutan: kenapa bertindak (hujan) → aksi utama (lapor) →
                // pekerjaan petugas → risiko wilayah → peta → laporan.
                // Tombol lapor harus terlihat tanpa menggulir.
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
                RiskCard(posisi: _titik),
                const SizedBox(height: Space.xl),
                SectionTitle(
                  'Peta sekitarmu',
                  trailing: TextButton(
                    onPressed: () => shellTab.value = Tabs.peta,
                    child: const Text('Buka peta'),
                  ),
                ),
                _PratinjauPeta(petugas: _petugas, posisi: _titik),
                const SizedBox(height: Space.xl),
                SectionTitle(
                  'Laporan dari HP ini',
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
      if (reportRepository.loading || !reportRepository.loaded) {
        return const [SkeletonList(count: 2, padding: EdgeInsets.zero)];
      }
      return const [
        EmptyState(
          icon: RIcons.kamera,
          title: 'Belum ada laporan',
          message:
              'Saluran yang kamu foto akan muncul di sini beserta statusnya, '
              'tanpa perlu login.',
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
    final petugas = session?.isPetugas ?? false;
    return Row(
      children: [
        const RivoraMark(size: 44),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _salam(DateTime.now()),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                petugas ? session!.nama : 'Warga',
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (petugas)
          IconButton(
            tooltip: 'Akun petugas',
            onPressed: () => _tampilkanAkun(context),
            icon: const Icon(RIcons.akun),
          )
        else
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            ),
            icon: const Icon(RIcons.petugas, size: 18),
            label: const Text('Masuk petugas'),
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
                    AppConfig.useMockApi ? RIcons.contoh : RIcons.server,
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
                icon: const Icon(RIcons.keluar),
                label: const Text('Keluar dari akun petugas'),
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
        color: scheme.primary,
        borderRadius: BorderRadius.circular(Radii.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.lg,
              Space.lg,
              Space.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lapor saluran tersumbat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Foto, pilih jenis, kirim. Lokasi tercatat otomatis.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.md),
                Icon(RIcons.kamera, size: 28, color: scheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carousel tugas aktif, terdekat dulu (urutan sumbatan kalau posisi
/// belum diketahui).
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
              Icon(RIcons.selesai, color: context.rivora.bersih.fg),
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
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: urut.length,
        separatorBuilder: (_, _) => const SizedBox(width: Space.md),
        itemBuilder: (context, i) =>
            _TugasMini(task: urut[i], jarak: jarak(urut[i])),
      ),
    );
  }
}

class _TugasMini extends StatelessWidget {
  const _TugasMini({required this.task, this.jarak});

  final Task task;
  final double? jarak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = context.rivora.sumbatan(task.kelasSebelum);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SizedBox(
      width: 288,
      child: Card(
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      alignment: Alignment.center,
                      child: JenisPictogram(
                        jenis: task.jenisSaluran,
                        size: 26,
                        color: c.fg,
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.rw ?? task.jenisSaluran.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(task.jenisSaluran.label, style: muted),
                        ],
                      ),
                    ),
                    SumbatanBadge(kelas: task.kelasSebelum, compact: true),
                  ],
                ),
                const SizedBox(height: Space.sm),
                Expanded(
                  child: Text(
                    task.catatanLurah ??
                        'Ditugaskan ${formatRelatif(task.createdAt)}.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: task.catatanLurah == null
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                Row(
                  children: [
                    TugasStatusChip(status: task.status),
                    const Spacer(),
                    Text(
                      jarak == null ? '' : formatJarak(jarak!),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
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
        borderRadius: BorderRadius.circular(Radii.xl),
        child: SizedBox(
          height: 176,
          child: Stack(
            children: [
              Positioned.fill(
                child: ListenableBuilder(
                  listenable: riskRepository,
                  builder: (context, _) => RivoraMap(
                    center: pusatRingkas(petugas: petugas),
                    zoom: 14.6,
                    markers: penandaRingkas(context, petugas: petugas),
                    rw: riskRepository.data?.rw ?? const [],
                    posisiSaya: posisi,
                    interaktif: false,
                  ),
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
                  ),
                  child: Text(
                    '$jumlah penanda · ketuk untuk membuka',
                    style: theme.textTheme.labelMedium,
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
      ('Dikirim', r.count('dikirim') + r.count('cek_manual')),
      ('Ditugaskan', r.count('ditugaskan')),
      ('Ditangani', r.count('ditangani')),
    ];
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Space.lg,
          horizontal: Space.sm,
        ),
        child: Row(
          children: [
            for (var i = 0; i < kolom.length; i++) ...[
              Expanded(
                child: Semantics(
                  label: '${kolom[i].$1}: ${kolom[i].$2} laporan',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(
                        '${kolom[i].$2}',
                        style: theme.textTheme.headlineMedium,
                      ),
                      Text(
                        kolom[i].$1,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < kolom.length - 1)
                Container(
                  width: 1,
                  height: 36,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
