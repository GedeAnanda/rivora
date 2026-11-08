import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'location_service.dart';

/// Kategori hujan harian BMKG (mm per 24 jam).
enum KategoriHujan {
  tidak('Tidak hujan'),
  ringan('Hujan ringan'),
  sedang('Hujan sedang'),
  lebat('Hujan lebat'),
  sangatLebat('Hujan sangat lebat'),
  ekstrem('Hujan ekstrem');

  const KategoriHujan(this.label);

  final String label;

  static KategoriHujan dariTotal(double mm) => mm < 0.5
      ? tidak
      : mm < 20
      ? ringan
      : mm < 50
      ? sedang
      : mm < 100
      ? lebat
      : mm < 150
      ? sangatLebat
      : ekstrem;

  /// Ambang "hujan lebat diprediksi" (RENCANA_FINAL bagian 4).
  bool get perluBertindak => index >= lebat.index;
}

class HujanPerJam {
  const HujanPerJam(this.waktu, this.mm, this.peluang);

  final DateTime waktu;
  final double mm;

  /// Peluang hujan (%), bisa `null`.
  final int? peluang;
}

class PrakiraanHujan {
  const PrakiraanHujan({
    required this.jam,
    required this.diambil,
    required this.lokasiPerkiraan,
  });

  /// Parse respons Open-Meteo `hourly=precipitation,precipitation_probability`
  /// dengan `timezone=Asia/Jakarta` (waktu lokal tanpa offset).
  factory PrakiraanHujan.dariOpenMeteo(
    Map<String, dynamic> json, {
    required bool lokasiPerkiraan,
    DateTime? diambil,
  }) {
    final hourly = json['hourly'] as Map<String, dynamic>;
    final times = hourly['time'] as List<dynamic>;
    final mm = hourly['precipitation'] as List<dynamic>;
    final prob = hourly['precipitation_probability'] as List<dynamic>?;
    return PrakiraanHujan(
      jam: [
        for (var i = 0; i < times.length; i++)
          HujanPerJam(
            DateTime.parse(times[i] as String),
            (mm[i] as num?)?.toDouble() ?? 0,
            (prob?[i] as num?)?.round(),
          ),
      ],
      diambil: diambil ?? DateTime.now(),
      lokasiPerkiraan: lokasiPerkiraan,
    );
  }

  final List<HujanPerJam> jam;
  final DateTime diambil;

  /// `true` kalau posisi pengguna belum diketahui dan memakai titik pilot.
  final bool lokasiPerkiraan;

  double get total => jam.fold(0, (s, h) => s + h.mm);

  KategoriHujan get kategori => KategoriHujan.dariTotal(total);

  HujanPerJam? get puncak {
    if (jam.isEmpty) return null;
    final p = jam.reduce((a, b) => b.mm > a.mm ? b : a);
    return p.mm > 0 ? p : null;
  }

  /// Jam dengan peluang hujan tertinggi (kalau Open-Meteo mengirimnya).
  HujanPerJam? get peluangTertinggi {
    HujanPerJam? best;
    for (final h in jam) {
      final p = h.peluang;
      if (p != null && (best == null || p > best.peluang!)) best = h;
    }
    return best;
  }

  /// Jam pertama dengan hujan ≥ 0,5 mm.
  HujanPerJam? get mulaiHujan {
    for (final h in jam) {
      if (h.mm >= 0.5) return h;
    }
    return null;
  }

  /// Komponen hujan (H) skor risiko, 0–1: total 24 jam ÷ 100 mm [ASUMSI],
  /// RENCANA_FINAL bagian 4.
  double get komponenHujan => (total / 100).clamp(0, 1);
}

/// Prakiraan hujan 24 jam dari Open-Meteo (proposal Tabel 2: sumber
/// komponen hujan skor risiko). Tanpa API key. Disimpan 15 menit.
class WeatherService extends ChangeNotifier {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Titik pilot di daerah Gedebage, dipakai kalau posisi belum diketahui.
  static const pilotLat = -6.9430;
  static const pilotLng = 107.6890;
  static const _segar = Duration(minutes: 15);

  PrakiraanHujan? _data;
  bool _loading = false;
  String? _error;

  PrakiraanHujan? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> refresh({bool paksa = false}) async {
    if (_loading) return;
    final d = _data;
    if (!paksa && d != null && DateTime.now().difference(d.diambil) < _segar) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final pos = await locationService.lastKnown();
      final lat = pos?.latitude ?? pilotLat;
      final lng = pos?.longitude ?? pilotLng;
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toStringAsFixed(4),
        'longitude': lng.toStringAsFixed(4),
        'hourly': 'precipitation,precipitation_probability',
        'forecast_hours': '24',
        'timezone': 'Asia/Jakarta',
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw HttpException('Open-Meteo ${res.statusCode}');
      }
      _data = PrakiraanHujan.dariOpenMeteo(
        jsonDecode(res.body) as Map<String, dynamic>,
        lokasiPerkiraan: pos == null,
      );
    } on Exception catch (e) {
      debugPrint('Prakiraan hujan gagal: $e');
      _error = 'Prakiraan hujan belum bisa dimuat. Cek internet.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

final weatherService = WeatherService();
