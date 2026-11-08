import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../services/location_service.dart';
import 'report_form_screen.dart';

/// Kamera di dalam aplikasi. Sengaja tanpa opsi galeri (proposal 3.2 dan
/// Tabel 3): foto harus diambil langsung supaya lokasi GPS dan waktunya
/// bisa dipercaya, sehingga laporan palsu lebih sulit dibuat.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _initCamera();
    // Panaskan GPS selagi pengguna membidik, supaya saat jepret lebih cepat.
    if (mounted && _error == null) locationService.currentPosition().ignore();
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

  Future<void> _jepret() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) return;
    setState(() {
      _busy = true;
      _busyText = 'Memotret…';
    });
    try {
      final capturedAt = DateTime.now();
      final shot = await controller.takePicture();
      if (!mounted) return;
      setState(() => _busyText = 'Mengambil lokasi GPS…');
      final position = await locationService.currentPosition();
      if (position.isMocked && !AppConfig.allowMockLocation) {
        throw const LocationException(
          'Lokasi palsu terdeteksi. Matikan aplikasi pemalsu lokasi lalu foto ulang.',
        );
      }
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReportFormScreen(
            photo: File(shot.path),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Foto saluran'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Center(child: CameraPreview(controller)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ShutterBar(onPressed: _busy ? null : _jepret),
                ),
                if (_busy) _BusyOverlay(text: _busyText),
              ],
            ),
    );
  }
}

class _ShutterBar extends StatelessWidget {
  const _ShutterBar({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Arahkan ke saluran. Lokasi dan waktu tercatat otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Semantics(
              button: true,
              label: 'Ambil foto',
              child: GestureDetector(
                onTap: onPressed,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(text, style: const TextStyle(color: Colors.white)),
            ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
