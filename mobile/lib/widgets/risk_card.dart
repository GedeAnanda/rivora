import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../models/rw_risk.dart';
import '../models/verification.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';
import '../utils/format.dart';
import 'motion.dart';
import 'status_chip.dart';

/// "Risiko di wilayahmu": skor RW di posisi pengguna dari `GET /rw/risk`
/// (proposal Tabel 4: warga mengetahui risiko di wilayahnya; 3.3:
/// transparansi model lewat rincian komponen dan kalimat alasan).
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
              ? const Skeleton(height: 168, radius: 20)
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
                  : 'RW paling berisiko',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(rw.nama, style: theme.textTheme.headlineSmall),
                const SizedBox(width: Space.md),
                RisikoChip(level: rw.level),
                const Spacer(),
                Semantics(
                  label: 'Skor ${formatDesimal(rw.skor)} dari 1',
                  excludeSemantics: true,
                  child: AnimatedScore(
                    value: rw.skor,
                    style: theme.textTheme.headlineSmall,
                    color: warna.fg,
                  ),
                ),
              ],
            ),
            if (rw.alasan != null) ...[
              const SizedBox(height: Space.sm),
              Text(rw.alasan!, style: theme.textTheme.bodyMedium),
            ],
            if (rw.hujan != null &&
                rw.sumbatan != null &&
                rw.kerentanan != null) ...[
              const SizedBox(height: Space.lg),
              _Komponen(label: 'Hujan', bobot: 0.4, nilai: rw.hujan!),
              const SizedBox(height: Space.sm),
              _Komponen(label: 'Sumbatan', bobot: 0.4, nilai: rw.sumbatan!),
              const SizedBox(height: Space.sm),
              _Komponen(label: 'Kerentanan', bobot: 0.2, nilai: rw.kerentanan!),
            ],
            if (hujanSimulasi != null) ...[
              const SizedBox(height: Space.md),
              Row(
                children: [
                  Icon(RIcons.contoh, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Space.xs + 2),
                  Expanded(
                    child: Text(
                      'Mode demo: hujan disimulasikan '
                      '${formatDesimal(hujanSimulasi!, digits: 0)} mm, '
                      'bukan prakiraan saat ini.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(RIcons.info, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: Space.xs + 2),
                Expanded(
                  child: Text(
                    'Skor = 0,4 hujan + 0,4 sumbatan + 0,2 kerentanan. Per RW, '
                    'bukan per ruas jalan.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Komponen extends StatelessWidget {
  const _Komponen({
    required this.label,
    required this.bobot,
    required this.nilai,
  });

  final String label;
  final double bobot;
  final double nilai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final warna = context.rivora.risiko(LevelRisiko.dariSkor(nilai));
    return Semantics(
      label:
          '$label ${formatDesimal(nilai)}, bobot ${formatDesimal(bobot, digits: 1)}',
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: AnimatedBar(
              value: nilai,
              color: warna.fg,
              background: scheme.surfaceContainerHigh,
              height: 6,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              formatDesimal(nilai),
              textAlign: TextAlign.end,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
