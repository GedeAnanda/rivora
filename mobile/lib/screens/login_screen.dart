import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
import '../theme/rivora_icons.dart';

/// Masuk petugas (mobile SRS FR-MB-07). Dibuka dari tombol "Masuk petugas"
/// di beranda; warga tidak perlu login. Hanya role `petugas` diterima.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (_loading) return;
    if (_username.text.trim().isEmpty) {
      setState(() => _error = 'Isi nama pengguna dulu.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await sessionStore.login(_username.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Masuk petugas')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.sm,
            Space.xl,
            Space.xl,
          ),
          children: [
            Text(
              'Untuk petugas kebersihan dan siskamling dengan akun dari '
              'kelurahan. Warga bisa melapor tanpa login.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.xl),
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: _username,
                    enabled: !_loading,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama pengguna',
                      prefixIcon: Icon(RIcons.akun),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  TextField(
                    controller: _password,
                    enabled: !_loading,
                    obscureText: _hidePassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _masuk(),
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: const Icon(RIcons.kunci),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword ? RIcons.lihat : RIcons.sembunyi,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.md),
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Icon(RIcons.bahaya, size: 20, color: scheme.error),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: Space.xl),
            FilledButton(
              onPressed: _loading ? null : _masuk,
              child: _loading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Masuk'),
            ),
            if (AppConfig.useMockApi) ...[
              const SizedBox(height: Space.xl),
              Container(
                padding: const EdgeInsets.all(Space.lg),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          RIcons.contoh,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Space.sm),
                        Text(
                          'Mode contoh (tanpa server)',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'Nama pengguna berisi "petugas" diterima, kata sandi '
                      'bebas. Nama lain ditolak seperti akun warga.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    OutlinedButton(
                      onPressed: () {
                        _username.text = 'petugas1';
                        _password.text = 'rivora';
                        setState(() => _error = null);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Isi akun contoh petugas'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
