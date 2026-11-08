import 'ai_result.dart';
import 'jenis_saluran.dart';

/// Tugas pembersihan untuk petugas (`GET /tasks?mine=1`).
/// Dibuat lurah dari daftar prioritas sebelum hujan (proposal 3.2 langkah 3).
class Task {
  const Task({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.jenisSaluran,
    required this.lat,
    required this.lng,
    required this.ai,
    this.skorPrioritas,
    this.rw,
    this.laporanId,
    this.fotoUrl,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final saluran = json['saluran'] as Map<String, dynamic>;
    final laporan = json['laporan'] as Map<String, dynamic>? ?? const {};
    return Task(
      id: '${json['id']}',
      status: json['status'] as String? ?? 'baru',
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      skorPrioritas: (json['skor_prioritas'] as num?)?.toDouble(),
      rw: json['rw'] as String?,
      jenisSaluran:
          JenisSaluran.fromApi(saluran['jenis_saluran'] as String?) ??
          JenisSaluran.terbuka,
      lat: (saluran['lat'] as num).toDouble(),
      lng: (saluran['lng'] as num).toDouble(),
      laporanId: laporan['id']?.toString(),
      fotoUrl: laporan['foto_url'] as String?,
      ai: AiResult.fromJson(laporan['ai'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final String id;

  /// `baru` | `dikerjakan` | `selesai` (docs/API.md).
  final String status;
  final DateTime createdAt;

  /// 0–1, skor prioritas saluran saat ditugaskan (proposal 3.3).
  final double? skorPrioritas;
  final String? rw;
  final JenisSaluran jenisSaluran;
  final double lat;
  final double lng;
  final String? laporanId;
  final String? fotoUrl;
  final AiResult ai;

  bool get selesai => status == 'selesai';
}

const Map<String, String> labelStatusTugas = {
  'baru': 'Baru',
  'dikerjakan': 'Dikerjakan',
  'selesai': 'Selesai',
};
