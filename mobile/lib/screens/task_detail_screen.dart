import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/task.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/maps.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/common.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';
import 'lapor_flow.dart';

/// Detail tugas pembersihan untuk petugas: menuju lokasi, lalu foto sesudah
/// dibersihkan untuk verifikasi (proposal 3.2 langkah 3–4).
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task, this.posisi});

  final Task task;
  final Position? posisi;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: taskRepository,
      builder: (context, _) =>
          _build(context, taskRepository.byId(task.id) ?? task),
    );
  }

  Widget _build(BuildContext context, Task t) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selesai = context.rivora.bersih;
    final jarak = posisi == null
        ? null
        : Geolocator.distanceBetween(
            posisi!.latitude,
            posisi!.longitude,
            t.lat,
            t.lng,
          );
    final laporanId = t.laporanId;

    return Scaffold(
      appBar: AppBar(title: Text(t.rw ?? 'Detail tugas')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.lg,
          Space.xl,
        ),
        children: [
          if (t.selesai) ...[
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: selesai.bg,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: selesai.fg),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      'Selesai dan sudah diverifikasi AI',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: selesai.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
          ],
          ReportPhoto(
            file: laporanId == null
                ? null
                : reportRepository.localPhoto(laporanId),
            url: t.fotoUrl,
            height: 220,
            width: double.infinity,
            radius: Radii.lg,
            semanticLabel: 'Foto laporan ${t.jenisSaluran.label}',
          ),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    t.jenisSaluran.label,
                    trailing: TugasStatusChip(status: t.status),
                  ),
                  if (t.skorPrioritas != null) ...[
                    const SizedBox(height: Space.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatDesimal(t.skorPrioritas!),
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
                    'Ditugaskan ${formatRelatif(t.createdAt)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          AiResultCard(ai: t.ai),
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
                          formatKoordinat(t.lat, t.lng),
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
      bottomNavigationBar: t.selesai
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.lg,
                  Space.sm,
                  Space.lg,
                  Space.lg,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => bukaPeta(t.lat, t.lng, arah: true),
                        icon: const Icon(Icons.directions_walk_rounded),
                        label: const Text('Arahkan'),
                      ),
                    ),
                    const SizedBox(width: Space.md),
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () => mulaiVerifikasi(context, t),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: const Text('Foto sesudah'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
