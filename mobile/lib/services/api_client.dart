import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config.dart';
import '../models/jenis_saluran.dart';
import '../models/report.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pintu aplikasi ke backend REST (kontrak: docs/API.md).
abstract class ApiClient {
  factory ApiClient.fromConfig() =>
      AppConfig.useMockApi ? MockApiClient() : HttpApiClient(AppConfig.apiUrl);

  /// `POST /reports`: kirim foto + lokasi, backend memanggil AI vision
  /// dan mengembalikan laporan beserta hasil analisisnya.
  Future<Report> submitReport({
    required File foto,
    required double lat,
    required double lng,
    required DateTime capturedAt,
    required JenisSaluran jenisSaluran,
  });
}

class HttpApiClient implements ApiClient {
  HttpApiClient(String baseUrl, {http.Client? client})
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  /// Analisis AI bisa makan waktu beberapa detik.
  static const _timeout = Duration(seconds: 60);

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

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'Server terlalu lama merespons. Coba kirim lagi.',
      );
    } on SocketException {
      throw const ApiException('Tidak bisa terhubung ke server. Cek internet.');
    } on http.ClientException {
      throw const ApiException('Koneksi ke server terputus. Coba kirim lagi.');
    }

    final body = _decode(response.body);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body != null) {
      return Report.fromJson(body);
    }
    throw ApiException(
      body?['error'] as String? ??
          'Laporan gagal dikirim (kode ${response.statusCode}).',
    );
  }

  Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

/// Backend tiruan: mengembalikan hasil AI contoh bergiliran
/// (berat → sedang → tidak terlihat → bersih) supaya semua tampilan teruji.
class MockApiClient implements ApiClient {
  MockApiClient({this.delay = const Duration(seconds: 2)});

  final Duration delay;
  int _counter = 0;

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
    return Report.fromJson({
      'id': 'contoh-$_counter',
      'status': ai['kelas_sumbatan'] == 'tidak_terlihat'
          ? 'cek_manual'
          : 'dikirim',
      'jenis_saluran': jenisSaluran.apiValue,
      'lat': lat,
      'lng': lng,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'ai': ai,
    });
  }
}

final ApiClient api = ApiClient.fromConfig();
