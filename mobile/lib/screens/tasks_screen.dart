import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/task.dart';
import '../services/location_service.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/status_chip.dart';
import '../widgets/sumbatan_style.dart';
import '../widgets/motion.dart';
import 'app_shell.dart';
import 'task_detail_screen.dart';

/// Tugas petugas, diurutkan dari prioritas tertinggi (proposal 3.2 langkah 3).
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Position? _posisi;

  @override
  void initState() {
    super.initState();
    locationService.lastKnown().then((p) {
      if (mounted && p != null) setState(() => _posisi = p);
    });
  }

  double? _jarak(Task t) => _posisi == null
      ? null
      : Geolocator.distanceBetween(
          _posisi!.latitude,
          _posisi!.longitude,
          t.lat,
          t.lng,
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: taskRepository,
        builder: (context, _) {
          final repo = taskRepository;
          final aktif = repo.aktif;
          final selesai = repo.items.where((t) => t.selesai).toList();
          final theme = Theme.of(context);
          return RefreshIndicator(
            onRefresh: repo.refresh,
            edgeOffset: 152,
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(
                    aktif.isEmpty ? 'Tugas' : 'Tugas · ${aktif.length} aktif',
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Lihat di peta',
                      onPressed: () => shellTab.value = Tabs.peta,
                      icon: const Icon(Icons.map_outlined),
                    ),
                    const SizedBox(width: Space.sm),
                  ],
                ),
                if (repo.items.isEmpty && repo.loading)
                  const SliverToBoxAdapter(child: SkeletonList())
                else if (repo.items.isEmpty && repo.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Tugas gagal dimuat',
                        message: repo.error!,
                        actionLabel: 'Coba lagi',
                        onAction: repo.refresh,
                      ),
                    ),
                  )
                else if (repo.items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Belum ada tugas',
                        message:
                            'Tugas pembersihan dari kelurahan akan muncul di '
                            'sini, urut dari prioritas tertinggi.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.lg,
                      0,
                      Space.lg,
                      Space.xxl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        Text(
                          aktif.isEmpty
                              ? 'Semua tugas selesai. Terima kasih!'
                              : 'Urut dari skor prioritas tertinggi: gabungan '
                                    'prakiraan hujan, sumbatan, dan kerentanan.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: Space.lg),
                        for (var i = 0; i < aktif.length; i++) ...[
                          _TaskCard(
                            task: aktif[i],
                            rank: i + 1,
                            jarak: _jarak(aktif[i]),
                            posisi: _posisi,
                          ),
                          const SizedBox(height: Space.md),
                        ],
                        if (selesai.isNotEmpty) ...[
                          const SizedBox(height: Space.lg),
                          SectionTitle('Selesai · ${selesai.length}'),
                          for (final t in selesai) ...[
                            _TaskCard(
                              task: t,
                              jarak: _jarak(t),
                              posisi: _posisi,
                            ),
                            const SizedBox(height: Space.md),
                          ],
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

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.jarak,
    required this.posisi,
    this.rank,
  });

  final Task task;
  final int? rank;
  final double? jarak;
  final Position? posisi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskDetailScreen(task: task, posisi: posisi),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Rank(rank: rank, selesai: task.selesai),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [?task.rw, task.jenisSaluran.label].join(' · '),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.xs,
                      children: [
                        SumbatanBadge(kelas: task.ai.kelas, compact: true),
                        TugasStatusChip(status: task.status),
                      ],
                    ),
                    const SizedBox(height: Space.sm),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.xs,
                      children: [
                        if (task.skorPrioritas != null)
                          Text(
                            'Prioritas ${formatDesimal(task.skorPrioritas!)}',
                            style: muted?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        if (jarak != null)
                          Text(formatJarak(jarak!), style: muted),
                        Text(formatRelatif(task.createdAt), style: muted),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rank extends StatelessWidget {
  const _Rank({required this.rank, required this.selesai});

  final int? rank;
  final bool selesai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pertama = rank == 1;
    return Semantics(
      label: selesai ? 'Selesai' : 'Prioritas nomor $rank',
      excludeSemantics: true,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selesai
              ? context.rivora.bersih.bg
              : pertama
              ? scheme.primary
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        child: selesai
            ? Icon(
                Icons.check_rounded,
                size: 20,
                color: context.rivora.bersih.fg,
              )
            : Text(
                '$rank',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: pertama ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
      ),
    );
  }
}
