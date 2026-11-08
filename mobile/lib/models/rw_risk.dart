import 'package:latlong2/latlong.dart';

import 'verification.dart';

/// Skor risiko satu RW dari `GET /rw/risk` (backend SRS 7.4, GeoJSON).
/// Untuk app: peta risiko dan "risiko di wilayahmu" (proposal Tabel 4:
/// warga mengetahui risiko di wilayahnya).
class RwRisk {
  const RwRisk({
    required this.rwId,
    required this.nama,
    required this.skor,
    required this.level,
    required this.polygon,
    this.alasan,
    this.hujan,
    this.sumbatan,
    this.kerentanan,
  });

  factory RwRisk.fromFeature(Map<String, dynamic> feature) {
    final p = feature['properties'] as Map<String, dynamic>;
    final geom = feature['geometry'] as Map<String, dynamic>?;
    final komponen = p['komponen'] as Map<String, dynamic>?;
    double? nilai(String k) =>
        ((komponen?[k] as Map<String, dynamic>?)?['nilai'] as num?)?.toDouble();
    final skor = (p['skor'] as num?)?.toDouble() ?? 0;
    return RwRisk(
      rwId: '${p['rw_id']}',
      nama: p['nama'] as String? ?? 'RW',
      skor: skor,
      level:
          LevelRisiko.fromApi(p['level'] as String?) ??
          LevelRisiko.dariSkor(skor),
      alasan: p['alasan'] as String?,
      hujan: nilai('hujan'),
      sumbatan: nilai('sumbatan'),
      kerentanan: nilai('kerentanan'),
      polygon: _cincinLuar(geom),
    );
  }

  final String rwId;
  final String nama;
  final double skor;
  final LevelRisiko level;

  /// Kalimat penjelasan dari backend (proposal 3.3: transparansi model).
  final String? alasan;
  final double? hujan;
  final double? sumbatan;
  final double? kerentanan;

  /// Cincin luar poligon RW. GeoJSON memakai urutan `[lng, lat]`.
  final List<LatLng> polygon;

  List<LatLng> get _sudut => polygon.length > 3 && polygon.first == polygon.last
      ? polygon.sublist(0, polygon.length - 1)
      : polygon;

  /// Pusat RW (rata-rata titik sudut). Peta menggambar risiko RW sebagai
  /// lingkaran lembut di titik ini, bukan kotak batas wilayah.
  LatLng? get pusat {
    if (polygon.length < 3) return null;
    final titik = _sudut;
    var lat = 0.0;
    var lng = 0.0;
    for (final t in titik) {
      lat += t.latitude;
      lng += t.longitude;
    }
    return LatLng(lat / titik.length, lng / titik.length);
  }

  /// Jari-jari lingkaran risiko dalam meter: 0,62 × jarak rata-rata pusat
  /// ke sudut. Untuk RW persegi ±0,44 × lebarnya, jadi ada celah tipis antar
  /// lingkaran RW tetangga dan label tidak tertimpa lingkaran lain.
  double get radiusMeter {
    final p = pusat;
    if (p == null) return 0;
    const jarak = Distance(roundResult: false);
    final titik = _sudut;
    var total = 0.0;
    for (final t in titik) {
      total += jarak(p, t);
    }
    return total / titik.length * 0.62;
  }

  /// Posisi label nama RW: di tepi selatan lingkaran. Badan pin menjulur
  /// ke atas dari titiknya, jadi label di bawah tidak tertimpa pin saluran
  /// yang berada di dalam RW.
  LatLng? get titikLabel {
    final p = pusat;
    if (p == null) return null;
    return const Distance().offset(p, radiusMeter, 180);
  }

  /// Titik di dalam poligon? (ray casting).
  bool berisi(LatLng t) {
    var di = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      final potong =
          (a.latitude > t.latitude) != (b.latitude > t.latitude) &&
          t.longitude <
              (b.longitude - a.longitude) *
                      (t.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude;
      if (potong) di = !di;
    }
    return di;
  }

  static List<LatLng> _cincinLuar(Map<String, dynamic>? geom) {
    if (geom == null || geom['type'] != 'Polygon') return const [];
    final rings = geom['coordinates'] as List<dynamic>;
    if (rings.isEmpty) return const [];
    return [
      for (final c in rings.first as List<dynamic>)
        LatLng(
          ((c as List<dynamic>)[1] as num).toDouble(),
          (c[0] as num).toDouble(),
        ),
    ];
  }
}

/// Seluruh respons `GET /rw/risk`: daftar RW + meta hujan.
class PetaRisiko {
  const PetaRisiko({
    required this.rw,
    this.hujanMm,
    this.hujanLebatDiprediksi = false,
    this.hujanSumber,
  });

  factory PetaRisiko.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return PetaRisiko(
      rw: [
        for (final f in (json['features'] as List<dynamic>? ?? const []))
          RwRisk.fromFeature(f as Map<String, dynamic>),
      ],
      hujanMm: (meta?['hujan_24j_mm'] as num?)?.toDouble(),
      hujanLebatDiprediksi: meta?['hujan_lebat_diprediksi'] as bool? ?? false,
      hujanSumber: meta?['hujan_sumber'] as String?,
    );
  }

  final List<RwRisk> rw;
  final double? hujanMm;
  final bool hujanLebatDiprediksi;

  /// `open_meteo` | `cache` | `tidak_tersedia` | `simulasi_demo` [DEMO].
  final String? hujanSumber;

  RwRisk? rwBernama(String? nama) {
    if (nama == null) return null;
    for (final r in rw) {
      if (r.nama == nama) return r;
    }
    return null;
  }

  RwRisk? rwDiTitik(LatLng t) {
    for (final r in rw) {
      if (r.berisi(t)) return r;
    }
    return null;
  }
}
