import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../models/report.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/maps.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/common.dart';
import '../widgets/lokasi_mini.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';
import '../theme/rivora_icons.dart';

/// Detail laporan: foto sebelum/sesudah, timeline status, hasil AI, lokasi.
/// Status "sudah ditangani" + foto bukti kembali ke pelapor (proposal Tabel 8).
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.report});

  final Report report;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Status terbaru dari backend (mobile SRS FR-MB-06).
    reportRepository.refreshOne(widget.report.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: reportRepository,
    builder: (context, _) => _build(
      context,
      reportRepository.byId(widget.report.id) ?? widget.report,
    ),
  );

  Widget _build(BuildContext context, Report report) {
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
          if (report.hasilDemo || report.lokasiDemo || report.digabung) ...[
            LabelLaporan(report: report),
            const SizedBox(height: Space.md),
          ],
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
                      kelas: report.ai.kelas,
                      jenis: report.jenisSaluran,
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
                      kelas: KelasSumbatan.bersih,
                      jenis: report.jenisSaluran,
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
              kelas: report.ai.kelas,
              jenis: report.jenisSaluran,
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
                  LokasiMini(
                    lat: report.lat,
                    lng: report.lng,
                    rw: report.rw,
                    kelas: report.kelasKini,
                    keterangan: 'Difoto ${formatWaktu(report.capturedAt)}',
                  ),
                  const SizedBox(height: Space.lg),
                  OutlinedButton.icon(
                    onPressed: () => bukaPeta(report.lat, report.lng),
                    icon: const Icon(RIcons.peta),
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
    final ditugaskan = r.ditugaskan || r.sudahDitangani;
    return [
      _Step('Dikirim', formatWaktu(r.capturedAt), done: true),
      _Step(
        'Ditugaskan',
        ditugaskan
            ? (r.petugasNama == null
                  ? 'Petugas sudah ditugaskan'
                  : 'ke ${r.petugasNama}')
            : 'Menunggu kelurahan menugaskan petugas',
        done: ditugaskan,
      ),
      _Step(
        'Ditangani',
        r.sudahDitangani
            ? [
                if (r.ditanganiAt != null) formatWaktu(r.ditanganiAt!),
                if (r.kelasSesudah != null)
                  'sesudah: ${r.kelasSesudah!.label.toLowerCase()}',
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
                            RIcons.centang,
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

/// Label kejujuran untuk juri dan pengguna (mobile SRS 6.3) dan info laporan
/// yang digabung (proposal Tabel 8).
class LabelLaporan extends StatelessWidget {
  const LabelLaporan({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final baris = <(IconData, String)>[
      if (report.hasilDemo) (RIcons.contoh, 'Hasil contoh (mode demo)'),
      if (report.lokasiDemo)
        (RIcons.lokasi, 'Lokasi dipetakan ke saluran contoh'),
      if (report.digabung)
        (RIcons.info, 'Digabung dengan laporan lain di saluran yang sama'),
    ];
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (ikon, teks) in baris)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(ikon, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(teks, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
