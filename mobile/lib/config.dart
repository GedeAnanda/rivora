/// Konfigurasi build, diisi lewat `--dart-define`.
///
/// Contoh:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000
///   flutter run --dart-define=API_URL=https://… --dart-define=LOKASI_DEMO=true
///
/// Tanpa `API_URL`, aplikasi memakai [MockApiClient]: hasil AI contoh,
/// tanpa backend. Berguna selama backend belum siap dan sebagai mode demo.
class AppConfig {
  AppConfig._();

  static const String apiUrl = String.fromEnvironment('API_URL');

  /// `true` untuk tes di emulator, karena lokasi emulator bisa terbaca
  /// sebagai lokasi palsu. Jangan dipakai di build untuk demo/pilot.
  static const bool allowMockLocation = bool.fromEnvironment(
    'ALLOW_MOCK_LOCATION',
  );

  /// `true` hanya untuk demo di luar wilayah pilot (mis. tempat pitching).
  /// App mengirim `lokasi_demo=true` saat lapor dan verifikasi; backend
  /// dengan `DEMO_MODE` memasang laporan ke saluran demo dan melewati
  /// batas 30 m (backend SRS FR-BE-21). Hasilnya diberi label demo.
  static const bool lokasiDemo = bool.fromEnvironment('LOKASI_DEMO');

  static bool get useMockApi => apiUrl.isEmpty;
}
