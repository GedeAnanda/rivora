import 'dart:io';

import 'package:flutter/material.dart';

import '../models/report.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/common.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';
import 'app_shell.dart';
import 'camera_screen.dart';
import 'report_detail_screen.dart';
import '../theme/rivora_icons.dart';

/// Hasil analisis AI untuk laporan yang baru dikirim.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.report, required this.photo});

  final Report report;
  final File photo;

  void _lihatStatus(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    shellTab.value = Tabs.laporan;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cekManual = report.ai.perluCekManual;
    final accent = cekManual
        ? context.rivora.tidakTerlihat
        : context.rivora.bersih;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan terkirim'),
        leading: IconButton(
          tooltip: 'Tutup',
          icon: const Icon(RIcons.tutup),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: accent.bg,
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReportPhoto(
                  file: photo,
                  width: 72,
                  height: 72,
                  radius: Radii.sm,
                  semanticLabel: 'Foto saluran yang dilaporkan',
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            cekManual ? RIcons.tidakTerlihat : RIcons.selesai,
                            size: 20,
                            color: accent.fg,
                          ),
                          const SizedBox(width: Space.xs + 2),
                          Expanded(
                            child: Text(
                              cekManual
                                  ? 'Perlu dicek manual'
                                  : 'Laporan diterima',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: accent.fg,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        cekManual
                            ? 'Saluran tidak terlihat jelas di foto. Petugas '
                                  'akan mengecek langsung ke lokasi.'
                            : 'Kelurahan melihat laporan ini di peta risiko '
                                  'dan daftar prioritas sebelum hujan.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      LaporanStatusChip(status: report.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.lg),
          if (report.hasilDemo || report.lokasiDemo || report.digabung) ...[
            LabelLaporan(report: report),
            const SizedBox(height: Space.lg),
          ],
          AiResultCard(ai: report.ai),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.lg,
            Space.sm,
            Space.lg,
            Space.lg,
          ),
          child: TombolBerpasangan(
            rata: true,
            sekunder: OutlinedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const CameraScreen()),
              ),
              child: const Text('Lapor lagi'),
            ),
            utama: FilledButton(
              onPressed: () => _lihatStatus(context),
              child: const Text('Lihat status'),
            ),
          ),
        ),
      ),
    );
  }
}
