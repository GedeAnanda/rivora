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
import '../theme/rivora_icons.dart';

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
            edgeOffset: 112,
            child: CustomScrollView(
              slivers: [
                SliverAppBar.medium(
                  title: Text(
                    aktif.isEmpty ? 'Tugas' : 'Tugas · ${aktif.length} aktif',
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Lihat di peta',
                      onPressed: () => shellTab.value = Tabs.peta,
                      icon: const Icon(RIcons.peta),
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
                        icon: RIcons.offline,
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
                        icon: RIcons.tugas,
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
                              : 'Urut dari sumbatan terparah, lalu yang paling '
                                    'lama ditugaskan. Tarik ke bawah untuk muat ulang.',
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
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.lg,
            Space.md,
            Space.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Nomor(rank: rank, selesai: task.selesai),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [?task.rw, task.jenisSaluran.label].join(' · '),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: Space.xs + 2),
                    Wrap(
                      spacing: Space.md,
                      runSpacing: Space.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SumbatanBadge(kelas: task.kelasSebelum, compact: true),
                        TugasStatusChip(status: task.status),
                      ],
                    ),
                    if (task.catatanLurah != null) ...[
                      const SizedBox(height: Space.sm),
                      Text(
                        task.catatanLurah!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: Space.sm),
                    Text(
                      [
                        'Ditugaskan ${formatRelatif(task.createdAt)}',
                        if (jarak != null) formatJarak(jarak!),
                      ].join(' · '),
                      style: muted,
                    ),
                  ],
                ),
              ),
              Icon(RIcons.chevron, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nomor urut tugas aktif (angka saja, tanpa kotak berwarna).
class _Nomor extends StatelessWidget {
  const _Nomor({required this.rank, required this.selesai});

  final int? rank;
  final bool selesai;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: selesai ? 'Selesai' : 'Nomor $rank',
      excludeSemantics: true,
      child: SizedBox(
        width: 32,
        child: selesai
            ? Icon(RIcons.selesai, size: 22, color: context.rivora.bersih.fg)
            : Text(
                '$rank',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  height: 1,
                  color: rank == 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
