/// Jenis saluran yang dipilih pelapor (proposal 3.2, langkah 1).
/// Nilai `apiValue` mengikuti enum di docs/API.md.
enum JenisSaluran {
  terbuka('terbuka', 'Saluran terbuka'),
  gorongGorong('gorong_gorong', 'Gorong-gorong'),
  inletJalan('inlet_jalan', 'Inlet jalan');

  const JenisSaluran(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static JenisSaluran? fromApi(String? value) {
    for (final jenis in values) {
      if (jenis.apiValue == value) return jenis;
    }
    return null;
  }
}
