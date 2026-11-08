import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../models/ai_result.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';
import 'rivora_map.dart';

/// Lokasi dalam bentuk yang dipahami warga: potongan peta + nama RW,
/// pengganti koordinat mentah "-6.944098, 107.691198".
///
/// [ringkas]: gambar peta kecil di kiri (form kirim laporan).
/// Selain itu: peta selebar kartu (detail laporan/tugas).
class LokasiMini extends StatelessWidget {
  const LokasiMini({
    super.key,
    required this.lat,
    required this.lng,
    this.rw,
    this.akurasi,
    this.keterangan,
    this.kelas,
    this.ringkas = false,
  });

  final double lat;
  final double lng;

  /// Nama RW dari backend. Kalau kosong, dicari dari poligon `GET /rw/risk`.
  final String? rw;

  /// Akurasi GPS (meter).
  final double? akurasi;

  /// Baris tambahan, mis. "Difoto 8 Nov 2026, 11:55" atau "530 m dari
  /// posisimu".
  final String? keterangan;

  /// Warna penanda (kondisi saluran). Kosong = warna merek.
  final KelasSumbatan? kelas;
  final bool ringkas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titik = LatLng(lat, lng);
    final namaRw = rw ?? riskRepository.data?.rwDiTitik(titik)?.nama;
    final judul = namaRw == null ? 'Lokasi GPS tercatat' : 'Di $namaRw';
    final baris = [
      if (akurasi != null) 'Titik GPS akurat ±${akurasi!.round()} m',
      ?keterangan,
    ];

    final peta = ClipRRect(
      borderRadius: BorderRadius.circular(ringkas ? Radii.sm : Radii.md),
      child: IgnorePointer(
        child: RivoraMap(
          center: titik,
          zoom: ringkas ? 15.2 : 16.5,
          interaktif: false,
          atribusi: !ringkas,
          markers: [
            if (ringkas)
              Marker(point: titik, width: 18, height: 18, child: const _Titik())
            else
              Marker(
                point: titik,
                width: LaporanPin.ukuran.width,
                height: LaporanPin.ukuran.height,
                alignment: Alignment.topCenter,
                child: LaporanPin(
                  kelas: kelas ?? KelasSumbatan.bersih,
                  label: judul,
                ),
              ),
          ],
        ),
      ),
    );

    final teks = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(judul, style: theme.textTheme.titleMedium),
        for (final b in baris) ...[
          const SizedBox(height: 2),
          Text(
            b,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return Semantics(
      label: [judul, ...baris].join('. '),
      excludeSemantics: true,
      child: ringkas
          ? Row(
              children: [
                SizedBox.square(dimension: 76, child: peta),
                const SizedBox(width: Space.md),
                Expanded(child: teks),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 148, width: double.infinity, child: peta),
                const SizedBox(height: Space.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        RIcons.lokasi,
                        size: 20,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(child: teks),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Titik extends StatelessWidget {
  const _Titik();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
      ),
    );
  }
}
