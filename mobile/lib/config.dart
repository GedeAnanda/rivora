/// Konfigurasi build, diisi lewat `--dart-define`.
///
/// Contoh:
///   flutter run --dart-define=API_URL=http://10.0.2.2:3000
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

  static bool get useMockApi => apiUrl.isEmpty;
}
