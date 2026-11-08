import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/jenis_saluran.dart';
import '../models/report.dart';
import '../models/rw_risk.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../models/verification.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get unauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Pintu aplikasi ke backend REST. Kontrak: `docs/backend/SRS.md` bagian 7
/// dan `docs/mobile/SRS.md` bagian 7.
abstract class ApiClient {
  factory ApiClient.fromConfig() =>
      AppConfig.useMockApi ? MockApiClient() : HttpApiClient(AppConfig.apiUrl);

  /// Token petugas, dikirim sebagai `Authorization: Bearer`.
  set token(String? value);

  /// `POST /auth/login` (7.1).
  Future<Session> login(String username, String password);

  /// `POST /reports` (7.2). Token opsional: warga boleh tanpa login.
  Future<Report> submitReport({
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    required JenisSaluran jenisSaluran,
  });

  /// `GET /reports/:id` (7.3): status terbaru + `tugas` + `bukti`.
  Future<Report> getReport(String id);

  /// `GET /tasks?mine=1` (7.9).
  Future<List<Task>> myTasks();

  /// `PATCH /tasks/:id` (7.11, P2): mis. `dikerjakan`.
  Future<Task> updateTaskStatus(String id, String status);

  /// `POST /tasks/:id/verify` (7.10).
  Future<VerificationResult> verifyTask({
    required String taskId,
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  });

  /// `POST /devices` (7.11): token FCM.
  Future<void> registerDevice(String fcmToken);

  /// `GET /rw/risk?kelurahan_id=` (7.4).
  Future<PetaRisiko> rwRisk(int kelurahanId);
}

class HttpApiClient implements ApiClient {
  HttpApiClient(String baseUrl, {http.Client? client})
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  String? _token;

  /// Analisis AI bisa sampai ±40 detik (mobile SRS NFR-02).
  static const _timeout = Duration(seconds: 60);

  @override
  set token(String? value) => _token = value;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  http.Request _json(String method, String path, Object body) =>
      http.Request(method, _uri(path))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);

  Future<http.MultipartRequest> _foto(
    String path, {
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    Map<String, String> extra = const {},
  }) async => http.MultipartRequest('POST', _uri(path))
    ..fields['lat'] = lat.toString()
    ..fields['lng'] = lng.toString()
    ..fields['captured_at'] = capturedAt.toUtc().toIso8601String()
    // Build demo saja (FR-BE-21); di build biasa field ini tidak dikirim.
    ..fields.addAll(AppConfig.lokasiDemo ? {'lokasi_demo': 'true'} : const {})
    ..fields.addAll(extra)
    ..files.add(
      await http.MultipartFile.fromPath(
        'foto',
        foto.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

  @override
  Future<Session> login(String username, String password) async {
    final body = await _send(
      _json('POST', '/auth/login', {
        'username': username,
        'password': password,
      }),
      gagal: 'Gagal masuk',
    );
    return Session.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<Report> submitReport({
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    required JenisSaluran jenisSaluran,
  }) async {
    final req = await _foto(
      '/reports',
      foto: foto,
      lat: lat,
      lng: lng,
      capturedAt: capturedAt,
      extra: {'jenis_saluran': jenisSaluran.apiValue},
    );
    final body = await _send(req, gagal: 'Laporan gagal dikirim');
    return Report.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<Report> getReport(String id) async {
    final body = await _send(
      http.Request('GET', _uri('/reports/${Uri.encodeComponent(id)}')),
      gagal: 'Laporan gagal dimuat',
    );
    return Report.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<List<Task>> myTasks() async {
    final body = await _send(
      http.Request('GET', _uri('/tasks?mine=1')),
      gagal: 'Tugas gagal dimuat',
    );
    final raw = body is Map<String, dynamic> ? body['data'] : body;
    return [
      for (final t in (raw as List<dynamic>? ?? const []))
        Task.fromJson(t as Map<String, dynamic>),
    ];
  }

  @override
  Future<Task> updateTaskStatus(String id, String status) async {
    final body = await _send(
      _json('PATCH', '/tasks/${Uri.encodeComponent(id)}', {'status': status}),
      gagal: 'Status tugas gagal diubah',
    );
    final map = body as Map<String, dynamic>;
    return Task.fromJson(map['tugas'] as Map<String, dynamic>? ?? map);
  }

  @override
  Future<VerificationResult> verifyTask({
    required String taskId,
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  }) async {
    final req = await _foto(
      '/tasks/${Uri.encodeComponent(taskId)}/verify',
      foto: foto,
      lat: lat,
      lng: lng,
      capturedAt: capturedAt,
    );
    final body = await _send(req, gagal: 'Verifikasi gagal dikirim');
    return VerificationResult.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<void> registerDevice(String fcmToken) async {
    await _send(
      _json('POST', '/devices', {'fcm_token': fcmToken}),
      gagal: 'Token notifikasi gagal disimpan',
    );
  }

  @override
  Future<PetaRisiko> rwRisk(int kelurahanId) async {
    final body = await _send(
      http.Request('GET', _uri('/rw/risk?kelurahan_id=$kelurahanId')),
      gagal: 'Peta risiko gagal dimuat',
    );
    return PetaRisiko.fromJson(body as Map<String, dynamic>);
  }

  Future<Object?> _send(
    http.BaseRequest request, {
    required String gagal,
  }) async {
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    } on SocketException {
      throw const ApiException('Tidak bisa terhubung ke server. Cek internet.');
    } on http.ClientException {
      throw const ApiException('Koneksi ke server terputus. Coba lagi.');
    }

    Object? body;
    try {
      body = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      body = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    // Pesan dari backend ditampilkan apa adanya (mobile SRS NFR-02).
    final pesan = body is Map<String, dynamic>
        ? body['error'] as String?
        : null;
    throw ApiException(
      pesan ??
          (response.statusCode == 401
              ? 'Sesi berakhir. Silakan masuk lagi.'
              : '$gagal (kode ${response.statusCode}).'),
      statusCode: response.statusCode,
    );
  }
}

/// Backend tiruan untuk mode contoh (tanpa `API_URL`). Semua respons memakai
/// bentuk JSON yang sama dengan backend SRS bagian 7.
///
/// - Login: nama pengguna berisi `petugas` → petugas, `lurah` → lurah,
///   selain itu warga. Kata sandi apa saja. App hanya menerima petugas.
/// - Hasil AI bergiliran (berat → sedang → tidak terlihat → bersih).
/// - 2 laporan dan 4 tugas contoh di sekitar Gedebage, 5 RW dengan skor.
class MockApiClient implements ApiClient {
  MockApiClient({
    this.delay = const Duration(seconds: 2),
    this.listDelay = const Duration(milliseconds: 500),
    this.tugasBaruSetelah = const Duration(seconds: 20),
  }) : _reports = {for (final r in _contohLaporan()) '${r['id']}': r},
       _tasks = _contohTugas(),
       _rw = _contohRw();

  final Duration delay;
  final Duration listDelay;

  /// Tugas baru contoh dikirim "lurah" beberapa detik setelah daftar tugas
  /// pertama kali dimuat, supaya notifikasi bisa didemokan.
  final Duration tugasBaruSetelah;

  final Map<String, Map<String, dynamic>> _reports;
  final List<Map<String, dynamic>> _tasks;
  final List<Map<String, dynamic>> _rw;
  int _counter = 0;
  DateTime? _pertamaMuatTugas;
  final Map<String, int> _percobaanVerifikasi = {};

  /// Id laporan contoh yang otomatis tampil di "Laporan saya" mode contoh.
  static const idLaporanContoh = ['contoh-102', 'contoh-101'];

  /// Komponen hujan tetap di mode contoh (0–1).
  static const _hujan = 0.5;

  @override
  set token(String? value) {}

  @override
  Future<Session> login(String username, String password) async {
    await Future<void>.delayed(listDelay);
    final nama = username.trim().toLowerCase();
    if (nama.isEmpty) throw const ApiException('Nama pengguna wajib diisi.');
    final role = nama.contains('petugas')
        ? 'petugas'
        : nama.contains('lurah')
        ? 'lurah'
        : 'warga';
    return Session.fromJson({
      'token': 'contoh-$role',
      'role': role,
      'pengguna': {
        'id': 2,
        'nama': role == 'petugas' ? 'Dedi' : 'Pengguna contoh',
        'kelurahan_id': 1,
      },
    });
  }

  static const _contohAi = <Map<String, dynamic>>[
    {
      'saluran_terlihat': true,
      'kelas_sumbatan': 'berat',
      'skor_sumbatan': 0.85,
      'penyebab': ['plastik', 'sedimen'],
      'keyakinan': 'tinggi',
      'catatan': 'Sampah plastik menutupi sebagian besar lebar saluran',
    },
    {
      'saluran_terlihat': true,
      'kelas_sumbatan': 'sedang',
      'skor_sumbatan': 0.55,
      'penyebab': ['daun_ranting'],
      'keyakinan': 'sedang',
      'catatan': 'Daun dan ranting menumpuk di sisi saluran, aliran masih ada',
    },
    {
      'saluran_terlihat': false,
      'kelas_sumbatan': 'tidak_terlihat',
      'skor_sumbatan': null,
      'penyebab': <String>[],
      'keyakinan': 'rendah',
      'catatan': 'Saluran tertutup beton, kondisi di dalam tidak terlihat',
    },
    {
      'saluran_terlihat': true,
      'kelas_sumbatan': 'bersih',
      'skor_sumbatan': 0.05,
      'penyebab': <String>[],
      'keyakinan': 'tinggi',
      'catatan': 'Saluran bersih, aliran lancar',
    },
  ];

  @override
  Future<Report> submitReport({
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    required JenisSaluran jenisSaluran,
  }) async {
    await Future<void>.delayed(delay);
    final ai = {
      ..._contohAi[_counter % _contohAi.length],
      'jenis_saluran': jenisSaluran.apiValue,
    };
    _counter++;
    // Laporan dalam 15 m dari laporan lain digabung (proposal Tabel 8).
    final digabung = _reports.values.any(
      (r) => _jarakM(lat, lng, r['lat'] as double, r['lng'] as double) < 15,
    );
    final json = <String, dynamic>{
      'id': 'contoh-$_counter',
      'status': ai['kelas_sumbatan'] == 'tidak_terlihat'
          ? 'cek_manual'
          : 'dikirim',
      'jenis_saluran': jenisSaluran.apiValue,
      'lat': lat,
      'lng': lng,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'foto_url': null,
      'ai': ai,
      'ai_sumber': 'model',
      'digabung': digabung,
      'rw_nama': _rwTerdekat(lat, lng),
      'lokasi_demo': false,
      'tugas': null,
      'bukti': null,
    };
    _reports['${json['id']}'] = json;
    return Report.fromJson(json);
  }

  @override
  Future<Report> getReport(String id) async {
    await Future<void>.delayed(listDelay);
    final r = _reports[id] ?? _laporanAsalTugas(id);
    if (r == null) {
      throw const ApiException('Laporan tidak ditemukan.', statusCode: 404);
    }
    return Report.fromJson(r);
  }

  /// Laporan asal tugas contoh (dari siskamling) supaya detail tugas bisa
  /// menampilkan analisis AI lengkap, seperti `GET /reports/:laporan_id`.
  Map<String, dynamic>? _laporanAsalTugas(String id) {
    final t = _tasks.where((t) => t['laporan_id'] == id).firstOrNull;
    if (t == null) return null;
    final saluran = t['saluran'] as Map<String, dynamic>;
    final kelas = t['kelas_sebelum'] as String;
    return {
      'id': id,
      'status': t['status'] == 'selesai' ? 'ditangani' : 'ditugaskan',
      'jenis_saluran': saluran['jenis'],
      'lat': saluran['lat'],
      'lng': saluran['lng'],
      'rw_nama': saluran['rw_nama'],
      'captured_at': t['dibuat_at'],
      'foto_url': t['foto_sebelum_url'],
      'ai': {
        ...switch (kelas) {
          'berat' => _contohAi[0],
          'sedang' => _contohAi[1],
          _ => const {
            'saluran_terlihat': true,
            'penyebab': ['daun_ranting'],
            'keyakinan': 'tinggi',
            'catatan': 'Sedikit daun di dasar saluran, aliran lancar',
          },
        },
        'kelas_sumbatan': kelas,
        'skor_sumbatan': t['skor_sebelum'],
      },
      'ai_sumber': 'model',
      'digabung': false,
      'lokasi_demo': false,
      'tugas': {'id': t['id'], 'status': t['status'], 'petugas_nama': 'Dedi'},
      'bukti': null,
    };
  }

  @override
  Future<List<Task>> myTasks() async {
    await Future<void>.delayed(listDelay);
    final now = DateTime.now();
    _pertamaMuatTugas ??= now;
    final adaTugasBaru = now.difference(_pertamaMuatTugas!) >= tugasBaruSetelah;
    if (adaTugasBaru && !_tasks.any((t) => t['id'] == 't5')) {
      _tasks.insert(0, _tugasBaru());
    }
    return [for (final json in _tasks) Task.fromJson(json)];
  }

  Map<String, dynamic> _tugas(String id) => _tasks.firstWhere(
    (t) => t['id'] == id,
    orElse: () =>
        throw const ApiException('Tugas tidak ditemukan.', statusCode: 404),
  );

  @override
  Future<Task> updateTaskStatus(String id, String status) async {
    await Future<void>.delayed(listDelay);
    final t = _tugas(id)..['status'] = status;
    return Task.fromJson(t);
  }

  @override
  Future<VerificationResult> verifyTask({
    required String taskId,
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  }) async {
    await Future<void>.delayed(delay);
    final task = _tugas(taskId);
    final percobaan = (_percobaanVerifikasi[taskId] ?? 0) + 1;
    _percobaanVerifikasi[taskId] = percobaan;

    // Tugas t3 sengaja gagal di percobaan pertama supaya tampilan
    // "masih ada sumbatan" ikut teruji.
    final bersih = !(taskId == 't3' && percobaan == 1);
    final saluran = task['saluran'] as Map<String, dynamic>;
    final selesaiAt = DateTime.now().toUtc().toIso8601String();
    if (bersih) {
      task
        ..['status'] = 'selesai'
        ..['selesai_at'] = selesaiAt;
      final laporan = _reports['${task['laporan_id']}'];
      if (laporan != null) {
        laporan
          ..['status'] = 'ditangani'
          ..['tugas'] = {
            'id': taskId,
            'status': 'selesai',
            'petugas_nama': 'Dedi',
          }
          ..['bukti'] = {
            'foto_sesudah_url': null,
            'kelas_sesudah': 'bersih',
            'selesai_at': selesaiAt,
          };
      }
      // Sumbatan di RW turun → skor risiko RW ikut turun (proposal 3.3).
      for (final rw in _rw) {
        if (rw['nama'] == saluran['rw_nama']) rw['s'] = 0.08;
      }
    } else {
      task['status'] = 'dikerjakan';
    }

    return VerificationResult.fromJson({
      'tugas': task,
      'verifikasi': {
        'sudah_bersih': bersih,
        'kelas_sesudah': bersih ? 'bersih' : 'sedang',
        'skor_sumbatan_sesudah': bersih ? 0.08 : 0.42,
        'keyakinan': 'tinggi',
        'catatan': bersih
            ? 'Sumbatan sudah terangkat, dasar saluran terlihat dan aliran lancar'
            : 'Masih ada sedimen di sudut inlet, sekitar sepertiga lubang tertutup',
      },
      'ai_sumber': 'model',
    });
  }

  @override
  Future<void> registerDevice(String fcmToken) async {}

  @override
  Future<PetaRisiko> rwRisk(int kelurahanId) async {
    await Future<void>.delayed(listDelay);
    return PetaRisiko.fromJson({
      'type': 'FeatureCollection',
      'meta': {
        'hujan_24j_mm': _hujan * 100,
        'hujan_sumber': 'simulasi_demo',
        'hujan_lebat_diprediksi': _hujan * 100 >= 50,
      },
      'features': [for (final rw in _rw) _fitur(rw)],
    });
  }

  static Map<String, dynamic> _fitur(Map<String, dynamic> rw) {
    final s = rw['s'] as double;
    final k = rw['k'] as double;
    final skor = 0.4 * _hujan + 0.4 * s + 0.2 * k;
    final level = LevelRisiko.dariSkor(skor);
    // Batas contoh: lima RW bersebelahan di sekitar Gedebage [ASUMSI].
    final batas = [
      for (final t in rw['batas'] as List<List<double>>) [t[1], t[0]],
    ];
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [...batas, batas.first],
        ],
      },
      'properties': {
        'rw_id': rw['id'],
        'nama': rw['nama'],
        'skor': skor,
        'level': level.apiValue,
        'komponen': {
          'hujan': {'nilai': _hujan, 'bobot': 0.4},
          'sumbatan': {'nilai': s, 'bobot': 0.4},
          'kerentanan': {'nilai': k, 'bobot': 0.2},
        },
        'alasan':
            '${level.label}: prakiraan hujan ${(_hujan * 100).round()} mm dalam '
            '24 jam, sumbatan ${_kataSumbatan(s)}, kerentanan lokasi '
            '${k >= 0.7
                ? 'tinggi'
                : k >= 0.5
                ? 'sedang'
                : 'rendah'}.',
      },
    };
  }

  static String _kataSumbatan(double s) => s >= 0.7
      ? 'berat'
      : s >= 0.4
      ? 'sedang'
      : s >= 0.15
      ? 'ringan'
      : 'sudah bersih';

  String _rwTerdekat(double lat, double lng) {
    var best = _rw.first;
    var bestD = double.infinity;
    for (final rw in _rw) {
      final d = _jarakM(lat, lng, rw['lat'] as double, rw['lng'] as double);
      if (d < bestD) {
        bestD = d;
        best = rw;
      }
    }
    return best['nama'] as String;
  }

  static double _jarakM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  static String _lalu(Duration d) =>
      DateTime.now().subtract(d).toUtc().toIso8601String();

  static List<Map<String, dynamic>> _contohRw() => [
    {
      'id': 2,
      'nama': 'RW 02',
      'batas': [
        [-6.9390, 107.6845],
        [-6.9390, 107.6885],
        [-6.9415, 107.6893],
        [-6.9425, 107.6876],
        [-6.9428, 107.6845],
      ],
      'lat': -6.9418,
      'lng': 107.6870,
      's': 0.55,
      'k': 0.6,
    },
    {
      'id': 3,
      'nama': 'RW 03',
      'batas': [
        [-6.9390, 107.6885],
        [-6.9390, 107.6960],
        [-6.9420, 107.6960],
        [-6.9422, 107.6922],
        [-6.9415, 107.6893],
      ],
      'lat': -6.9405,
      'lng': 107.6899,
      's': 0.08,
      'k': 0.4,
    },
    {
      'id': 4,
      'nama': 'RW 04',
      'batas': [
        [-6.9428, 107.6845],
        [-6.9425, 107.6876],
        [-6.9438, 107.6898],
        [-6.9475, 107.6890],
        [-6.9475, 107.6845],
      ],
      'lat': -6.9432,
      'lng': 107.6881,
      's': 0.78,
      'k': 0.7,
    },
    {
      'id': 5,
      'nama': 'RW 05',
      'batas': [
        [-6.9415, 107.6893],
        [-6.9422, 107.6922],
        [-6.9420, 107.6960],
        [-6.9445, 107.6960],
        [-6.9450, 107.6925],
        [-6.9438, 107.6898],
        [-6.9425, 107.6876],
      ],
      'lat': -6.9441,
      'lng': 107.6912,
      's': 0.85,
      'k': 0.9,
    },
    {
      'id': 7,
      'nama': 'RW 07',
      'batas': [
        [-6.9438, 107.6898],
        [-6.9450, 107.6925],
        [-6.9445, 107.6960],
        [-6.9475, 107.6960],
        [-6.9475, 107.6890],
      ],
      'lat': -6.9460,
      'lng': 107.6935,
      's': 0.48,
      'k': 0.5,
    },
  ];

  static List<Map<String, dynamic>> _contohLaporan() => [
    {
      'id': 'contoh-102',
      'status': 'ditugaskan',
      'jenis_saluran': 'terbuka',
      'lat': -6.9418,
      'lng': 107.6870,
      'rw_nama': 'RW 02',
      'captured_at': _lalu(const Duration(hours: 5)),
      'foto_url': null,
      'ai': _contohAi[1],
      'ai_sumber': 'model',
      'digabung': false,
      'lokasi_demo': false,
      'tugas': {'id': 't2', 'status': 'baru', 'petugas_nama': 'Dedi'},
      'bukti': null,
    },
    {
      'id': 'contoh-101',
      'status': 'ditangani',
      'jenis_saluran': 'gorong_gorong',
      'lat': -6.9441,
      'lng': 107.6912,
      'rw_nama': 'RW 05',
      'captured_at': _lalu(const Duration(days: 2)),
      'foto_url': null,
      'ai': _contohAi[0],
      'ai_sumber': 'model',
      'digabung': false,
      'lokasi_demo': false,
      'tugas': {'id': 't0', 'status': 'selesai', 'petugas_nama': 'Dedi'},
      'bukti': {
        'foto_sesudah_url': null,
        'kelas_sesudah': 'bersih',
        'selesai_at': _lalu(const Duration(days: 1)),
      },
    },
  ];

  static Map<String, dynamic> _tugasJson({
    required String id,
    required String status,
    required String rw,
    required String jenis,
    required double lat,
    required double lng,
    required String kelas,
    required double skor,
    required Duration lalu,
    String? laporanId,
    String? catatan,
  }) => {
    'id': id,
    'status': status,
    'saluran': {
      'id': 's-$id',
      'jenis': jenis,
      'rw_nama': rw,
      'lat': lat,
      'lng': lng,
    },
    'petugas': {'id': 2, 'nama': 'Dedi'},
    'laporan_id': laporanId ?? 'laporan-$id',
    'foto_sebelum_url': null,
    'kelas_sebelum': kelas,
    'skor_sebelum': skor,
    'foto_sesudah_url': null,
    'verifikasi': null,
    'catatan': catatan,
    'dibuat_at': _lalu(lalu),
    'selesai_at': status == 'selesai'
        ? _lalu(lalu - const Duration(hours: 2))
        : null,
  };

  static Map<String, dynamic> _tugasBaru() => _tugasJson(
    id: 't5',
    status: 'baru',
    rw: 'RW 04',
    jenis: 'inlet_jalan',
    lat: -6.9432,
    lng: 107.6881,
    kelas: 'berat',
    skor: 0.78,
    lalu: Duration.zero,
    catatan: 'Baru dilaporkan siskamling. Kantong plastik menutup inlet.',
  );

  static List<Map<String, dynamic>> _contohTugas() => [
    _tugasJson(
      id: 't1',
      status: 'baru',
      rw: 'RW 05',
      jenis: 'gorong_gorong',
      lat: -6.9441,
      lng: 107.6912,
      kelas: 'berat',
      skor: 0.85,
      lalu: const Duration(minutes: 40),
      catatan: 'Prioritas sebelum hujan sore. Fokus mulut gorong-gorong.',
    ),
    _tugasJson(
      id: 't2',
      status: 'baru',
      rw: 'RW 02',
      jenis: 'terbuka',
      lat: -6.9418,
      lng: 107.6870,
      kelas: 'sedang',
      skor: 0.55,
      lalu: const Duration(hours: 1, minutes: 15),
      // Laporan warga yang sama: setelah t2 bersih, laporan ini ditangani.
      laporanId: 'contoh-102',
      catatan: 'Laporan warga. Bersihkan sebelum pukul 15.00.',
    ),
    _tugasJson(
      id: 't3',
      status: 'dikerjakan',
      rw: 'RW 07',
      jenis: 'inlet_jalan',
      lat: -6.9460,
      lng: 107.6935,
      kelas: 'sedang',
      skor: 0.48,
      lalu: const Duration(hours: 3),
    ),
    _tugasJson(
      id: 't4',
      status: 'selesai',
      rw: 'RW 03',
      jenis: 'terbuka',
      lat: -6.9405,
      lng: 107.6899,
      kelas: 'ringan',
      skor: 0.30,
      lalu: const Duration(days: 1),
    ),
  ];
}

final ApiClient api = ApiClient.fromConfig();
