import 'package:flutter/material.dart';

import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'motion.dart';

String _jam(DateTime t) => '${t.hour.toString().padLeft(2, '0')}.00';

/// Hero beranda: prakiraan hujan 24 jam di sekitar pengguna (Open-Meteo),
/// kategori BMKG, kalimat tindakan, dan grafik per jam. Ini tahap
/// "Prediksi" (proposal 3.2) yang terlihat langsung oleh petugas dan warga.
class RainCard extends StatelessWidget {
  const RainCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: weatherService,
      builder: (context, _) {
        final data = weatherService.data;
        if (data == null && weatherService.loading) {
          return const Skeleton(height: 252, radius: 24);
        }
        if (data == null) {
          return _Gagal(
            pesan: weatherService.error ?? 'Prakiraan hujan belum dimuat.',
          );
        }
        return _Isi(data: data);
      },
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});

  final PrakiraanHujan data;

  static List<Color> _gradien(KategoriHujan k) => switch (k) {
    KategoriHujan.tidak ||
    KategoriHujan.ringan => const [Color(0xFF0B6E79), Color(0xFF06424A)],
    KategoriHujan.sedang => const [Color(0xFF7A4300), Color(0xFF4A2800)],
    _ => const [Color(0xFF9B1C14), Color(0xFF5E0F0A)],
  };

  String get _peluang {
    final p = data.peluangTertinggi;
    if (p == null || (p.peluang ?? 0) < 20) return '';
    return ' Peluang hujan tertinggi ${p.peluang}% pukul ${_jam(p.waktu)}.';
  }

  String get _kalimat {
    final mulai = data.mulaiHujan;
    final puncak = data.puncak;
    return switch (data.kategori) {
      KategoriHujan.tidak =>
        'Tidak ada hujan dalam 24 jam. Waktu yang tepat untuk membersihkan saluran.$_peluang',
      KategoriHujan.ringan =>
        'Hujan ringan${mulai == null ? '' : ' mulai sekitar ${_jam(mulai.waktu)}'}.$_peluang Pantau saluran di sekitarmu.',
      KategoriHujan.sedang =>
        'Hujan mulai sekitar ${_jam(mulai!.waktu)}, puncak ${_jam(puncak!.waktu)}. Laporkan saluran yang tersumbat sekarang.',
      _ =>
        'Hujan lebat mulai sekitar ${_jam(mulai!.waktu)}. Bersihkan saluran tersumbat sebelum itu.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const putih = Colors.white;
    final redup = Colors.white.withValues(alpha: 0.88);
    final k = data.kategori;

    return Semantics(
      container: true,
      label:
          'Prakiraan hujan 24 jam: ${formatDesimal(data.total, digits: 1)} '
          'milimeter, ${k.label}. $_kalimat',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          Space.xl,
          Space.lg,
          Space.xl,
          Space.lg,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradien(k),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  k.perluBertindak
                      ? Icons.thunderstorm_rounded
                      : Icons.water_drop_rounded,
                  size: 18,
                  color: putih,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    'Prakiraan hujan 24 jam',
                    style: theme.textTheme.labelLarge?.copyWith(color: putih),
                  ),
                ),
                Text(
                  data.lokasiPerkiraan
                      ? 'Gedebage (perkiraan)'
                      : 'Di sekitarmu',
                  style: theme.textTheme.labelMedium?.copyWith(color: redup),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDesimal(data.total, digits: 1),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: putih,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: Space.xs, bottom: 4),
                  child: Text(
                    'mm',
                    style: theme.textTheme.titleMedium?.copyWith(color: redup),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    k.label,
                    style: theme.textTheme.labelLarge?.copyWith(color: putih),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              _kalimat,
              style: theme.textTheme.bodyMedium?.copyWith(color: putih),
            ),
            const SizedBox(height: Space.lg),
            RainChart(jam: data.jam),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Batang = mm · bayangan = peluang · skor hujan ${formatDesimal(data.komponenHujan)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: redup),
                  ),
                ),
                Text(
                  'Open-Meteo',
                  style: theme.textTheme.bodySmall?.copyWith(color: redup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Batang hujan per jam, 24 jam ke depan, di atas latar gelap.
class RainChart extends StatelessWidget {
  const RainChart({super.key, required this.jam, this.height = 64});

  final List<HujanPerJam> jam;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (jam.isEmpty) return SizedBox(height: height);
    final theme = Theme.of(context);
    final maks = jam.map((h) => h.mm).fold<double>(0, (a, b) => b > a ? b : a);
    final skala = maks < 4 ? 4.0 : maks;
    final label = theme.textTheme.labelSmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.88),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.reveal),
      curve: Motion.enter,
      builder: (context, t, _) => Column(
        children: [
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in jam)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      // Bayangan = peluang hujan (0–100 %), batang terang =
                      // curah hujan (mm). Peluang tetap informatif saat
                      // curah hujan kecil.
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          if (h.peluang != null)
                            Container(
                              height: (height * h.peluang! / 100) * t,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          Container(
                            height: h.mm <= 0
                                ? 3
                                : (3 + (height - 3) * (h.mm / skala)) * t,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: h.mm <= 0
                                    ? 0.3
                                    : h.mm >= 10
                                    ? 1
                                    : h.mm >= 5
                                    ? 0.9
                                    : 0.7,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.xs + 2),
          Row(
            children: [
              for (var i = 0; i < jam.length; i += 6)
                Expanded(
                  child: Text(
                    i == 0 ? 'Kini' : _jam(jam[i].waktu),
                    style: label,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gagal extends StatelessWidget {
  const _Gagal({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Space.md),
          Expanded(child: Text(pesan, style: theme.textTheme.bodyMedium)),
          TextButton(
            onPressed: () => weatherService.refresh(paksa: true),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
