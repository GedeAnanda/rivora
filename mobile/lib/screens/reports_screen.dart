import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/report_tile.dart';
import '../widgets/motion.dart';
import 'lapor_flow.dart';

enum _Filter { semua, diproses, ditangani }

/// Laporan saya: semua laporan pengguna beserta statusnya.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _Filter _filter = _Filter.semua;

  List<Report> _filtered(List<Report> items) => switch (_filter) {
    _Filter.semua => items,
    _Filter.diproses => items.where((r) => !r.sudahDitangani).toList(),
    _Filter.ditangani => items.where((r) => r.sudahDitangani).toList(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan saya')),
      body: ListenableBuilder(
        listenable: reportRepository,
        builder: (context, _) {
          final repo = reportRepository;
          if (repo.items.isEmpty && repo.loading) {
            return const SkeletonList();
          }
          if (repo.items.isEmpty && repo.error != null) {
            return Center(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Laporan gagal dimuat',
                message: repo.error!,
                actionLabel: 'Coba lagi',
                onAction: repo.refresh,
              ),
            );
          }
          if (repo.items.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada laporan',
                message:
                    'Laporan yang kamu kirim akan muncul di sini, lengkap '
                    'dengan status penanganannya.',
                actionLabel: 'Lapor saluran',
                onAction: () => mulaiLapor(context),
              ),
            );
          }
          final items = _filtered(repo.items);
          return RefreshIndicator(
            onRefresh: repo.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.lg,
                Space.xxl,
              ),
              children: [
                SegmentedButton<_Filter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: _Filter.semua, label: Text('Semua')),
                    ButtonSegment(
                      value: _Filter.diproses,
                      label: Text('Diproses'),
                    ),
                    ButtonSegment(
                      value: _Filter.ditangani,
                      label: Text('Ditangani'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: Space.lg),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.filter_list_off_rounded,
                    title: 'Tidak ada laporan di sini',
                    message: 'Coba pilih filter lain.',
                  )
                else
                  for (final r in items) ...[
                    ReportTile(report: r),
                    const SizedBox(height: Space.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
