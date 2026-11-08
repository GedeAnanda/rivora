import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../models/rw_risk.dart';
import '../models/verification.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';
import '../utils/format.dart';
import 'motion.dart';
import 'risk_meter.dart';

/// "Risiko genangan di wilayahmu" (proposal Tabel 4: warga mengetahui risiko
/// di wilayahnya).
///
/// Untuk warga: kesimpulan dalam kata, meteran tiga warna, satu saran
/// tindakan, dan tiga alasan berbahasa sehari-hari. Angka dan rumus
/// (proposal 3.3, transparansi model) tetap ada di lembar "Cara menilai".
class RiskCard extends StatelessWidget {
  const RiskCard({super.key, this.posisi});

  final LatLng? posisi;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: riskRepository,
      builder: (context, _) {
        final data = riskRepository.data;
        if (data == null) {
          return riskRepository.loading
              ? const Skeleton(height: 220, radius: 20)
              : const SizedBox.shrink();
        }
        final dariPosisi = posisi == null ? null : data.rwDiTitik(posisi!);
        // Tanpa posisi (atau di luar RW pilot): tampilkan RW berisiko tertinggi.
        final rw =
            dariPosisi ??
            (data.rw.isEmpty
                ? null
                : (data.rw.toList()..sort((a, b) => b.skor.compareTo(a.skor)))
                      .first);
        if (rw == null) return const SizedBox.shrink();
        return _Isi(
          rw: rw,
          diPosisimu: dariPosisi != null,
          hujanSimulasi: data.hujanSumber == 'simulasi_demo'
              ? data.hujanMm
              : null,
        );
      },
    );
  }
}

String _saran(LevelRisiko level) => switch (level) {
  LevelRisiko.risikoTinggi =>
    'Laporkan saluran tersumbat di sekitarmu sebelum hujan, dan simpan '
        'barang penting di tempat yang lebih tinggi.',
  LevelRisiko.waspada =>
    'Cek saluran dekat rumah. Kalau ada sampah menumpuk, laporkan lewat '
        'tombol Lapor.',
  LevelRisiko.aman =>
    'Saluran di wilayahmu relatif lancar. Tetap laporkan kalau melihat '
        'saluran tersumbat.',
};

class _Isi extends StatelessWidget {
  const _Isi({required this.rw, required this.diPosisimu, this.hujanSimulasi});

  final RwRisk rw;
  final bool diPosisimu;

  /// mm hujan simulasi [DEMO] (`hujan_sumber: simulasi_demo`), wajib diberi
  /// label agar tidak tertukar dengan prakiraan asli (mobile SRS 6.3).
  final double? hujanSimulasi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warna = context.rivora.risiko(rw.level);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diPosisimu
                  ? 'Risiko genangan di wilayahmu'
                  : 'Wilayah paling berisiko',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.xs),
            Semantics(
              header: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: rw.nama,
                      style: theme.textTheme.headlineSmall,
                    ),
                    TextSpan(
                      text: '  ${rw.level.label}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: warna.fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.lg),
            RiskMeter(skor: rw.skor),
            const SizedBox(height: Space.lg),
            // Saran tindakan: pertanyaan "saya harus apa?".
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: warna.bg,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(RIcons.saran, size: 22, color: warna.fg),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      _saran(rw.level),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: warna.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (rw.hujan != null &&
                rw.sumbatan != null &&
                rw.kerentanan != null) ...[
              const SizedBox(height: Space.lg),
              Text(
                'Kenapa?',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.sm),
              _Faktor(
                ikon: RIcons.hujan,
                nilai: rw.hujan!,
                teks: switch (TingkatFaktor.dari(rw.hujan!)) {
                  TingkatFaktor.tinggi => 'Hujan deras diprediksi',
                  TingkatFaktor.sedang => 'Hujan cukup deras diprediksi',
                  TingkatFaktor.rendah => 'Hujan sedikit atau tidak hujan',
                },
              ),
              _Faktor(
                ikon: RIcons.sampah,
                nilai: rw.sumbatan!,
                teks: switch (TingkatFaktor.dari(rw.sumbatan!)) {
                  TingkatFaktor.tinggi => 'Banyak saluran tersumbat',
                  TingkatFaktor.sedang => 'Sebagian saluran tersumbat',
                  TingkatFaktor.rendah => 'Saluran relatif bersih',
                },
              ),
              _Faktor(
                ikon: RIcons.genangan,
                nilai: rw.kerentanan!,
                teks: switch (TingkatFaktor.dari(rw.kerentanan!)) {
                  TingkatFaktor.tinggi => 'Daerah rendah, sering tergenang',
                  TingkatFaktor.sedang => 'Daerah agak rendah',
                  TingkatFaktor.rendah => 'Daerah jarang tergenang',
                },
              ),
            ],
            if (hujanSimulasi != null) ...[
              const SizedBox(height: Space.sm),
              Row(
                children: [
                  Icon(RIcons.contoh, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Space.xs + 2),
                  Expanded(
                    child: Text(
                      'Mode demo: hujan disimulasikan, bukan prakiraan '
                      'saat ini.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                ),
                onPressed: () => _caraMenilai(context, rw, hujanSimulasi),
                icon: const Icon(RIcons.tanya, size: 18),
                label: const Text('Cara RIVORA menilai'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faktor extends StatelessWidget {
  const _Faktor({required this.ikon, required this.nilai, required this.teks});

  final IconData ikon;
  final double nilai;
  final String teks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tingkat = TingkatFaktor.dari(nilai);
    final warna = context.rivora.risiko(tingkat.warna);
    return Semantics(
      label: '$teks, tingkat ${tingkat.label}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs + 2),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: warna.bg,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(ikon, size: 20, color: warna.fg),
            ),
            const SizedBox(width: Space.md),
            Expanded(child: Text(teks, style: theme.textTheme.bodyLarge)),
            const SizedBox(width: Space.sm),
            _Titik(tingkat: tingkat, warna: warna.fg),
          ],
        ),
      ),
    );
  }
}

/// Tiga titik terisi sesuai tingkat (1 rendah, 2 sedang, 3 tinggi).
class _Titik extends StatelessWidget {
  const _Titik({required this.tingkat, required this.warna});

  final TingkatFaktor tingkat;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final kosong = Theme.of(context).colorScheme.outlineVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: i <= tingkat.index ? warna : kosong,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

/// Penjelasan untuk yang ingin tahu (dan juri): angka, bobot, dan rumus.
void _caraMenilai(BuildContext context, RwRisk rw, double? hujanSimulasi) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      final scheme = theme.colorScheme;
      Widget baris(String label, String bobot, double? nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Text(
              bobot,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                nilai == null ? '–' : formatDesimal(nilai),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
      );
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cara RIVORA menilai', style: theme.textTheme.titleLarge),
              const SizedBox(height: Space.sm),
              Text(
                'Risiko dihitung per RW dari tiga hal: seberapa deras hujan '
                '24 jam ke depan, seberapa banyak saluran tersumbat menurut '
                'foto laporan, dan seberapa mudah daerah itu tergenang. '
                'Hujan dan sumbatan paling berpengaruh.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: Space.lg),
              baris('Hujan', '× 0,4', rw.hujan),
              baris('Sumbatan', '× 0,4', rw.sumbatan),
              baris('Kerentanan', '× 0,2', rw.kerentanan),
              const Divider(height: Space.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Skor ${rw.nama}',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    formatDesimal(rw.skor),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: context.rivora.risiko(rw.level).fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(
                'Aman di bawah 0,40 · Waspada 0,40–0,69 · Risiko tinggi '
                '0,70 ke atas. Skor turun begitu saluran dibersihkan dan '
                'diverifikasi AI.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (hujanSimulasi != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  'Mode demo: hujan disimulasikan '
                  '${formatDesimal(hujanSimulasi, digits: 0)} mm.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
