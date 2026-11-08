import 'ai_result.dart';
import 'jenis_saluran.dart';

DateTime? _waktu(Object? value) =>
    value is String ? DateTime.parse(value).toLocal() : null;

/// Tugas pembersihan untuk petugas (backend SRS 7.9). Dibuat lurah dari
/// daftar prioritas sebelum hujan (proposal 3.2 langkah 3).
class Task {
  const Task({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.jenisSaluran,
    required this.lat,
    required this.lng,
    required this.kelasSebelum,
    this.skorSebelum,
    this.rw,
    this.saluranId,
    this.laporanId,
    this.fotoUrl,
    this.fotoSesudahUrl,
    this.catatanLurah,
    this.selesaiAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final saluran = json['saluran'] as Map<String, dynamic>;
    return Task(
      id: '${json['id']}',
      status: json['status'] as String? ?? 'baru',
      createdAt: _waktu(json['dibuat_at']) ?? DateTime.now(),
      jenisSaluran:
          JenisSaluran.fromApi(saluran['jenis'] as String?) ??
          JenisSaluran.terbuka,
      lat: (saluran['lat'] as num).toDouble(),
      lng: (saluran['lng'] as num).toDouble(),
      rw: saluran['rw_nama'] as String?,
      saluranId: saluran['id']?.toString(),
      laporanId: json['laporan_id']?.toString(),
      fotoUrl: json['foto_sebelum_url'] as String?,
      kelasSebelum: KelasSumbatan.fromApi(json['kelas_sebelum'] as String?),
      skorSebelum: (json['skor_sebelum'] as num?)?.toDouble(),
      fotoSesudahUrl: json['foto_sesudah_url'] as String?,
      catatanLurah: json['catatan'] as String?,
      selesaiAt: _waktu(json['selesai_at']),
    );
  }

  final String id;

  /// `baru` | `dikerjakan` | `selesai`.
  final String status;
  final DateTime createdAt;
  final JenisSaluran jenisSaluran;
  final double lat;
  final double lng;
  final String? rw;
  final String? saluranId;
  final String? laporanId;
  final String? fotoUrl;
  final KelasSumbatan kelasSebelum;

  /// Skor sumbatan sebelum dibersihkan, 0–1.
  final double? skorSebelum;
  final String? fotoSesudahUrl;

  /// Catatan dari lurah saat menugaskan (mobile SRS FR-MB-08).
  final String? catatanLurah;
  final DateTime? selesaiAt;

  bool get selesai => status == 'selesai';

  /// Ringkasan kondisi sebelum untuk komponen yang memakai [AiResult].
  /// Detail AI lengkap diambil dari `GET /reports/:laporan_id`.
  AiResult get ai => AiResult(
    saluranTerlihat: kelasSebelum != KelasSumbatan.tidakTerlihat,
    kelas: kelasSebelum,
    skorSumbatan: skorSebelum,
    penyebab: const [],
    keyakinan: '',
    catatan: '',
  );
}

const Map<String, String> labelStatusTugas = {
  'baru': 'Baru',
  'dikerjakan': 'Dikerjakan',
  'selesai': 'Selesai',
};
