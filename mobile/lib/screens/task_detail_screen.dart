import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/maps.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/common.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';

/// Detail tugas pembersihan untuk petugas.
/// Foto sesudah (verifikasi) ditambahkan di tahap 03.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task, this.posisi});

  final Task task;
  final Position? posisi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final jarak = posisi == null
        ? null
        : Geolocator.distanceBetween(
            posisi!.latitude,
            posisi!.longitude,
            task.lat,
            task.lng,
          );

    return Scaffold(
      appBar: AppBar(title: Text(task.rw ?? 'Detail tugas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xl,
        ),
        children: [
          ReportPhoto(
            url: task.fotoUrl,
            height: 220,
            radius: Radii.lg,
            semanticLabel: 'Foto laporan ${task.jenisSaluran.label}',
          ),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    task.jenisSaluran.label,
                    trailing: TugasStatusChip(status: task.status),
                  ),
                  if (task.skorPrioritas != null) ...[
                    const SizedBox(height: Space.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatDesimal(task.skorPrioritas!),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: Space.sm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'skor prioritas',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'Gabungan prakiraan hujan, sumbatan, dan kerentanan lokasi.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  Text(
                    'Ditugaskan ${formatRelatif(task.createdAt)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          AiResultCard(ai: task.ai),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Lokasi'),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          formatKoordinat(task.lat, task.lng),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (jarak != null)
                        Text(
                          formatJarak(jarak),
                          style: theme.textTheme.labelLarge,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: task.selesai
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.sm,
                  Space.lg,
                  Space.lg,
                ),
                child: FilledButton.icon(
                  onPressed: () => bukaPeta(task.lat, task.lng, arah: true),
                  icon: const Icon(Icons.directions_walk_rounded),
                  label: const Text('Arahkan ke lokasi'),
                ),
              ),
            ),
    );
  }
}
