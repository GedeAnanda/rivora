import 'ai_result.dart';
import 'jenis_saluran.dart';

DateTime? _waktu(Object? value) =>
    value is String ? DateTime.parse(value).toLocal() : null;

/// Laporan saluran dari backend: respons `POST /reports` dan item
/// `GET /reports?mine=1`. Field timeline bersifat opsional.
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
    this.rw,
    this.ditugaskanAt,
    this.ditanganiAt,
    this.petugasNama,
    this.fotoSesudahUrl,
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
      rw: json['rw'] as String?,
      ditugaskanAt: _waktu(json['ditugaskan_at']),
      ditanganiAt: _waktu(json['ditangani_at']),
      petugasNama: json['petugas_nama'] as String?,
      fotoSesudahUrl: json['foto_sesudah_url'] as String?,
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
  final String? rw;
  final DateTime? ditugaskanAt;
  final DateTime? ditanganiAt;
  final String? petugasNama;

  /// Foto bukti setelah dibersihkan (proposal Tabel 8: dikirim balik ke pelapor).
  final String? fotoSesudahUrl;

  bool get sudahDitangani => status == 'ditangani';
}

const Map<String, String> labelStatusLaporan = {
  'dikirim': 'Dikirim',
  'ditugaskan': 'Ditugaskan',
  'ditangani': 'Sudah ditangani',
  'cek_manual': 'Perlu cek manual',
};
