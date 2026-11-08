import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../theme/rivora_icons.dart';
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
          return const Skeleton(height: 260, radius: 24);
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

/// "nanti sore", "besok pagi", "sebentar lagi": waktu dalam bahasa sehari-hari.
String kataWaktu(DateTime t, {DateTime? now}) {
  final kini = now ?? DateTime.now();
  final besok =
      DateTime(t.year, t.month, t.day) !=
      DateTime(kini.year, kini.month, kini.day);
  if (!besok && t.difference(kini).inMinutes < 60) return 'sebentar lagi';
  final h = t.hour;
  final bagian = h < 4
      ? 'dini hari'
      : h < 11
      ? 'pagi'
      : h < 15
      ? 'siang'
      : h < 18
      ? 'sore'
      : 'malam';
  return besok ? 'besok $bagian' : 'nanti $bagian';
}

class _Isi extends StatelessWidget {
  const _Isi({required this.data});

  final PrakiraanHujan data;

  /// Satu warna datar per kategori (tanpa gradien); teks putih tetap
  /// kontras >= 4.5:1 di ketiganya.
  static Color _latar(KategoriHujan k) => switch (k) {
    KategoriHujan.tidak || KategoriHujan.ringan => const Color(0xFF0A5C66),
    KategoriHujan.sedang => const Color(0xFF6B3B00),
    _ => const Color(0xFF8A1A12),
  };

  /// Kesimpulan dalam satu kalimat: yang pertama dibaca warga.
  String get _judul {
    final mulai = data.mulaiHujan;
    final puncak = data.puncak;
    final peluang = data.peluangTertinggi;
    return switch (data.kategori) {
      KategoriHujan.tidak =>
        (peluang?.peluang ?? 0) >= 50
            ? 'Mungkin gerimis ${kataWaktu(peluang!.waktu)}'
            : 'Tidak hujan sampai besok',
      // Total >= 0,5 mm tetapi tidak ada satu jam pun >= 0,5 mm: gerimis
      // tipis yang tersebar, bukan "hujan sebentar lagi".
      KategoriHujan.ringan =>
        mulai == null
            ? 'Gerimis tipis sesekali'
            : 'Hujan ringan ${kataWaktu(mulai.waktu)}',
      KategoriHujan.sedang =>
        'Hujan sedang ${kataWaktu((mulai ?? puncak)!.waktu)}',
      final k => '${k.label} mulai pukul ${_jam((mulai ?? puncak)!.waktu)}',
    };
  }

  /// Saran tindakan sesuai kondisi.
  String get _saran {
    final mulai = data.mulaiHujan ?? data.puncak;
    return switch (data.kategori) {
      KategoriHujan.tidak => 'Waktu yang tepat membersihkan saluran.',
      KategoriHujan.ringan => 'Belum berbahaya. Pantau saluran dekat rumah.',
      KategoriHujan.sedang => 'Laporkan saluran tersumbat sebelum hujan turun.',
      _ => 'Bersihkan saluran tersumbat sebelum pukul ${_jam(mulai!.waktu)}.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const putih = Colors.white;
    final redup = Colors.white.withValues(alpha: 0.88);
    final k = data.kategori;
    final peluang = data.peluangTertinggi?.peluang;

    return Semantics(
      container: true,
      label:
          '$_judul. $_saran Total ${formatDesimal(data.total, digits: 1)} '
          'milimeter dalam 24 jam.',
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
          color: _latar(k),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cuaca 24 jam',
                    style: theme.textTheme.labelLarge?.copyWith(color: redup),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _judul,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: putih,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        _saran,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: putih,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.md),
                CuacaIlustrasi(kategori: k, size: 72),
              ],
            ),
            const SizedBox(height: Space.lg),
            RainChart(jam: data.jam),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      '${formatDesimal(data.total, digits: 1)} mm',
                      if (peluang != null && peluang >= 20)
                        'peluang hujan $peluang%',
                    ].join(' · '),
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

/// Garis waktu hujan 24 jam: satu batang per jam, makin tinggi makin deras.
/// Jam tanpa hujan berupa titik kecil, jadi jendela hujan langsung terlihat.
class RainChart extends StatelessWidget {
  const RainChart({super.key, required this.jam, this.height = 44});

  final List<HujanPerJam> jam;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (jam.isEmpty) return SizedBox(height: this.height);
    final theme = Theme.of(context);
    final maks = jam.map((h) => h.mm).fold<double>(0, (a, b) => b > a ? b : a);
    // Tinggi grafik ikut jumlah hujan: hari kering/gerimis tidak
    // menyisakan pita kosong besar.
    final height = maks < 0.1
        ? 6.0
        : maks < 2
        ? 10 + (this.height - 10) * maks / 2
        : this.height;
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
                      child: h.mm < 0.1
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            )
                          : Container(
                              height: (6 + (height - 6) * (h.mm / skala)) * t,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: h.mm >= 5 ? 1 : 0.8,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
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
                    i == 0 ? 'Sekarang' : _jam(jam[i].waktu),
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

/// Ilustrasi cuaca sederhana, digambar sendiri: matahari, awan + tetes
/// (jumlah tetes ikut kategori), awan gelap + kilat untuk hujan lebat.
class CuacaIlustrasi extends StatelessWidget {
  const CuacaIlustrasi({super.key, required this.kategori, this.size = 64});

  final KategoriHujan kategori;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _CuacaPainter(kategori),
      ),
    );
  }
}

class _CuacaPainter extends CustomPainter {
  const _CuacaPainter(this.k);

  final KategoriHujan k;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final putih = Paint()..color = Colors.white;
    final garis = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round;

    if (k == KategoriHujan.tidak) {
      final c = Offset(s * 0.5, s * 0.5);
      canvas.drawCircle(c, s * 0.18, putih);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + d * s * 0.28, c + d * s * 0.4, garis);
      }
      return;
    }

    // Awan: tiga lingkaran + alas membulat.
    final awan = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(s * 0.36, s * 0.42), radius: s * 0.16),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(s * 0.56, s * 0.34), radius: s * 0.2),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(s * 0.72, s * 0.46), radius: s * 0.13),
      )
      ..addRRect(
        RRect.fromLTRBR(
          s * 0.2,
          s * 0.4,
          s * 0.85,
          s * 0.58,
          Radius.circular(s * 0.09),
        ),
      );
    canvas.drawPath(
      awan,
      Paint()..color = Colors.white.withValues(alpha: k.index >= 3 ? 0.75 : 1),
    );

    final jumlah = switch (k) {
      KategoriHujan.ringan => 2,
      KategoriHujan.sedang => 3,
      _ => 4,
    };
    final tetes = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.055
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < jumlah; i++) {
      final x = s * (0.32 + 0.4 * (i + 0.5) / jumlah);
      final y0 = s * (i.isEven ? 0.68 : 0.74);
      canvas.drawLine(
        Offset(x, y0),
        Offset(x - s * 0.05, y0 + s * 0.13),
        tetes,
      );
    }

    if (k.index >= KategoriHujan.lebat.index) {
      final kilat = Path()
        ..moveTo(s * 0.58, s * 0.6)
        ..lineTo(s * 0.5, s * 0.76)
        ..lineTo(s * 0.58, s * 0.76)
        ..lineTo(s * 0.52, s * 0.92)
        ..lineTo(s * 0.66, s * 0.72)
        ..lineTo(s * 0.58, s * 0.72)
        ..close();
      canvas.drawPath(kilat, Paint()..color = const Color(0xFFF2C16B));
    }
  }

  @override
  bool shouldRepaint(_CuacaPainter old) => old.k != k;
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
          Icon(RIcons.offline, color: theme.colorScheme.onSurfaceVariant),
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
