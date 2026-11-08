import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/ai_result.dart';
import '../theme/app_theme.dart';
import 'sumbatan_style.dart';

/// Peta dasar RIVORA: tile OpenStreetMap (terang diredam / gelap ikut
/// tema), sesuai proposal Tabel 12 (Leaflet + OpenStreetMap; flutter_map =
/// port Leaflet untuk Flutter).
class RivoraMap extends StatelessWidget {
  const RivoraMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.posisiSaya,
    this.interaktif = true,
    this.controller,
    this.onTapPeta,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final LatLng? posisiSaya;
  final bool interaktif;
  final MapController? controller;
  final VoidCallback? onTapPeta;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 11,
        maxZoom: 19,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        interactionOptions: InteractionOptions(
          flags: interaktif
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
        onTap: onTapPeta == null ? null : (_, _) => onTapPeta!(),
      ),
      children: [
        // Tile OpenStreetMap standar (gratis, wajib atribusi + User-Agent).
        // Diredam warnanya supaya penanda status lebih menonjol; mode gelap
        // memakai filter gelap bawaan flutter_map.
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.rivora.rivora',
          tileBuilder: gelap ? darkModeTileBuilder : _tileRedam,
        ),
        if (posisiSaya != null)
          MarkerLayer(
            markers: [
              Marker(
                point: posisiSaya!,
                width: 24,
                height: 24,
                child: const _TitikSaya(),
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        if (interaktif)
          SimpleAttributionWidget(
            source: const Text('OpenStreetMap contributors'),
            backgroundColor: Theme.of(context).colorScheme.surface
                .withValues(alpha: 0.8),
          ),
      ],
    );
  }
}

/// Saturasi ±30 % dan sedikit lebih terang.
Widget _tileRedam(BuildContext context, Widget tile, TileImage image) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      0.39496, 0.44056, 0.04448, 0, 30.6, //
      0.13096, 0.70456, 0.04448, 0, 30.6, //
      0.13096, 0.44056, 0.30848, 0, 30.6, //
      0, 0, 0, 1, 0, //
    ]),
    child: tile,
  );
}

class _TitikSaya extends StatelessWidget {
  const _TitikSaya();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Posisimu',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2F7DF6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x552F7DF6),
              blurRadius: 10,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Penanda laporan: warna + ikon kelas sumbatan.
class LaporanPin extends StatelessWidget {
  const LaporanPin({
    super.key,
    required this.kelas,
    this.terpilih = false,
    required this.label,
  });

  final KelasSumbatan kelas;
  final bool terpilih;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Penanda selalu memakai warna pekat (versi terang) supaya angka/ikon
    // putih tetap kontras di peta terang maupun gelap.
    final c = RivoraColors.light.sumbatan(kelas);
    return Semantics(
      button: true,
      selected: terpilih,
      label: label,
      child: AnimatedScale(
        scale: terpilih ? 1.2 : 1,
        duration: Motion.of(context, Motion.fast),
        curve: Motion.enter,
        child: Container(
          decoration: BoxDecoration(
            color: c.fg,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(ikonSumbatan(kelas), size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

/// Penanda tugas: nomor urut prioritas, atau centang kalau selesai.
class TugasPin extends StatelessWidget {
  const TugasPin({
    super.key,
    required this.kelas,
    required this.label,
    this.urutan,
    this.selesai = false,
    this.terpilih = false,
  });

  final KelasSumbatan kelas;
  final String label;
  final int? urutan;
  final bool selesai;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = RivoraColors.light.sumbatan(kelas);
    final warna = selesai ? RivoraColors.light.bersih.fg : c.fg;
    return Semantics(
      button: true,
      selected: terpilih,
      label: label,
      child: AnimatedScale(
        scale: terpilih ? 1.2 : 1,
        duration: Motion.of(context, Motion.fast),
        curve: Motion.enter,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: urutan == 1 ? scheme.primary : Colors.white,
              width: urutan == 1 ? 3 : 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: selesai
              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
              : Text(
                  '${urutan ?? ''}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
