import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

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
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _isiContoh(String username) {
    _username.text = username;
    _password.text = 'rivora';
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(Space.xl),
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: RivoraMark(size: 56),
                ),
                const SizedBox(height: Space.xl),
                Text('Masuk ke RIVORA', style: theme.textTheme.headlineMedium),
                const SizedBox(height: Space.sm),
                Text(
                  'Lapor saluran tersumbat dan pantau penanganannya '
                  'sebelum hujan datang.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xxl),
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
                          prefixIcon: Icon(Icons.person_outline_rounded),
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
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
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
                        Icon(Icons.error_outline_rounded, color: scheme.error),
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
                  _MockHint(onPick: _isiContoh),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MockHint extends StatelessWidget {
  const _MockHint({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
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
                Icons.science_outlined,
                size: 20,
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
            'Pilih peran untuk mencoba aplikasi.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onPick('petugas'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Petugas'),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onPick('warga'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Warga'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
