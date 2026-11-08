import 'package:flutter/material.dart';

import '../models/report.dart';
import '../screens/report_detail_screen.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'report_photo.dart';
import 'status_chip.dart';
import 'sumbatan_style.dart';
import '../theme/rivora_icons.dart';

/// Satu baris laporan di daftar: foto, jenis + waktu, kelas, status.
class ReportTile extends StatelessWidget {
  const ReportTile({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lokasi = report.rw ?? formatKoordinat(report.lat, report.lng);
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReportDetailScreen(report: report),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(
            children: [
              ReportPhoto(
                file: reportRepository.localPhoto(report.id),
                url: report.fotoUrl,
                width: 72,
                height: 72,
                radius: Radii.sm,
                kelas: report.kelasKini,
                jenis: report.jenisSaluran,
                semanticLabel: 'Foto ${report.jenisSaluran.label}',
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.jenisSaluran.label,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$lokasi · ${formatRelatif(report.capturedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      children: [
                        SumbatanBadge(kelas: report.kelasKini, compact: true),
                        LaporanStatusChip(status: report.status),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(RIcons.chevron, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
