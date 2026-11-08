import 'dart:io';

import 'package:flutter/material.dart';

import '../models/ai_result.dart';
import '../models/report.dart';
import '../utils/format.dart';
import '../widgets/sumbatan_style.dart';
import 'camera_screen.dart';

/// Hasil analisis AI untuk laporan yang baru dikirim.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.report, required this.photo});

  final Report report;
  final File photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ai = report.ai;
    final skor = ai.skorSumbatan;
    final warna = warnaSumbatan(ai.kelas);

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil analisis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (ai.perluCekManual) ...[
            Card(
              color: Colors.amber.shade50,
              child: const ListTile(
                leading: Icon(Icons.visibility_off, color: Colors.brown),
                title: Text('Perlu dicek manual'),
                subtitle: Text(
                  'Saluran tidak terlihat jelas di foto. Petugas akan '
                  'mengecek langsung ke lokasi.',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      photo,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SumbatanBadge(kelas: ai.kelas),
                        const SizedBox(height: 8),
                        Text(
                          report.jenisSaluran.label,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (skor != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: skor.clamp(0, 1),
                              minHeight: 8,
                              color: warna,
                              backgroundColor: warna.withValues(alpha: 0.15),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Skor sumbatan ${formatDesimal(skor)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Penyebab'),
                  subtitle: ai.penyebab.isEmpty
                      ? const Text('Tidak ada penyebab dominan')
                      : Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final p in ai.penyebab)
                                Chip(
                                  label: Text(labelPenyebab[p] ?? p),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ),
                ),
                ListTile(
                  leading: const Icon(Icons.psychology_outlined),
                  title: const Text('Keyakinan AI'),
                  subtitle: Text(_labelKeyakinan(ai.keyakinan)),
                ),
                if (ai.catatan.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Catatan AI'),
                    subtitle: Text(ai.catatan),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Status laporan'),
                  subtitle: Text(
                    labelStatusLaporan[report.status] ?? report.status,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(formatKoordinat(report.lat, report.lng)),
                  subtitle: Text(formatWaktu(report.capturedAt)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const CameraScreen()),
            ),
            icon: const Icon(Icons.photo_camera),
            label: const Text('Lapor saluran lain'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Kembali ke beranda'),
          ),
        ],
      ),
    );
  }

  static String _labelKeyakinan(String keyakinan) => switch (keyakinan) {
    'tinggi' => 'Tinggi',
    'sedang' => 'Sedang',
    _ => 'Rendah: hasil perlu dikonfirmasi petugas',
  };
}
