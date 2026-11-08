import 'ai_result.dart';
import 'jenis_saluran.dart';

/// Laporan saluran yang sudah diterima backend (respons `POST /reports`).
class Report {
  const Report({
    required this.id,
    required this.status,
    required this.jenisSaluran,
    required this.lat,
    required this.lng,
    required this.capturedAt,
    required this.ai,
    this.fotoUrl,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: '${json['id']}',
      status: json['status'] as String? ?? 'dikirim',
      jenisSaluran:
          JenisSaluran.fromApi(json['jenis_saluran'] as String?) ??
          JenisSaluran.terbuka,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      capturedAt: DateTime.parse(json['captured_at'] as String).toLocal(),
      fotoUrl: json['foto_url'] as String?,
      ai: AiResult.fromJson(json['ai'] as Map<String, dynamic>),
    );
  }

  final String id;

  /// `dikirim` | `ditugaskan` | `ditangani` | `cek_manual` (docs/API.md).
  final String status;
  final JenisSaluran jenisSaluran;
  final double lat;
  final double lng;
  final DateTime capturedAt;
  final String? fotoUrl;
  final AiResult ai;
}

const Map<String, String> labelStatusLaporan = {
  'dikirim': 'Dikirim',
  'ditugaskan': 'Ditugaskan ke petugas',
  'ditangani': 'Sudah ditangani',
  'cek_manual': 'Perlu cek manual',
};
