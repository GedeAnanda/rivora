import 'ai_result.dart';
import 'task.dart';

/// Level risiko RW (proposal 3.2 langkah 2). Batas skor mengikuti
/// docs/RENCANA_FINAL.md bagian 4 [ASUMSI]: aman < 0,40 · waspada < 0,70.
enum LevelRisiko {
  aman('aman', 'Aman'),
  waspada('waspada', 'Waspada'),
  risikoTinggi('risiko_tinggi', 'Risiko tinggi');

  const LevelRisiko(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LevelRisiko dariSkor(double skor) => skor < 0.40
      ? LevelRisiko.aman
      : skor < 0.70
      ? LevelRisiko.waspada
      : LevelRisiko.risikoTinggi;

  static LevelRisiko? fromApi(String? v) {
    for (final l in values) {
      if (l.apiValue == v) return l;
    }
    return null;
  }
}

/// Hasil `POST /tasks/:id/verify` (backend SRS 7.10): AI membandingkan foto
/// sebelum dan sesudah (proposal 3.2 langkah 4).
///
/// `verifikasi` bisa `null` (AI gagal menilai): tampilkan `pesan` dan tombol
/// Foto ulang (mobile SRS FR-MB-10).
class VerificationResult {
  const VerificationResult({
    required this.sudahBersih,
    required this.kelasSesudah,
    required this.keyakinan,
    required this.catatan,
    this.dinilai = true,
    this.pesan,
    this.skorSumbatanSesudah,
    this.aiSumber,
    this.tugas,
    this.rw,
    this.skorRwSebelum,
    this.skorRwSesudah,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final v = json['verifikasi'] as Map<String, dynamic>?;
    final tugas = json['tugas'] as Map<String, dynamic>?;
    return VerificationResult(
      dinilai: v != null,
      pesan: json['pesan'] as String?,
      sudahBersih: v?['sudah_bersih'] as bool? ?? false,
      kelasSesudah: KelasSumbatan.fromApi(v?['kelas_sesudah'] as String?),
      skorSumbatanSesudah: (v?['skor_sumbatan_sesudah'] as num?)?.toDouble(),
      keyakinan: v?['keyakinan'] as String? ?? 'rendah',
      catatan: v?['catatan'] as String? ?? '',
      aiSumber: json['ai_sumber'] as String?,
      tugas: tugas == null ? null : Task.fromJson(tugas),
    );
  }

  /// `false` kalau AI tidak memberi penilaian (`verifikasi: null`).
  final bool dinilai;
  final String? pesan;
  final bool sudahBersih;
  final KelasSumbatan kelasSesudah;
  final double? skorSumbatanSesudah;
  final String keyakinan;
  final String catatan;

  /// `model` | `demo` [DEMO].
  final String? aiSumber;

  /// Tugas setelah diperbarui server (status `selesai` kalau bersih).
  final Task? tugas;

  /// Skor risiko RW sebelum dan sesudah, diambil dari `GET /rw/risk`
  /// sebelum dan sesudah verifikasi (bukan bagian respons verify).
  final String? rw;
  final double? skorRwSebelum;
  final double? skorRwSesudah;

  bool get adaPerubahanSkor => skorRwSebelum != null && skorRwSesudah != null;
  bool get hasilDemo => aiSumber == 'demo';

  VerificationResult denganSkorRw(
    String? rw,
    double? sebelum,
    double? sesudah,
  ) => VerificationResult(
    dinilai: dinilai,
    pesan: pesan,
    sudahBersih: sudahBersih,
    kelasSesudah: kelasSesudah,
    skorSumbatanSesudah: skorSumbatanSesudah,
    keyakinan: keyakinan,
    catatan: catatan,
    aiSumber: aiSumber,
    tugas: tugas,
    rw: rw,
    skorRwSebelum: sebelum,
    skorRwSesudah: sesudah,
  );
}
