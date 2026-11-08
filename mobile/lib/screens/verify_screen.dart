import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../app_keys.dart';
import '../config.dart';
import '../models/task.dart';
import '../models/verification.dart';
import '../services/api_client.dart';
import '../services/repositories.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/before_after.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/report_photo.dart';
import '../widgets/status_chip.dart';
import '../widgets/sumbatan_style.dart';
import 'lapor_flow.dart';

enum _Tahap { tinjau, kirim, hasil }

/// Verifikasi pembersihan (proposal 3.2 langkah 4, Tabel 3): bandingkan
/// foto sebelum–sesudah, kirim, AI menilai, skor RW diperbarui.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({
    super.key,
    required this.tugas,
    required this.photo,
    required this.position,
    required this.capturedAt,
  });

  final Task tugas;
  final File photo;
  final Position position;
  final DateTime capturedAt;

  /// Jarak maksimal dari titik saluran **[ASUMSI]**, turunan Tabel 8
  /// (foto wajib dengan GPS supaya tidak ada laporan palsu).
  static const batasJarakMeter = 100.0;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  _Tahap _tahap = _Tahap.tinjau;
  VerificationResult? _hasil;

  late final double _jarak = Geolocator.distanceBetween(
    widget.position.latitude,
    widget.position.longitude,
    widget.tugas.lat,
    widget.tugas.lng,
  );

  bool get _terlaluJauh => _jarak > VerifyScreen.batasJarakMeter;

  @override
  void initState() {
    super.initState();
    layarFokus.value++;
  }

  @override
  void dispose() {
    layarFokus.value--;
    super.dispose();
  }

  /// Mode contoh tidak memblokir, karena lokasi tugas contoh ada di Gedebage.
  bool get _diblokir => _terlaluJauh && !AppConfig.useMockApi;

  Future<void> _kirim() async {
    if (_tahap != _Tahap.tinjau || _diblokir) return;
    setState(() => _tahap = _Tahap.kirim);
    try {
      final hasil = await api.verifyTask(
        taskId: widget.tugas.id,
        foto: widget.photo,
        lat: widget.position.latitude,
        lng: widget.position.longitude,
        capturedAt: widget.capturedAt,
      );
      final updated = hasil.tugas;
      if (updated != null) {
        taskRepository.replace(updated);
      } else {
        taskRepository.refresh(silent: true);
      }
      final laporanId = widget.tugas.laporanId;
      if (hasil.sudahBersih && laporanId != null) {
        reportRepository.setLocalSesudah(laporanId, widget.photo);
      }
      reportRepository.refresh(silent: true);
      hasil.sudahBersih
          ? HapticFeedback.heavyImpact()
          : HapticFeedback.mediumImpact();
      if (!mounted) return;
      setState(() {
        _hasil = hasil;
        _tahap = _Tahap.hasil;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _tahap = _Tahap.tinjau);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _fotoUlang() => mulaiVerifikasi(context, widget.tugas, ganti: true);

  void _keDaftarTugas() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  Widget get _before {
    final laporanId = widget.tugas.laporanId;
    return ReportPhoto(
      file: laporanId == null ? null : reportRepository.localPhoto(laporanId),
      url: widget.tugas.fotoUrl,
      radius: 0,
      kelas: widget.tugas.ai.kelas,
      jenis: widget.tugas.jenisSaluran,
      semanticLabel: 'Foto sebelum dibersihkan',
    );
  }

  Widget get _after => Image.file(
    widget.photo,
    fit: BoxFit.cover,
    semanticLabel: 'Foto sesudah dibersihkan',
  );

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;
    final judul = switch (_tahap) {
      _Tahap.hasil when hasil!.sudahBersih => 'Verifikasi selesai',
      _Tahap.hasil => 'Belum bersih',
      _ => 'Verifikasi pembersihan',
    };
    return PopScope(
      canPop: _tahap != _Tahap.kirim,
      child: Scaffold(
        appBar: AppBar(
          title: Text(judul),
          automaticallyImplyLeading: _tahap == _Tahap.tinjau,
          leading: _tahap == _Tahap.hasil
              ? IconButton(
                  tooltip: 'Tutup',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _keDaftarTugas,
                )
              : null,
        ),
        body: AnimatedSwitcher(
          duration: Motion.of(context, Motion.normal),
          switchInCurve: Motion.enter,
          switchOutCurve: Motion.exit,
          child: hasil == null
              ? _Tinjau(
                  key: const ValueKey('tinjau'),
                  tugas: widget.tugas,
                  before: _before,
                  after: _after,
                  mengirim: _tahap == _Tahap.kirim,
                  jarak: _jarak,
                  terlaluJauh: _terlaluJauh,
                  diblokir: _diblokir,
                  capturedAt: widget.capturedAt,
                )
              : _Hasil(
                  key: const ValueKey('hasil'),
                  hasil: hasil,
                  before: _before,
                  after: _after,
                ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.sm,
              Space.lg,
              Space.lg,
            ),
            child: switch (_tahap) {
              _Tahap.tinjau || _Tahap.kirim => Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _tahap == _Tahap.kirim ? null : _fotoUlang,
                      child: const Text('Foto ulang'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: _tahap == _Tahap.kirim || _diblokir
                          ? null
                          : _kirim,
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(
                        _tahap == _Tahap.kirim
                            ? 'Memeriksa…'
                            : 'Kirim verifikasi',
                      ),
                    ),
                  ),
                ],
              ),
              _Tahap.hasil when hasil!.sudahBersih => FilledButton(
                onPressed: _keDaftarTugas,
                child: const Text('Kembali ke daftar tugas'),
              ),
              _Tahap.hasil => Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _keDaftarTugas,
                      child: const Text('Nanti'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: _fotoUlang,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Foto ulang'),
                    ),
                  ),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Tinjau extends StatelessWidget {
  const _Tinjau({
    super.key,
    required this.tugas,
    required this.before,
    required this.after,
    required this.mengirim,
    required this.jarak,
    required this.terlaluJauh,
    required this.diblokir,
    required this.capturedAt,
  });

  final Task tugas;
  final Widget before;
  final Widget after;
  final bool mengirim;
  final double jarak;
  final bool terlaluJauh;
  final bool diblokir;
  final DateTime capturedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rv = context.rivora;
    final lokasiWarna = terlaluJauh ? rv.waspada : rv.bersih;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.sm,
        Space.lg,
        Space.xl,
      ),
      children: [
        Stack(
          children: [
            BeforeAfterCompare(before: before, after: after),
            if (mengirim)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  child: const ScanOverlay(label: 'AI membandingkan foto…'),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Icon(Icons.swipe_rounded, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: Space.xs + 2),
            Text(
              'Geser atau ketuk foto untuk membandingkan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Bukti pembersihan'),
                Container(
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: lokasiWarna.bg,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        terlaluJauh
                            ? Icons.wrong_location_outlined
                            : Icons.where_to_vote_rounded,
                        color: lokasiWarna.fg,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              terlaluJauh
                                  ? '${formatJarak(jarak)} dari titik saluran'
                                  : 'Di lokasi saluran · ${formatJarak(jarak)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: lokasiWarna.fg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (terlaluJauh)
                              Text(
                                diblokir
                                    ? 'Foto sesudah harus diambil di lokasi '
                                          '(maks. ${VerifyScreen.batasJarakMeter.round()} m).'
                                    : 'Mode contoh: jarak tidak diperiksa.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: lokasiWarna.fg,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.md),
                _Info(
                  icon: Icons.schedule_rounded,
                  text: 'Difoto ${formatWaktu(capturedAt)}',
                ),
                const SizedBox(height: Space.sm),
                _Info(
                  icon: Icons.place_outlined,
                  text: [?tugas.rw, tugas.jenisSaluran.label].join(' · '),
                ),
                const SizedBox(height: Space.sm),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Space.sm),
                    Text('Sebelum: ', style: theme.textTheme.bodyMedium),
                    SumbatanBadge(kelas: tugas.ai.kelas, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Hasil extends StatelessWidget {
  const _Hasil({
    super.key,
    required this.hasil,
    required this.before,
    required this.after,
  });

  final VerificationResult hasil;
  final Widget before;
  final Widget after;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rv = context.rivora;
    final bersih = hasil.sudahBersih;
    final aksen = bersih ? rv.bersih : rv.sedang;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.sm,
        Space.lg,
        Space.xl,
      ),
      children: [
        Semantics(
          liveRegion: true,
          child: Column(
            children: [
              _PopIn(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: aksen.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    bersih ? Icons.check_rounded : Icons.priority_high_rounded,
                    size: 40,
                    color: aksen.fg,
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              Text(
                bersih ? 'Saluran sudah bersih' : 'Masih ada sumbatan',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: Space.xs),
              Text(
                bersih
                    ? 'AI membandingkan foto sebelum dan sesudah. Tugas '
                          'tercatat selesai dan pelapor melihat foto buktinya.'
                    : 'Bersihkan bagian yang tersisa, lalu foto ulang dari '
                          'sudut yang sama.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        if (bersih && hasil.adaPerubahanSkor) ...[
          _SkorRw(hasil: hasil),
          const SizedBox(height: Space.lg),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Penilaian AI sesudah dibersihkan'),
                SumbatanBadge(kelas: hasil.kelasSesudah),
                if (hasil.catatan.isNotEmpty) ...[
                  const SizedBox(height: Space.md),
                  Text(hasil.catatan, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: Space.md),
                Text(
                  'Keyakinan ${hasil.keyakinan}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        BeforeAfterCompare(before: before, after: after),
      ],
    );
  }
}

/// Skor risiko RW turun setelah saluran dibersihkan: angka menghitung mundur,
/// bar memendek, level berubah (mis. Risiko tinggi → Waspada).
class _SkorRw extends StatelessWidget {
  const _SkorRw({required this.hasil});

  final VerificationResult hasil;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sebelum = hasil.skorRwSebelum!;
    final sesudah = hasil.skorRwSesudah!;
    final levelSebelum = LevelRisiko.dariSkor(sebelum);
    final levelSesudah = LevelRisiko.dariSkor(sesudah);
    final warna = context.rivora.risiko(levelSesudah);

    return Semantics(
      label:
          'Skor risiko ${hasil.rw ?? 'RW'} turun dari ${formatDesimal(sebelum)} '
          'ke ${formatDesimal(sesudah)}, level ${levelSesudah.label}',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skor risiko ${hasil.rw ?? 'RW'}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: Space.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedScore(
                    from: sebelum,
                    value: sesudah,
                    style: theme.textTheme.headlineMedium?.copyWith(height: 1),
                    color: warna.fg,
                  ),
                  const SizedBox(width: Space.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      'dari ${formatDesimal(sebelum)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.sm),
              AnimatedBar(
                from: sebelum,
                value: sesudah,
                color: warna.fg,
                background: warna.bg,
                height: 10,
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  RisikoChip(level: levelSebelum),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  RisikoChip(level: levelSesudah),
                ],
              ),
              const SizedBox(height: Space.md),
              Text(
                'Sumbatan turun, jadi skor ikut turun '
                '(0,4 × hujan + 0,4 × sumbatan + 0,2 × kerentanan).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Space.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Muncul dengan sedikit memantul. Langsung tampil kalau animasi dimatikan.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: Motion.of(context, Motion.reveal),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: child,
    );
  }
}
