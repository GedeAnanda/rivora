import 'ai_result.dart';
import 'task.dart';

/// Level risiko RW (proposal 3.2 langkah 2). Batas skor mengikuti
/// docs/RENCANA_FINAL.md bagian 4 [ASUMSI]: aman < 0,40 · waspada < 0,70.
enum LevelRisiko {
  aman('Aman'),
  waspada('Waspada'),
  risikoTinggi('Risiko tinggi');

  const LevelRisiko(this.label);

  final String label;

  static LevelRisiko dariSkor(double skor) => skor < 0.40
      ? LevelRisiko.aman
      : skor < 0.70
      ? LevelRisiko.waspada
      : LevelRisiko.risikoTinggi;
}

/// Hasil `POST /tasks/:id/verify`: AI membandingkan foto sebelum dan
/// sesudah, lalu skor risiko RW diperbarui (proposal 3.2 langkah 4).
class VerificationResult {
  const VerificationResult({
    required this.sudahBersih,
    required this.kelasSesudah,
    required this.keyakinan,
    required this.catatan,
    this.skorSumbatanSesudah,
    this.rw,
    this.skorRwSebelum,
    this.skorRwSesudah,
    this.tugas,
    this.fotoSesudahUrl,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final v = json['verifikasi'] as Map<String, dynamic>? ?? json;
    final rw = json['rw'] as Map<String, dynamic>?;
    final tugas = json['tugas'] as Map<String, dynamic>?;
    return VerificationResult(
      sudahBersih: v['sudah_bersih'] as bool? ?? false,
      kelasSesudah: KelasSumbatan.fromApi(v['kelas_sesudah'] as String?),
      skorSumbatanSesudah: (v['skor_sumbatan_sesudah'] as num?)?.toDouble(),
      keyakinan: v['keyakinan'] as String? ?? 'rendah',
      catatan: v['catatan'] as String? ?? '',
      rw: rw?['nama'] as String?,
      skorRwSebelum: (rw?['skor_sebelum'] as num?)?.toDouble(),
      skorRwSesudah: (rw?['skor_sesudah'] as num?)?.toDouble(),
      tugas: tugas == null ? null : Task.fromJson(tugas),
      fotoSesudahUrl: json['foto_sesudah_url'] as String?,
    );
  }

  final bool sudahBersih;
  final KelasSumbatan kelasSesudah;
  final double? skorSumbatanSesudah;
  final String keyakinan;
  final String catatan;
  final String? rw;
  final double? skorRwSebelum;
  final double? skorRwSesudah;

  /// Tugas setelah diperbarui server (status `selesai` kalau bersih).
  final Task? tugas;
  final String? fotoSesudahUrl;

  bool get adaPerubahanSkor => skorRwSebelum != null && skorRwSesudah != null;
}
