import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/maps.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/common.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';

/// Detail laporan: foto sebelum/sesudah, timeline status, hasil AI, lokasi.
/// Status "sudah ditangani" + foto bukti kembali ke pelapor (proposal Tabel 8).
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final local = reportRepository.localPhoto(report.id);
    final adaSesudah = report.sudahDitangani;

    return Scaffold(
      appBar: AppBar(title: Text(report.jenisSaluran.label)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xxl,
        ),
        children: [
          if (adaSesudah)
            Row(
              children: [
                Expanded(
                  child: _LabeledPhoto(
                    label: 'Sebelum',
                    child: ReportPhoto(
                      file: local,
                      url: report.fotoUrl,
                      height: 180,
                      width: double.infinity,
                      semanticLabel: 'Foto saluran sebelum dibersihkan',
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: _LabeledPhoto(
                    label: 'Sesudah',
                    child: ReportPhoto(
                      file: reportRepository.localSesudah(report.id),
                      url: report.fotoSesudahUrl,
                      height: 180,
                      width: double.infinity,
                      semanticLabel: 'Foto bukti saluran sesudah dibersihkan',
                    ),
                  ),
                ),
              ],
            )
          else
            ReportPhoto(
              file: local,
              url: report.fotoUrl,
              height: 220,
              width: double.infinity,
              radius: Radii.lg,
              semanticLabel: 'Foto ${report.jenisSaluran.label}',
            ),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    'Status',
                    trailing: LaporanStatusChip(status: report.status),
                  ),
                  const SizedBox(height: Space.sm),
                  _Timeline(report: report),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          AiResultCard(ai: report.ai),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Lokasi'),
                  _InfoRow(
                    icon: Icons.place_outlined,
                    text: [
                      ?report.rw,
                      formatKoordinat(report.lat, report.lng),
                    ].join(' · '),
                  ),
                  const SizedBox(height: Space.sm),
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    text: 'Difoto ${formatWaktu(report.capturedAt)}',
                  ),
                  const SizedBox(height: Space.lg),
                  OutlinedButton.icon(
                    onPressed: () => bukaPeta(report.lat, report.lng),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Buka di Maps'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledPhoto extends StatelessWidget {
  const _LabeledPhoto({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Space.xs),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _Step {
  const _Step(this.title, this.subtitle, {required this.done});

  final String title;
  final String? subtitle;
  final bool done;
}

/// Timeline status: Dikirim → Ditugaskan → Ditangani.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.report});

  final Report report;

  List<_Step> get _steps {
    final r = report;
    if (r.status == 'cek_manual') {
      return [
        _Step('Dikirim', formatWaktu(r.capturedAt), done: true),
        const _Step(
          'Perlu cek manual',
          'Saluran tidak terlihat di foto. Petugas akan mengecek ke lokasi.',
          done: true,
        ),
        const _Step('Ditangani', null, done: false),
      ];
    }
    final ditugaskan = r.status == 'ditugaskan' || r.sudahDitangani;
    return [
      _Step('Dikirim', formatWaktu(r.capturedAt), done: true),
      _Step(
        'Ditugaskan',
        ditugaskan
            ? [
                if (r.petugasNama != null) 'ke ${r.petugasNama}',
                if (r.ditugaskanAt != null) formatWaktu(r.ditugaskanAt!),
              ].join(' · ')
            : 'Menunggu kelurahan menugaskan petugas',
        done: ditugaskan,
      ),
      _Step(
        'Ditangani',
        r.sudahDitangani
            ? [
                if (r.ditanganiAt != null) formatWaktu(r.ditanganiAt!),
                if (r.fotoSesudahUrl != null) 'foto bukti tersedia',
              ].join(' · ')
            : null,
        done: r.sudahDitangani,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], last: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.last});

  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = step.done ? scheme.primary : scheme.outline;
    return Semantics(
      label:
          '${step.title}, ${step.done ? 'selesai' : 'belum'}'
          '${step.subtitle == null ? '' : ', ${step.subtitle}'}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.done ? color : Colors.transparent,
                      border: Border.all(color: color, width: 2),
                    ),
                    child: step.done
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: scheme.onPrimary,
                          )
                        : null,
                  ),
                  if (!last)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: step.done ? color : scheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: step.done
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (step.subtitle != null && step.subtitle!.isNotEmpty)
                      Text(
                        step.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
