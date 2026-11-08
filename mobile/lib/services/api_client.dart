import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/jenis_saluran.dart';
import '../models/report.dart';
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

/// Pintu aplikasi ke backend REST (kontrak: docs/API.md,
/// usulan tambahan mobile: docs/mobile/02-status-dan-tugas.md).
abstract class ApiClient {
  factory ApiClient.fromConfig() =>
      AppConfig.useMockApi ? MockApiClient() : HttpApiClient(AppConfig.apiUrl);

  /// Token dari login, dikirim sebagai `Authorization: Bearer`.
  set token(String? value);

  /// `POST /auth/login`
  Future<Session> login(String username, String password);

  /// `POST /reports`: kirim foto + lokasi, backend memanggil AI vision
  /// dan mengembalikan laporan beserta hasil analisisnya.
  Future<Report> submitReport({
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    required JenisSaluran jenisSaluran,
  });

  /// `GET /reports?mine=1`: laporan milik pengguna yang login.
  Future<List<Report>> myReports();

  /// `GET /tasks?mine=1`: tugas milik petugas yang login.
  Future<List<Task>> myTasks();

  /// `POST /tasks/:id/verify`: foto sesudah dibersihkan. AI membandingkan
  /// dengan foto sebelum, skor RW diperbarui (proposal 3.2 langkah 4).
  Future<VerificationResult> verifyTask({
    required String taskId,
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  });

  /// `POST /devices`: simpan token FCM supaya backend bisa mengirim
  /// notifikasi tugas (proposal Tabel 12).
  Future<void> registerDevice(String fcmToken);
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

  /// Analisis AI bisa makan waktu beberapa detik.
  static const _timeout = Duration(seconds: 60);

  @override
  set token(String? value) => _token = value;

  Map<String, String> get _authHeader => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  @override
  Future<Session> login(String username, String password) async {
    final body = await _sendJson(
      http.Request('POST', Uri.parse('$_baseUrl/auth/login'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'username': username, 'password': password}),
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
    final request =
        http.MultipartRequest('POST', Uri.parse('$_baseUrl/reports'))
          ..fields['lat'] = lat.toString()
          ..fields['lng'] = lng.toString()
          ..fields['captured_at'] = capturedAt.toUtc().toIso8601String()
          ..fields['jenis_saluran'] = jenisSaluran.apiValue
          ..files.add(
            await http.MultipartFile.fromPath(
              'foto',
              foto.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
    final body = await _sendJson(request, gagal: 'Laporan gagal dikirim');
    return Report.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<List<Report>> myReports() async {
    final body = await _sendJson(
      http.Request('GET', Uri.parse('$_baseUrl/reports?mine=1')),
      gagal: 'Laporan gagal dimuat',
    );
    return [for (final item in _list(body)) Report.fromJson(item)];
  }

  @override
  Future<List<Task>> myTasks() async {
    final body = await _sendJson(
      http.Request('GET', Uri.parse('$_baseUrl/tasks?mine=1')),
      gagal: 'Tugas gagal dimuat',
    );
    return [for (final item in _list(body)) Task.fromJson(item)];
  }

  @override
  Future<VerificationResult> verifyTask({
    required String taskId,
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  }) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('$_baseUrl/tasks/${Uri.encodeComponent(taskId)}/verify'),
          )
          ..fields['lat'] = lat.toString()
          ..fields['lng'] = lng.toString()
          ..fields['captured_at'] = capturedAt.toUtc().toIso8601String()
          ..files.add(
            await http.MultipartFile.fromPath(
              'foto',
              foto.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
    final body = await _sendJson(request, gagal: 'Verifikasi gagal dikirim');
    return VerificationResult.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<void> registerDevice(String fcmToken) async {
    await _sendJson(
      http.Request('POST', Uri.parse('$_baseUrl/devices'))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode({'fcm_token': fcmToken}),
      gagal: 'Token notifikasi gagal disimpan',
    );
  }

  /// Menerima `[...]` atau `{ "data": [...] }`.
  List<Map<String, dynamic>> _list(Object? body) {
    final raw = body is Map<String, dynamic> ? body['data'] : body;
    return [
      for (final item in (raw as List<dynamic>? ?? const []))
        item as Map<String, dynamic>,
    ];
  }

  Future<Object?> _sendJson(
    http.BaseRequest request, {
    required String gagal,
  }) async {
    request.headers.addAll(_authHeader);
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

    final pesan = body is Map<String, dynamic>
        ? body['error'] as String?
        : null;
    throw ApiException(
      response.statusCode == 401
          ? 'Sesi berakhir. Silakan masuk lagi.'
          : pesan ?? '$gagal (kode ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}

/// Backend tiruan untuk mode contoh (tanpa `API_URL`).
///
/// - Login: nama pengguna berisi `petugas` → petugas, `lurah` → lurah,
///   selain itu warga. Kata sandi apa saja.
/// - Hasil AI bergiliran (berat → sedang → tidak terlihat → bersih)
///   supaya semua tampilan teruji.
/// - Sudah berisi 2 laporan dan 4 tugas contoh di sekitar Gedebage.
class MockApiClient implements ApiClient {
  MockApiClient({
    this.delay = const Duration(seconds: 2),
    this.listDelay = const Duration(milliseconds: 500),
    this.tugasBaruSetelah = const Duration(seconds: 20),
  }) : _reports = _contohLaporan(),
       _tasks = _contohTugas();

  final Duration delay;
  final Duration listDelay;
  final List<Map<String, dynamic>> _reports;
  final List<Map<String, dynamic>> _tasks;
  int _counter = 0;

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
    return Session(
      token: 'contoh-$role',
      role: role,
      nama: switch (role) {
        'petugas' => 'Dedi',
        'lurah' => 'Kelurahan contoh',
        _ => 'Rina',
      },
    );
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
    final json = <String, dynamic>{
      'id': 'contoh-$_counter',
      'status': ai['kelas_sumbatan'] == 'tidak_terlihat'
          ? 'cek_manual'
          : 'dikirim',
      'jenis_saluran': jenisSaluran.apiValue,
      'lat': lat,
      'lng': lng,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'ai': ai,
    };
    _reports.insert(0, json);
    return Report.fromJson(json);
  }

  @override
  Future<List<Report>> myReports() async {
    await Future<void>.delayed(listDelay);
    return [for (final json in _reports) Report.fromJson(json)];
  }

  /// Tugas baru contoh yang "dikirim lurah" beberapa detik setelah petugas
  /// pertama kali membuka daftar tugas, supaya notifikasi bisa didemokan.
  final Duration tugasBaruSetelah;
  DateTime? _pertamaMuatTugas;
  final Map<String, int> _percobaanVerifikasi = {};

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

  @override
  Future<VerificationResult> verifyTask({
    required String taskId,
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
  }) async {
    await Future<void>.delayed(delay);
    final task = _tasks.firstWhere(
      (t) => t['id'] == taskId,
      orElse: () => throw const ApiException('Tugas tidak ditemukan.'),
    );
    final percobaan = (_percobaanVerifikasi[taskId] ?? 0) + 1;
    _percobaanVerifikasi[taskId] = percobaan;

    // Tugas t3 sengaja gagal di percobaan pertama supaya tampilan
    // "masih ada sumbatan" ikut teruji.
    final bersih = !(taskId == 't3' && percobaan == 1);
    final laporan = task['laporan'] as Map<String, dynamic>;
    final skorSebelum = (task['skor_prioritas'] as num).toDouble();
    final sumbatanSebelum =
        ((laporan['ai'] as Map<String, dynamic>)['skor_sumbatan'] as num?)
            ?.toDouble() ??
        0.5;
    final sumbatanSesudah = bersih ? 0.08 : 0.42;
    // Rumus proposal 3.3: komponen sumbatan berbobot 0,4.
    final skorSesudah =
        (skorSebelum - 0.4 * (sumbatanSebelum - sumbatanSesudah)).clamp(
          0.0,
          1.0,
        );

    if (bersih) {
      task['status'] = 'selesai';
      final laporanId = laporan['id'];
      for (final r in _reports) {
        if (r['id'] == laporanId) {
          r['status'] = 'ditangani';
          r['ditangani_at'] = DateTime.now().toUtc().toIso8601String();
        }
      }
    } else {
      task['status'] = 'dikerjakan';
    }

    return VerificationResult.fromJson({
      'verifikasi': {
        'sudah_bersih': bersih,
        'kelas_sesudah': bersih ? 'bersih' : 'sedang',
        'skor_sumbatan_sesudah': sumbatanSesudah,
        'keyakinan': 'tinggi',
        'catatan': bersih
            ? 'Sumbatan sudah terangkat, dasar saluran terlihat dan aliran lancar'
            : 'Masih ada sedimen di sudut inlet, sekitar sepertiga lubang tertutup',
      },
      'tugas': task,
      'rw': {
        'nama': task['rw'],
        'skor_sebelum': skorSebelum,
        'skor_sesudah': bersih ? skorSesudah : skorSebelum - 0.02,
      },
    });
  }

  @override
  Future<void> registerDevice(String fcmToken) async {}

  static String _lalu(Duration d) =>
      DateTime.now().subtract(d).toUtc().toIso8601String();

  static List<Map<String, dynamic>> _contohLaporan() => [
    {
      'id': 'contoh-102',
      'status': 'ditugaskan',
      'jenis_saluran': 'terbuka',
      'lat': -6.9418,
      'lng': 107.6870,
      'rw': 'RW 02',
      'captured_at': _lalu(const Duration(hours: 5)),
      'ditugaskan_at': _lalu(const Duration(hours: 3)),
      'petugas_nama': 'Dedi',
      'ai': _contohAi[1],
    },
    {
      'id': 'contoh-101',
      'status': 'ditangani',
      'jenis_saluran': 'gorong_gorong',
      'lat': -6.9441,
      'lng': 107.6912,
      'rw': 'RW 05',
      'captured_at': _lalu(const Duration(days: 2)),
      'ditugaskan_at': _lalu(const Duration(days: 2, hours: -1)),
      'ditangani_at': _lalu(const Duration(days: 1)),
      'petugas_nama': 'Dedi',
      'ai': _contohAi[0],
    },
  ];

  static Map<String, dynamic> _tugas({
    required String id,
    required String status,
    required double skor,
    required String rw,
    required String jenis,
    required double lat,
    required double lng,
    required Map<String, dynamic> ai,
    required Duration lalu,
    String? laporanId,
  }) => {
    'id': id,
    'status': status,
    'created_at': _lalu(lalu),
    'skor_prioritas': skor,
    'rw': rw,
    'saluran': {'jenis_saluran': jenis, 'lat': lat, 'lng': lng},
    'laporan': {'id': laporanId ?? 'laporan-$id', 'ai': ai},
  };

  static Map<String, dynamic> _tugasBaru() => _tugas(
    id: 't5',
    status: 'baru',
    skor: 0.79,
    rw: 'RW 04',
    jenis: 'inlet_jalan',
    lat: -6.9432,
    lng: 107.6881,
    ai: const {
      'saluran_terlihat': true,
      'kelas_sumbatan': 'berat',
      'skor_sumbatan': 0.78,
      'penyebab': ['plastik', 'daun_ranting'],
      'keyakinan': 'tinggi',
      'catatan': 'Kantong plastik dan daun menutup hampir seluruh inlet',
    },
    lalu: Duration.zero,
  );

  static List<Map<String, dynamic>> _contohTugas() => [
    _tugas(
      id: 't1',
      status: 'baru',
      skor: 0.86,
      rw: 'RW 05',
      jenis: 'gorong_gorong',
      lat: -6.9441,
      lng: 107.6912,
      ai: _contohAi[0],
      lalu: const Duration(minutes: 40),
    ),
    _tugas(
      id: 't2',
      status: 'baru',
      skor: 0.71,
      rw: 'RW 02',
      jenis: 'terbuka',
      lat: -6.9418,
      lng: 107.6870,
      ai: _contohAi[1],
      lalu: const Duration(hours: 1, minutes: 15),
      // Laporan warga yang sama: setelah t2 diverifikasi bersih, laporan
      // ini ikut berubah menjadi "Sudah ditangani".
      laporanId: 'contoh-102',
    ),
    _tugas(
      id: 't3',
      status: 'dikerjakan',
      skor: 0.64,
      rw: 'RW 07',
      jenis: 'inlet_jalan',
      lat: -6.9460,
      lng: 107.6935,
      ai: const {
        'saluran_terlihat': true,
        'kelas_sumbatan': 'sedang',
        'skor_sumbatan': 0.48,
        'penyebab': ['sedimen'],
        'keyakinan': 'tinggi',
        'catatan': 'Sedimen menutup separuh lubang inlet',
      },
      lalu: const Duration(hours: 3),
    ),
    _tugas(
      id: 't4',
      status: 'selesai',
      skor: 0.52,
      rw: 'RW 03',
      jenis: 'terbuka',
      lat: -6.9405,
      lng: 107.6899,
      ai: const {
        'saluran_terlihat': true,
        'kelas_sumbatan': 'ringan',
        'skor_sumbatan': 0.3,
        'penyebab': ['plastik'],
        'keyakinan': 'sedang',
        'catatan': 'Beberapa sampah plastik di dasar saluran',
      },
      lalu: const Duration(days: 1),
    ),
  ];
}

final ApiClient api = ApiClient.fromConfig();
