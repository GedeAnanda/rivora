import 'ai_result.dart';
import 'jenis_saluran.dart';

DateTime? _waktu(Object? value) =>
    value is String ? DateTime.parse(value).toLocal() : null;

/// Laporan saluran: respons `POST /reports` (backend SRS 7.2) dan
/// `GET /reports/:id` (7.3, ditambah `tugas` dan `bukti`).
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
    this.aiSumber,
    this.lokasiDemo = false,
    this.digabung = false,
    this.tugasStatus,
    this.petugasNama,
    this.fotoSesudahUrl,
    this.kelasSesudah,
    this.ditanganiAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    final tugas = json['tugas'] as Map<String, dynamic>?;
    final bukti = json['bukti'] as Map<String, dynamic>?;
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
      rw: json['rw_nama'] as String? ?? json['rw'] as String?,
      aiSumber: json['ai_sumber'] as String?,
      lokasiDemo: json['lokasi_demo'] as bool? ?? false,
      digabung: json['digabung'] as bool? ?? false,
      tugasStatus: tugas?['status'] as String?,
      petugasNama: tugas?['petugas_nama'] as String?,
      fotoSesudahUrl: bukti?['foto_sesudah_url'] as String?,
      kelasSesudah: bukti?['kelas_sesudah'] == null
          ? null
          : KelasSumbatan.fromApi(bukti!['kelas_sesudah'] as String?),
      ditanganiAt: _waktu(bukti?['selesai_at']),
    );
  }

  final String id;

  /// `dikirim` | `ditugaskan` | `ditangani` | `cek_manual`.
  final String status;
  final JenisSaluran jenisSaluran;
  final double lat;
  final double lng;
  final DateTime capturedAt;
  final String? fotoUrl;
  final AiResult ai;
  final String? rw;

  /// `model` | `demo` [DEMO]. "demo" wajib diberi label (mobile SRS 6.3).
  final String? aiSumber;

  /// Lokasi dipetakan ke saluran contoh [DEMO] (mobile SRS 6.3).
  final bool lokasiDemo;

  /// Laporan berdekatan digabung ke saluran yang sama (proposal Tabel 8).
  final bool digabung;
  final String? tugasStatus;
  final String? petugasNama;

  /// Foto bukti sesudah dibersihkan (proposal Tabel 8: dikirim ke pelapor).
  final String? fotoSesudahUrl;
  final KelasSumbatan? kelasSesudah;
  final DateTime? ditanganiAt;

  /// Bentuk sama dengan respons backend, untuk disimpan di HP
  /// (mobile SRS FR-MB-06: laporan bisa dilacak tanpa login).
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'jenis_saluran': jenisSaluran.apiValue,
    'lat': lat,
    'lng': lng,
    'captured_at': capturedAt.toUtc().toIso8601String(),
    'foto_url': fotoUrl,
    'ai': ai.toJson(),
    'rw_nama': rw,
    'ai_sumber': aiSumber,
    'lokasi_demo': lokasiDemo,
    'digabung': digabung,
    'tugas': tugasStatus == null && petugasNama == null
        ? null
        : {'status': tugasStatus, 'petugas_nama': petugasNama},
    'bukti':
        fotoSesudahUrl == null && kelasSesudah == null && ditanganiAt == null
        ? null
        : {
            'foto_sesudah_url': fotoSesudahUrl,
            'kelas_sesudah': kelasSesudah?.apiValue,
            'selesai_at': ditanganiAt?.toUtc().toIso8601String(),
          },
  };

  bool get sudahDitangani => status == 'ditangani';

  /// Kondisi saluran sekarang: hasil verifikasi kalau sudah ditangani,
  /// selain itu hasil AI saat dilaporkan. Dipakai warna penanda peta.
  KelasSumbatan get kelasKini =>
      sudahDitangani ? (kelasSesudah ?? KelasSumbatan.bersih) : ai.kelas;
  bool get ditugaskan => tugasStatus != null || status == 'ditugaskan';
  bool get hasilDemo => aiSumber == 'demo';
}

const Map<String, String> labelStatusLaporan = {
  'dikirim': 'Dikirim',
  'ditugaskan': 'Ditugaskan',
  'ditangani': 'Sudah ditangani',
  'cek_manual': 'Perlu cek manual',
};
