/// Kelas sumbatan dari AI vision (proposal 3.2 dan Lampiran C).
enum KelasSumbatan {
  bersih('bersih', 'Bersih'),
  ringan('ringan', 'Sumbatan ringan'),
  sedang('sedang', 'Sumbatan sedang'),
  berat('berat', 'Sumbatan berat'),
  tidakTerlihat('tidak_terlihat', 'Tidak terlihat');

  const KelasSumbatan(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Nilai yang tidak dikenal dianggap "tidak terlihat" supaya laporan
  /// masuk jalur cek manual, bukan diam-diam dihitung sebagai bersih.
  static KelasSumbatan fromApi(String? value) {
    for (final kelas in values) {
      if (kelas.apiValue == value) return kelas;
    }
    return KelasSumbatan.tidakTerlihat;
  }
}

/// Keluaran analisis AI untuk satu foto, format Lampiran C proposal.
class AiResult {
  const AiResult({
    required this.saluranTerlihat,
    required this.kelas,
    required this.skorSumbatan,
    required this.penyebab,
    required this.keyakinan,
    required this.catatan,
    this.jenisSaluran,
  });

  factory AiResult.fromJson(Map<String, dynamic> json) {
    return AiResult(
      jenisSaluran: json['jenis_saluran'] as String?,
      saluranTerlihat: json['saluran_terlihat'] as bool? ?? false,
      kelas: KelasSumbatan.fromApi(json['kelas_sumbatan'] as String?),
      skorSumbatan: (json['skor_sumbatan'] as num?)?.toDouble(),
      penyebab: [
        for (final p in (json['penyebab'] as List<dynamic>? ?? const []))
          p.toString(),
      ],
      keyakinan: json['keyakinan'] as String? ?? 'rendah',
      catatan: json['catatan'] as String? ?? '',
    );
  }

  final String? jenisSaluran;
  final bool saluranTerlihat;
  final KelasSumbatan kelas;

  /// 0–1. Bisa `null` kalau saluran tidak terlihat.
  final double? skorSumbatan;
  final List<String> penyebab;

  /// `rendah` | `sedang` | `tinggi`. Selalu ditampilkan (proposal Tabel 8).
  final String keyakinan;
  final String catatan;

  /// Saluran tertutup atau tidak jelas → harus dicek manual (proposal 3.2).
  bool get perluCekManual =>
      kelas == KelasSumbatan.tidakTerlihat || !saluranTerlihat;

  Map<String, dynamic> toJson() => {
    'jenis_saluran': jenisSaluran,
    'saluran_terlihat': saluranTerlihat,
    'kelas_sumbatan': kelas.apiValue,
    'skor_sumbatan': skorSumbatan,
    'penyebab': penyebab,
    'keyakinan': keyakinan,
    'catatan': catatan,
  };
}

const Map<String, String> labelPenyebab = {
  'plastik': 'Plastik',
  'sedimen': 'Sedimen',
  'daun_ranting': 'Daun & ranting',
  'puing': 'Puing',
};
