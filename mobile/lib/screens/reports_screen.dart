import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/report_tile.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'laporan-baru',
        onPressed: () => mulaiLapor(context),
        icon: const Icon(Icons.photo_camera_rounded),
        label: const Text('Lapor'),
      ),
      body: ListenableBuilder(
        listenable: reportRepository,
        builder: (context, _) {
          final repo = reportRepository;
          final items = _filtered(repo.items);
          return RefreshIndicator(
            onRefresh: repo.refresh,
            edgeOffset: 152,
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(
                    repo.items.isEmpty
                        ? 'Laporan saya'
                        : 'Laporan saya · ${repo.items.length}',
                  ),
                ),
                if (repo.items.isEmpty && repo.loading)
                  const SliverToBoxAdapter(child: SkeletonList())
                else if (repo.items.isEmpty && repo.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Laporan gagal dimuat',
                        message: repo.error!,
                        actionLabel: 'Coba lagi',
                        onAction: repo.refresh,
                      ),
                    ),
                  )
                else if (repo.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada laporan',
                        message:
                            'Laporan yang kamu kirim akan muncul di sini, '
                            'lengkap dengan status penanganannya.',
                        actionLabel: 'Lapor saluran',
                        onAction: () => mulaiLapor(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    // Ruang bawah supaya kartu terakhir tidak tertutup FAB.
                    padding: const EdgeInsets.fromLTRB(
                      Space.lg,
                      0,
                      Space.lg,
                      96,
                    ),
                    sliver: SliverList.list(
                      children: [
                        SegmentedButton<_Filter>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: _Filter.semua,
                              label: Text('Semua'),
                            ),
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
                          onSelectionChanged: (s) =>
                              setState(() => _filter = s.first),
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
                            const SizedBox(height: Space.md),
                          ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
