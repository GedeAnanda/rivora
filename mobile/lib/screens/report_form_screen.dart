import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/jenis_saluran.dart';
import '../services/api_client.dart';
import '../utils/format.dart';
import 'camera_screen.dart';
import 'result_screen.dart';

/// Konfirmasi laporan: foto, lokasi & waktu otomatis, pilih jenis saluran.
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.photo,
    required this.position,
    required this.capturedAt,
  });

  final File photo;
  final Position position;
  final DateTime capturedAt;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  JenisSaluran? _jenis;
  bool _sending = false;

  Future<void> _kirim() async {
    final jenis = _jenis;
    if (jenis == null || _sending) return;
    setState(() => _sending = true);
    try {
      final report = await api.submitReport(
        foto: widget.photo,
        lat: widget.position.latitude,
        lng: widget.position.longitude,
        capturedAt: widget.capturedAt,
        jenisSaluran: jenis,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(report: report, photo: widget.photo),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _fotoUlang() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pos = widget.position;
    return Scaffold(
      appBar: AppBar(title: const Text('Kirim laporan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(widget.photo, height: 260, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(formatKoordinat(pos.latitude, pos.longitude)),
                  subtitle: Text('Akurasi ±${pos.accuracy.round()} m'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(formatWaktu(widget.capturedAt)),
                  subtitle: const Text('Dicatat otomatis saat memotret'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Jenis saluran', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final jenis in JenisSaluran.values)
                ChoiceChip(
                  label: Text(jenis.label),
                  // Tanpa centang supaya lebar chip tetap dan tata letak
                  // tidak bergeser saat dipilih.
                  showCheckmark: false,
                  selected: _jenis == jenis,
                  onSelected: _sending
                      ? null
                      : (_) => setState(() => _jenis = jenis),
                ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _jenis == null || _sending ? null : _kirim,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_sending ? 'Menganalisis foto…' : 'Kirim laporan'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          if (_jenis == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Pilih jenis saluran dulu.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _sending ? null : _fotoUlang,
            icon: const Icon(Icons.replay),
            label: const Text('Foto ulang'),
          ),
        ],
      ),
    );
  }
}
