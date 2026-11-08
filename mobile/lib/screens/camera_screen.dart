import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../app_keys.dart';
import '../config.dart';
import '../models/task.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report_photo.dart';
import '../widgets/step_progress.dart';
import 'report_form_screen.dart';
import 'verify_screen.dart';
import '../theme/rivora_icons.dart';

enum _Gps { mencari, siap, gagal }

/// Kamera di dalam aplikasi. Sengaja tanpa opsi galeri (proposal 3.2 dan
/// Tabel 3): foto harus diambil langsung supaya lokasi GPS dan waktunya
/// bisa dipercaya, sehingga laporan palsu lebih sulit dibuat.
///
/// Dengan [tugas], kamera dipakai untuk foto sesudah dibersihkan
/// (verifikasi, proposal 3.2 langkah 4).
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.tugas});

  final Task? tugas;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = false;
  String? _error;
  bool _busy = false;
  String _busyText = '';
  bool _flash = false;

  _Gps _gps = _Gps.mencari;
  Position? _posisi;
  DateTime? _posisiAt;

  bool get _verifikasi => widget.tugas != null;

  /// Posisi dari pemanasan GPS dipakai langsung kalau masih segar.
  static const _posisiSegar = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pemberitahuan jangan menutupi tombol jepret.
    messengerKey.currentState?.hideCurrentSnackBar();
    layarFokus.value++;
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    layarFokus.value--;
    super.dispose();
  }

  Future<void> _start() async {
    await _initCamera();
    if (mounted && _error == null) _panaskanGps();
  }

  /// Ambil posisi selagi pengguna membidik, dan tampilkan statusnya.
  Future<void> _panaskanGps() async {
    setState(() => _gps = _Gps.mencari);
    try {
      final p = await locationService.currentPosition();
      if (!mounted) return;
      setState(() {
        _posisi = p;
        _posisiAt = DateTime.now();
        _gps = _Gps.siap;
      });
    } on LocationException {
      if (mounted) setState(() => _gps = _Gps.gagal);
    }
  }

  Future<void> _initCamera() async {
    if (_initializing) return;
    _initializing = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _error = 'Kamera tidak ditemukan di HP ini.');
        }
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final ditolak =
          e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'CameraAccessRestricted';
      setState(
        () => _error = ditolak
            ? 'Izin kamera ditolak. Izinkan kamera di pengaturan aplikasi.'
            : 'Kamera gagal dibuka (${e.code}).',
      );
    } finally {
      _initializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      if (controller == null) return;
      setState(() => _controller = null);
      controller.dispose();
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        _error == null &&
        !_busy) {
      _initCamera();
    }
  }

  Future<Position> _posisiUntukJepret() async {
    final p = _posisi;
    final at = _posisiAt;
    if (p != null &&
        at != null &&
        DateTime.now().difference(at) < _posisiSegar) {
      return p;
    }
    return locationService.currentPosition();
  }

  Future<void> _kilat() async {
    if (Motion.reduced(context)) return;
    setState(() => _flash = true);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (mounted) setState(() => _flash = false);
  }

  Future<void> _jepret() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;
    setState(() {
      _busy = true;
      _busyText = 'Memotret…';
    });
    try {
      HapticFeedback.mediumImpact();
      final capturedAt = DateTime.now();
      _kilat();
      final shot = await controller.takePicture();
      if (!mounted) return;
      setState(() => _busyText = 'Mengunci lokasi GPS…');
      final position = await _posisiUntukJepret();
      if (position.isMocked && !AppConfig.allowMockLocation) {
        throw const LocationException(
          'Lokasi palsu terdeteksi. Matikan aplikasi pemalsu lokasi lalu foto ulang.',
        );
      }
      if (!mounted) return;
      final photo = File(shot.path);
      final tugas = widget.tugas;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => tugas == null
              ? ReportFormScreen(
                  photo: photo,
                  position: position,
                  capturedAt: capturedAt,
                )
              : VerifyScreen(
                  tugas: tugas,
                  photo: photo,
                  position: position,
                  capturedAt: capturedAt,
                ),
        ),
      );
    } on LocationException catch (e) {
      _tampilkanError(e.message);
    } on CameraException catch (e) {
      _tampilkanError('Gagal memotret (${e.code}). Coba lagi.');
    } on Exception {
      _tampilkanError('Terjadi kesalahan. Coba foto ulang.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        // Dialog sistem saat jepret bisa membuat kamera ditutup; buka lagi.
        if (_controller == null && _error == null) _initCamera();
      }
    }
  }

  void _tampilkanError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final tugas = widget.tugas;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_verifikasi ? 'Foto sesudah' : 'Foto saluran'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).textTheme.titleLarge
            ?.copyWith(color: Colors.white),
      ),
      body: _error != null
          ? _ErrorView(
              message: _error!,
              onRetry: () {
                setState(() => _error = null);
                _initCamera();
              },
            )
          : controller == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Center(child: CameraPreview(controller)),
                const Positioned.fill(child: _FrameGuide()),
                Positioned(
                  left: Space.lg,
                  right: Space.lg,
                  top: Space.md,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tugas != null && tugas.fotoUrl != null) ...[
                        _SebelumThumb(url: tugas.fotoUrl!),
                        const SizedBox(width: Space.sm),
                      ],
                      if (tugas == null)
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: Space.md, top: 2),
                            child: StepProgress(langkah: 1, diAtasGelap: true),
                          ),
                        )
                      else
                        const Spacer(),
                      _GpsChip(
                        gps: _gps,
                        akurasi: _posisi?.accuracy,
                        onRetry: _panaskanGps,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ShutterBar(
                    hint: _verifikasi
                        ? 'Ambil dari sudut yang sama dengan foto sebelum.'
                        : 'Arahkan saluran ke dalam bingkai. Lokasi dan '
                              'waktu tercatat otomatis.',
                    onPressed: _busy ? null : _jepret,
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flash ? 1 : 0,
                    duration: _flash
                        ? const Duration(milliseconds: 40)
                        : const Duration(milliseconds: 220),
                    child: const ColoredBox(
                      color: Colors.white,
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
                if (_busy) _BusyOverlay(text: _busyText),
              ],
            ),
    );
  }
}

/// Sudut bingkai bidik di tengah layar.
class _FrameGuide extends StatelessWidget {
  const _FrameGuide();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xl, 72, Space.xl, 220),
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 28.0;
    const r = 10.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final corners = [
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len, 0),
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, len),
      Path()
        ..moveTo(w, h - len)
        ..lineTo(w, h - r)
        ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
        ..lineTo(w - len, h),
      Path()
        ..moveTo(len, h)
        ..lineTo(r, h)
        ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
        ..lineTo(0, h - len),
    ];
    for (final c in corners) {
      canvas.drawPath(c, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}

class _GpsChip extends StatelessWidget {
  const _GpsChip({
    required this.gps,
    required this.akurasi,
    required this.onRetry,
  });

  final _Gps gps;
  final double? akurasi;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (gps) {
      _Gps.mencari => (RIcons.gpsCari, 'Mencari GPS…', Colors.white),
      _Gps.siap => (
        RIcons.gps,
        'GPS siap · ±${akurasi?.round() ?? '-'} m',
        const Color(0xFF7BD8A6),
      ),
      _Gps.gagal => (
        RIcons.gpsMati,
        'GPS belum didapat · coba lagi',
        const Color(0xFFF2C16B),
      ),
    };
    return Semantics(
      liveRegion: true,
      button: gps == _Gps.gagal,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: gps == _Gps.gagal ? onRetry : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xB307111F),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Foto sebelum sebagai acuan sudut saat memotret sesudah dibersihkan.
class _SebelumThumb extends StatelessWidget {
  const _SebelumThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xB307111F),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportPhoto(
            url: url,
            width: 72,
            height: 72,
            radius: Radii.sm,
            semanticLabel: 'Foto sebelum sebagai acuan sudut',
          ),
          const SizedBox(height: 2),
          Text(
            'Sebelum',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ShutterBar extends StatefulWidget {
  const _ShutterBar({required this.hint, required this.onPressed});

  final String hint;
  final VoidCallback? onPressed;

  @override
  State<_ShutterBar> createState() => _ShutterBarState();
}

class _ShutterBarState extends State<_ShutterBar> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x0007111F), Color(0xE607111F)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.xxl,
            Space.xl,
            Space.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.hint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Space.lg),
              Semantics(
                button: true,
                enabled: enabled,
                label: 'Ambil foto',
                excludeSemantics: true,
                child: GestureDetector(
                  onTapDown: enabled
                      ? (_) => setState(() => _pressed = true)
                      : null,
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: enabled
                      ? (_) => setState(() => _pressed = false)
                      : null,
                  onTap: widget.onPressed,
                  child: AnimatedScale(
                    scale: _pressed ? 0.9 : 1,
                    duration: Motion.of(context, Motion.fast),
                    curve: Motion.enter,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: enabled ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: Space.lg),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(RIcons.kamera, color: Colors.white70, size: 48),
            const SizedBox(height: Space.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: Space.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(160, 52)),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
