import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/report.dart';
import '../models/task.dart';
import '../services/api_client.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';
import '../utils/format.dart';
import '../utils/maps.dart';
import '../widgets/ai_result_card.dart';
import '../widgets/common.dart';
import '../widgets/lokasi_mini.dart';
import '../widgets/motion.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';
import '../widgets/sumbatan_style.dart';
import 'lapor_flow.dart';

/// Detail tugas pembersihan (mobile SRS FR-MB-08): foto sebelum + kelas,
/// catatan dari lurah, waktu ditugaskan, Buka di peta, Mulai kerjakan (P2),
/// dan Foto sesudah (FR-MB-10).
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task, this.posisi});

  final Task task;
  final Position? posisi;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  /// Detail AI lengkap dari laporan asal (`GET /reports/:laporan_id`).
  late final Future<Report?> _laporan = _muatLaporan();
  bool _mengubah = false;

  Future<Report?> _muatLaporan() async {
    final id = widget.task.laporanId;
    if (id == null) return null;
    try {
      return await api.getReport(id);
    } on ApiException {
      return null;
    }
  }

  Future<void> _mulaiKerjakan(Task t) async {
    setState(() => _mengubah = true);
    try {
      taskRepository.replace(await api.updateTaskStatus(t.id, 'dikerjakan'));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status tugas: sedang dikerjakan.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _mengubah = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: taskRepository,
      builder: (context, _) =>
          _build(context, taskRepository.byId(widget.task.id) ?? widget.task),
    );
  }

  Widget _build(BuildContext context, Task t) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final posisi = widget.posisi;
    final jarak = posisi == null
        ? null
        : Geolocator.distanceBetween(
            posisi.latitude,
            posisi.longitude,
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
            _Banner(
              warna: context.rivora.bersih,
              ikon: RIcons.verifikasi,
              teks: t.selesaiAt == null
                  ? 'Selesai dan sudah diverifikasi AI'
                  : 'Selesai ${formatWaktu(t.selesaiAt!)} · terverifikasi AI',
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
            kelas: t.kelasSebelum,
            jenis: t.jenisSaluran,
            semanticLabel: 'Foto sebelum ${t.jenisSaluran.label}',
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
                  Text(
                    'Ditugaskan ${formatRelatif(t.createdAt)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (t.catatanLurah != null) ...[
                    const SizedBox(height: Space.lg),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Space.md),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan dari kelurahan',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            t.catatanLurah!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          FutureBuilder<Report?>(
            future: _laporan,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Skeleton(height: 180, radius: Radii.xl);
              }
              final r = snap.data;
              if (r != null) return AiResultCard(ai: r.ai);
              // Laporan asal tidak bisa dimuat: tampilkan kondisi sebelum
              // dari objek tugas saja (kelas + skor), tanpa mengarang
              // penyebab.
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('Kondisi sebelum'),
                      SumbatanBadge(kelas: t.kelasSebelum),
                      const SizedBox(height: Space.xs),
                      Text(
                        kataSumbatan(t.kelasSebelum),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Lokasi'),
                  LokasiMini(
                    lat: t.lat,
                    lng: t.lng,
                    rw: t.rw,
                    kelas: t.kelasSebelum,
                    keterangan: jarak == null
                        ? null
                        : '${formatJarak(jarak)} dari posisimu',
                  ),
                  const SizedBox(height: Space.md),
                  OutlinedButton.icon(
                    onPressed: () => bukaPeta(t.lat, t.lng, arah: true),
                    icon: const Icon(RIcons.arahkan, size: 18),
                    label: const Text('Arahkan ke lokasi'),
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
                child: _TombolBawah(
                  mulai: t.status == 'baru'
                      ? OutlinedButton(
                          onPressed: _mengubah ? null : () => _mulaiKerjakan(t),
                          child: Text(
                            _mengubah ? 'Menyimpan…' : 'Mulai kerjakan',
                            maxLines: 1,
                          ),
                        )
                      : null,
                  foto: FilledButton.icon(
                    onPressed: () => mulaiVerifikasi(context, t),
                    icon: const Icon(RIcons.kamera, size: 18),
                    label: const Text('Foto sesudah', maxLines: 1),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Foto sesudah (+ Mulai kerjakan kalau tugas masih baru).
class _TombolBawah extends StatelessWidget {
  const _TombolBawah({required this.foto, this.mulai});

  final Widget foto;
  final Widget? mulai;

  @override
  Widget build(BuildContext context) {
    final mulai = this.mulai;
    if (mulai == null) return SizedBox(width: double.infinity, child: foto);
    return TombolBerpasangan(sekunder: mulai, utama: foto);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.warna, required this.ikon, required this.teks});

  final StatusColor warna;
  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: warna.bg,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(ikon, color: warna.fg),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              teks,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: warna.fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
