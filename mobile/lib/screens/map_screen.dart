import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/report.dart';
import '../models/task.dart';
import '../services/location_service.dart';
import '../services/repositories.dart';
import '../services/session_store.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/maps.dart';
import '../widgets/report_photo.dart';
import '../widgets/rivora_map.dart';
import '../widgets/status_chip.dart';
import '../widgets/sumbatan_style.dart';
import 'lapor_flow.dart';
import 'report_detail_screen.dart';
import 'task_detail_screen.dart';

enum _Lapisan { semua, laporan, tugas }

/// Peta laporan dan tugas di sekitar pengguna (proposal Tabel 3: peta
/// risiko; di app mobile versi lapangan untuk petugas dan warga).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _peta = MapController();
  Position? _posisi;
  Object? _pilih;
  _Lapisan _lapisan = _Lapisan.semua;

  bool get _petugas => sessionStore.value?.isPetugas ?? false;

  @override
  void initState() {
    super.initState();
    locationService.lastKnown().then((p) {
      if (mounted && p != null) setState(() => _posisi = p);
    });
  }

  LatLng? get _saya =>
      _posisi == null ? null : LatLng(_posisi!.latitude, _posisi!.longitude);

  LatLng _awal() {
    final saya = _saya;
    if (saya != null) return saya;
    if (_petugas && taskRepository.items.isNotEmpty) {
      final t = taskRepository.items.first;
      return LatLng(t.lat, t.lng);
    }
    if (reportRepository.items.isNotEmpty) {
      final r = reportRepository.items.first;
      return LatLng(r.lat, r.lng);
    }
    return const LatLng(WeatherService.pilotLat, WeatherService.pilotLng);
  }

  void _pilihItem(Object item, LatLng titik) {
    setState(() => _pilih = item);
    _peta.move(titik, math.max(_peta.camera.zoom, 16));
  }

  void _kePosisiSaya() {
    final saya = _saya;
    if (saya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posisimu belum diketahui. Nyalakan GPS.'),
        ),
      );
      locationService.lastKnown().then((p) {
        if (mounted && p != null) setState(() => _posisi = p);
      });
      return;
    }
    _peta.move(saya, 16);
  }

  double? _jarak(double lat, double lng) => _posisi == null
      ? null
      : Geolocator.distanceBetween(
          _posisi!.latitude,
          _posisi!.longitude,
          lat,
          lng,
        );

  List<Marker> _markers() {
    final markers = <Marker>[];
    if (_lapisan != _Lapisan.tugas) {
      for (final r in reportRepository.items) {
        markers.add(
          Marker(
            point: LatLng(r.lat, r.lng),
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () => _pilihItem(r, LatLng(r.lat, r.lng)),
              child: LaporanPin(
                kelas: r.ai.kelas,
                terpilih: identical(_pilih, r),
                label:
                    'Laporan ${r.jenisSaluran.label}, ${r.ai.kelas.label}, '
                    '${labelStatusLaporan[r.status] ?? r.status}',
              ),
            ),
          ),
        );
      }
    }
    if (_petugas && _lapisan != _Lapisan.laporan) {
      final aktif = taskRepository.aktif;
      for (final t in taskRepository.items) {
        final urutan = t.selesai ? null : aktif.indexOf(t) + 1;
        markers.add(
          Marker(
            point: LatLng(t.lat, t.lng),
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => _pilihItem(t, LatLng(t.lat, t.lng)),
              child: TugasPin(
                kelas: t.ai.kelas,
                urutan: urutan,
                selesai: t.selesai,
                terpilih: identical(_pilih, t),
                label: t.selesai
                    ? 'Tugas selesai ${t.rw ?? ''}'
                    : 'Tugas prioritas $urutan ${t.rw ?? ''}, ${t.ai.kelas.label}',
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([reportRepository, taskRepository]),
      builder: (context, _) {
        final pilih = _pilih;
        // Item terpilih bisa berubah di repositori (mis. tugas selesai).
        final tugasTerpilih = pilih is Task
            ? taskRepository.byId(pilih.id) ?? pilih
            : null;
        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: RivoraMap(
                  controller: _peta,
                  center: _awal(),
                  markers: _markers(),
                  posisiSaya: _saya,
                  onTapPeta: () => setState(() => _pilih = null),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: _BarAtas(
                    petugas: _petugas,
                    lapisan: _lapisan,
                    jumlahLaporan: reportRepository.items.length,
                    jumlahTugas: taskRepository.aktif.length,
                    onLapisan: (l) => setState(() {
                      _lapisan = l;
                      _pilih = null;
                    }),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'peta-posisi-saya',
                        tooltip: 'Ke posisimu',
                        onPressed: _kePosisiSaya,
                        child: const Icon(Icons.my_location_rounded),
                      ),
                      const SizedBox(height: Space.md),
                      AnimatedSwitcher(
                        duration: Motion.of(context, Motion.normal),
                        switchInCurve: Motion.enter,
                        switchOutCurve: Motion.exit,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: switch (pilih) {
                          Report r => _KartuLaporan(
                            key: ValueKey('r${r.id}'),
                            report: r,
                          ),
                          Task _ => _KartuTugas(
                            key: ValueKey('t${tugasTerpilih!.id}'),
                            task: tugasTerpilih,
                            urutan: tugasTerpilih.selesai
                                ? null
                                : taskRepository.aktif.indexOf(tugasTerpilih) +
                                      1,
                            jarak: _jarak(tugasTerpilih.lat, tugasTerpilih.lng),
                          ),
                          _ => _Legenda(
                            key: const ValueKey('legenda'),
                            petugas: _petugas,
                          ),
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarAtas extends StatelessWidget {
  const _BarAtas({
    required this.petugas,
    required this.lapisan,
    required this.jumlahLaporan,
    required this.jumlahTugas,
    required this.onLapisan,
  });

  final bool petugas;
  final _Lapisan lapisan;
  final int jumlahLaporan;
  final int jumlahTugas;
  final ValueChanged<_Lapisan> onLapisan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Kaca(
          child: Row(
            children: [
              Icon(Icons.map_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Peta saluran',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              Text(
                petugas
                    ? '$jumlahTugas tugas · $jumlahLaporan laporan'
                    : '$jumlahLaporan laporan',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (petugas) ...[
          const SizedBox(height: Space.sm),
          _Kaca(
            padding: const EdgeInsets.all(Space.xs),
            child: SegmentedButton<_Lapisan>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
              ),
              segments: const [
                ButtonSegment(value: _Lapisan.semua, label: Text('Semua')),
                ButtonSegment(value: _Lapisan.tugas, label: Text('Tugas')),
                ButtonSegment(value: _Lapisan.laporan, label: Text('Laporan')),
              ],
              selected: {lapisan},
              onSelectionChanged: (s) => onLapisan(s.first),
            ),
          ),
        ],
      ],
    );
  }
}

/// Panel melayang di atas peta.
class _Kaca extends StatelessWidget {
  const _Kaca({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Space.lg,
      vertical: Space.md,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B1F2A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({super.key, required this.petugas});

  final bool petugas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sama dengan warna penanda (selalu versi pekat).
    const rv = RivoraColors.light;
    Widget item(Color c, String t, {bool kotak = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            shape: kotak ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: kotak ? BorderRadius.circular(3) : null,
          ),
        ),
        const SizedBox(width: Space.xs + 2),
        Text(t, style: theme.textTheme.labelMedium),
      ],
    );
    return _Kaca(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ketuk penanda untuk melihat detail',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.md,
            runSpacing: Space.xs,
            children: [
              item(rv.berat.fg, 'Berat'),
              item(rv.sedang.fg, 'Sedang'),
              item(rv.ringan.fg, 'Ringan'),
              item(rv.bersih.fg, 'Bersih'),
              item(rv.tidakTerlihat.fg, 'Tidak terlihat'),
              if (petugas)
                item(
                  theme.colorScheme.onSurfaceVariant,
                  'Tugas (nomor = prioritas)',
                  kotak: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KartuLaporan extends StatelessWidget {
  const _KartuLaporan({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void buka() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportDetailScreen(report: report),
      ),
    );
    return _Kaca(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: buka,
            borderRadius: BorderRadius.circular(Radii.md),
            child: Row(
              children: [
                ReportPhoto(
                  file: reportRepository.localPhoto(report.id),
                  url: report.fotoUrl,
                  width: 64,
                  height: 64,
                  radius: Radii.sm,
                  kelas: report.ai.kelas,
                  jenis: report.jenisSaluran,
                  semanticLabel: 'Foto ${report.jenisSaluran.label}',
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.jenisSaluran.label,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${report.rw ?? 'Laporanmu'} · ${formatRelatif(report.capturedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Space.xs + 2),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.xs,
                        children: [
                          SumbatanBadge(kelas: report.ai.kelas, compact: true),
                          LaporanStatusChip(status: report.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => bukaPeta(report.lat, report.lng),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Maps'),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: buka,
                  child: const Text('Lihat detail'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KartuTugas extends StatelessWidget {
  const _KartuTugas({
    super.key,
    required this.task,
    required this.urutan,
    required this.jarak,
  });

  final Task task;
  final int? urutan;
  final double? jarak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    void buka() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TaskDetailScreen(task: task)),
    );
    return _Kaca(
      padding: const EdgeInsets.all(Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: buka,
            borderRadius: BorderRadius.circular(Radii.md),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 44,
                  child: TugasPin(
                    kelas: task.ai.kelas,
                    urutan: urutan,
                    selesai: task.selesai,
                    label: 'Urutan prioritas ${urutan ?? '-'}',
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [?task.rw, task.jenisSaluran.label].join(' · '),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: Space.xs),
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.xs,
                        children: [
                          SumbatanBadge(kelas: task.ai.kelas, compact: true),
                          TugasStatusChip(status: task.status),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        [
                          if (task.skorPrioritas != null)
                            'Prioritas ${formatDesimal(task.skorPrioritas!)}',
                          if (jarak != null) formatJarak(jarak!),
                        ].join(' · '),
                        style: muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          if (task.selesai)
            FilledButton(onPressed: buka, child: const Text('Lihat detail'))
          else
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => bukaPeta(task.lat, task.lng, arah: true),
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: const Text('Arahkan'),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: () => mulaiVerifikasi(context, task),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Foto sesudah'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dipakai beranda: penanda yang sama dengan layar peta, tanpa interaksi.
List<Marker> penandaRingkas(BuildContext context, {required bool petugas}) {
  final markers = <Marker>[
    for (final r in reportRepository.items)
      Marker(
        point: LatLng(r.lat, r.lng),
        width: 28,
        height: 28,
        child: LaporanPin(kelas: r.ai.kelas, label: r.jenisSaluran.label),
      ),
  ];
  if (petugas) {
    final aktif = taskRepository.aktif;
    for (final t in aktif) {
      markers.add(
        Marker(
          point: LatLng(t.lat, t.lng),
          width: 30,
          height: 30,
          child: TugasPin(
            kelas: t.ai.kelas,
            urutan: aktif.indexOf(t) + 1,
            label: t.rw ?? '',
          ),
        ),
      );
    }
  }
  return markers;
}

/// Titik tengah ringkas untuk pratinjau peta di beranda.
LatLng pusatRingkas({required bool petugas}) {
  final titik = <LatLng>[
    for (final r in reportRepository.items) LatLng(r.lat, r.lng),
    if (petugas)
      for (final t in taskRepository.aktif) LatLng(t.lat, t.lng),
  ];
  if (titik.isEmpty) {
    return const LatLng(WeatherService.pilotLat, WeatherService.pilotLng);
  }
  final lat =
      titik.map((p) => p.latitude).reduce((a, b) => a + b) / titik.length;
  final lng =
      titik.map((p) => p.longitude).reduce((a, b) => a + b) / titik.length;
  return LatLng(lat, lng);
}
