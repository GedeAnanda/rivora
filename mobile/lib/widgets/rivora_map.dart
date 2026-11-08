import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../models/ai_result.dart';
import '../models/rw_risk.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';

/// Peta dasar RIVORA: tile OpenStreetMap (terang diredam / gelap ikut tema),
/// poligon risiko RW, dan penanda. Sesuai proposal Tabel 12 (Leaflet +
/// OpenStreetMap; flutter_map = port Leaflet untuk Flutter).
class RivoraMap extends StatelessWidget {
  const RivoraMap({
    super.key,
    required this.center,
    this.zoom = 15,
    this.markers = const [],
    this.rw = const [],
    this.posisiSaya,
    this.interaktif = true,
    this.atribusi,
    this.atribusiDiAtas = false,
    this.controller,
    this.onTapPeta,
  });

  final LatLng center;
  final double zoom;
  final List<Marker> markers;

  /// Poligon RW berwarna level risiko (peta risiko, proposal Tabel 3).
  final List<RwRisk> rw;
  final LatLng? posisiSaya;
  final bool interaktif;

  /// Tampilkan atribusi OpenStreetMap. Default: ikut [interaktif]. Peta
  /// statis yang cukup besar sebaiknya tetap menampilkannya.
  final bool? atribusi;

  /// Atribusi di kanan atas (pratinjau yang punya label di bawah).
  final bool atribusiDiAtas;
  final MapController? controller;
  final VoidCallback? onTapPeta;

  @override
  Widget build(BuildContext context) {
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final label = Theme.of(context).textTheme.labelSmall;
    final halo = Theme.of(context).colorScheme.surface.withValues(alpha: 0.9);
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
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'id.rivora.rivora',
          tileBuilder: gelap ? darkModeTileBuilder : _tileRedam,
        ),
        if (rw.isNotEmpty)
          PolygonLayer(
            polygons: [
              for (final r in rw)
                if (r.polygon.length >= 3)
                  Polygon(
                    points: r.polygon,
                    color: RivoraColors.light
                        .risiko(r.level)
                        .fg
                        .withValues(alpha: 0.16),
                    borderColor: RivoraColors.light
                        .risiko(r.level)
                        .fg
                        .withValues(alpha: 0.7),
                    borderStrokeWidth: 1.5,
                  ),
            ],
          ),
        // Nama RW hanya di peta penuh; di pratinjau kecil menumpuk pin.
        if (rw.isNotEmpty && interaktif)
          MarkerLayer(
            markers: [
              for (final r in rw)
                if (r.titikLabel case final titik?)
                  Marker(
                    point: titik,
                    width: 72,
                    height: 20,
                    child: IgnorePointer(
                      child: Center(
                        child: Text(
                          r.nama,
                          maxLines: 1,
                          style: (label ?? const TextStyle()).copyWith(
                            color: context.rivora.risiko(r.level).fg,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(color: halo, blurRadius: 3),
                              Shadow(color: halo, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        if (posisiSaya != null)
          MarkerLayer(
            markers: [
              Marker(
                point: posisiSaya!,
                width: 22,
                height: 22,
                child: const _TitikSaya(),
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        // Atribusi OSM wajib terlihat; strip kecil di pojok kanan bawah.
        // Layar peta memberi ruang di bawah legenda untuk strip ini.
        if (atribusi ?? interaktif)
          Align(
            alignment: atribusiDiAtas
                ? Alignment.topRight
                : Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '© OpenStreetMap contributors',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
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

/// Bentuk pin peta (tetes terbalik) dengan ujung di bawah.
class _PinPainter extends CustomPainter {
  const _PinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.18, h * 0.66, 0, h * 0.5, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..cubicTo(w, h * 0.5, w * 0.82, h * 0.66, w / 2, h)
      ..close();
    canvas
      ..drawShadow(path, Colors.black, 3, false)
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.color,
    required this.terpilih,
    required this.label,
    required this.child,
  });

  final Color color;
  final bool terpilih;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: terpilih,
      label: label,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: terpilih ? 1.18 : 1,
        alignment: Alignment.bottomCenter,
        duration: Motion.of(context, Motion.fast),
        curve: Motion.enter,
        child: CustomPaint(
          painter: _PinPainter(color),
          child: LayoutBuilder(
            builder: (context, c) => Align(
              alignment: Alignment.topCenter,
              child: SizedBox.square(
                dimension: c.maxWidth,
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Penanda laporan: pin warna kelas sumbatan dengan titik putih. Penanda
/// selalu memakai warna pekat (versi terang) supaya kontras di peta terang
/// maupun gelap. Ujung pin di bawah: pakai `Alignment.topCenter` di Marker.
class LaporanPin extends StatelessWidget {
  const LaporanPin({
    super.key,
    required this.kelas,
    this.terpilih = false,
    required this.label,
  });

  static const ukuran = Size(28, 36);

  final KelasSumbatan kelas;
  final bool terpilih;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _Pin(
      color: RivoraColors.light.sumbatan(kelas).fg,
      terpilih: terpilih,
      label: label,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Penanda tugas: pin lebih besar berisi nomor urut, centang kalau selesai.
class TugasPin extends StatelessWidget {
  const TugasPin({
    super.key,
    required this.kelas,
    required this.label,
    this.urutan,
    this.selesai = false,
    this.terpilih = false,
  });

  static const ukuran = Size(34, 44);

  final KelasSumbatan kelas;
  final String label;
  final int? urutan;
  final bool selesai;
  final bool terpilih;

  @override
  Widget build(BuildContext context) {
    return _Pin(
      color: selesai
          ? RivoraColors.light.bersih.fg
          : RivoraColors.light.sumbatan(kelas).fg,
      terpilih: terpilih,
      label: label,
      child: selesai
          ? const Icon(RIcons.centang, size: 16, color: Colors.white)
          : Text(
              '${urutan ?? ''}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
    );
  }
}
