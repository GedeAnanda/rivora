import 'package:flutter/material.dart';

import '../config.dart';
import '../models/session.dart';
import '../services/repositories.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/report_tile.dart';
import '../widgets/sumbatan_style.dart';
import 'app_shell.dart';
import 'lapor_flow.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh() async {
    await Future.wait([
      reportRepository.refresh(),
      if (sessionStore.value?.isPetugas ?? false) taskRepository.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final session = sessionStore.value;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListenableBuilder(
            listenable: Listenable.merge([reportRepository, taskRepository]),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.lg,
                Space.lg,
                Space.xxl,
              ),
              children: [
                _Header(session: session),
                const SizedBox(height: Space.xl),
                _LaporCard(onTap: () => mulaiLapor(context)),
                if (session?.isPetugas ?? false) ...[
                  const SizedBox(height: Space.lg),
                  const _TugasCard(),
                ],
                const SizedBox(height: Space.xl),
                SectionTitle(
                  'Laporanmu',
                  trailing: TextButton(
                    onPressed: () => shellTab.value = Tabs.laporan,
                    child: const Text('Lihat semua'),
                  ),
                ),
                const _StatRow(),
                const SizedBox(height: Space.lg),
                ..._recent(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _recent(BuildContext context) {
    final items = reportRepository.items.take(3).toList();
    if (items.isEmpty) {
      if (reportRepository.loading) {
        return const [SkeletonList(count: 2, padding: EdgeInsets.zero)];
      }
      return const [
        EmptyState(
          icon: Icons.photo_camera_outlined,
          title: 'Belum ada laporan',
          message:
              'Saluran yang kamu foto akan muncul di sini beserta statusnya.',
        ),
      ];
    }
    return [
      for (final r in items) ...[
        ReportTile(report: r),
        const SizedBox(height: Space.sm),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final Session? session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const RivoraMark(size: 40),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${session?.nama ?? ''}',
                style: theme.textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                labelRole[session?.role] ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Akun',
          onPressed: () => _showAkun(context),
          icon: const Icon(Icons.account_circle_outlined),
          iconSize: 28,
        ),
      ],
    );
  }

  void _showAkun(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session?.nama ?? '', style: theme.textTheme.titleLarge),
              Text(
                labelRole[session?.role] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Space.lg),
              Row(
                children: [
                  Icon(
                    AppConfig.useMockApi
                        ? Icons.science_outlined
                        : Icons.cloud_done_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      AppConfig.useMockApi
                          ? 'Mode contoh (tanpa server)'
                          : 'Server: ${AppConfig.apiUrl}',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xl),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  keluar();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aksi utama aplikasi: lapor saluran.
class _LaporCard extends StatelessWidget {
  const _LaporCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Lapor saluran. Foto saluran tersumbat, lokasi tercatat otomatis.',
      excludeSemantics: true,
      child: Material(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(Radii.lg + 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lapor saluran',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      Text(
                        'Foto saluran yang tersumbat. Lokasi dan waktu '
                        'tercatat otomatis.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.lg),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: scheme.onPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: scheme.primary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ringkasan tugas untuk petugas: jumlah aktif + prioritas tertinggi.
class _TugasCard extends StatelessWidget {
  const _TugasCard();

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: taskRepository, builder: _build);

  Widget _build(BuildContext context, Widget? _) {
    final theme = Theme.of(context);
    final aktif = taskRepository.aktif;
    final teratas = aktif.isEmpty ? null : aktif.first;
    return Card(
      child: InkWell(
        onTap: () => shellTab.value = Tabs.tugas,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(
                  Icons.assignment_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aktif.isEmpty
                          ? 'Tidak ada tugas aktif'
                          : '${aktif.length} tugas menunggu',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (teratas != null) ...[
                      const SizedBox(height: Space.xs),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Teratas: ${teratas.rw ?? teratas.jenisSaluran.label}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          SumbatanBadge(kelas: teratas.ai.kelas, compact: true),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: reportRepository, builder: _build);

  Widget _build(BuildContext context, Widget? _) {
    final r = reportRepository;
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'Dikirim',
            value: r.count('dikirim') + r.count('cek_manual'),
            icon: Icons.send_rounded,
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: _Stat(
            label: 'Ditugaskan',
            value: r.count('ditugaskan'),
            icon: Icons.engineering_rounded,
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: _Stat(
            label: 'Ditangani',
            value: r.count('ditangani'),
            icon: Icons.task_alt_rounded,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value laporan',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: Space.sm),
            Text('$value', style: theme.textTheme.headlineSmall),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
