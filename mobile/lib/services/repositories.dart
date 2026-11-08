import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/report.dart';
import '../models/rw_risk.dart';
import '../models/task.dart';
import 'api_client.dart';
import 'session_store.dart';

/// Laporan yang dikirim dari HP ini (mobile SRS FR-MB-06).
///
/// Disimpan di HP supaya warga tanpa login tetap bisa melacak laporannya.
/// Refresh memanggil `GET /reports/:id` untuk tiap laporan (backend SRS 7.3).
class ReportRepository extends ChangeNotifier {
  static const _key = 'rivora.laporan_saya';

  List<Report> _items = const [];
  final Map<String, String> _localPhotos = {};
  final Map<String, String> _localSesudah = {};
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<Report> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  File? localPhoto(String reportId) => _file(_localPhotos[reportId]);

  /// Foto sesudah yang diambil di HP ini (petugas yang juga pelapor).
  File? localSesudah(String reportId) => _file(_localSesudah[reportId]);

  static File? _file(String? path) => path == null ? null : File(path);

  int count(String status) => _items.where((r) => r.status == status).length;

  /// Muat dari penyimpanan HP. Mode contoh: isi 2 laporan contoh sekali.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _items = [
          for (final e in list)
            Report.fromJson(
              (e as Map<String, dynamic>)['laporan'] as Map<String, dynamic>,
            ),
        ];
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          final id = '${(m['laporan'] as Map<String, dynamic>)['id']}';
          if (m['foto_lokal'] is String) {
            _localPhotos[id] = m['foto_lokal'] as String;
          }
          if (m['sesudah_lokal'] is String) {
            _localSesudah[id] = m['sesudah_lokal'] as String;
          }
        }
      } on Object catch (e) {
        debugPrint('Laporan tersimpan rusak, diabaikan: $e');
        _items = const [];
      }
    } else if (AppConfig.useMockApi) {
      final contoh = <Report>[];
      for (final id in MockApiClient.idLaporanContoh) {
        try {
          contoh.add(await api.getReport(id));
        } on ApiException {
          // Lewati.
        }
      }
      _items = contoh;
      await _save();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([
        for (final r in _items)
          {
            'laporan': r.toJson(),
            'foto_lokal': _localPhotos[r.id],
            'sesudah_lokal': _localSesudah[r.id],
          },
      ]),
    );
  }

  void addSubmitted(Report report, File photo) {
    _localPhotos[report.id] = photo.path;
    _items = [report, ..._items.where((r) => r.id != report.id)];
    notifyListeners();
    _save();
  }

  void setLocalSesudah(String reportId, File photo) {
    _localSesudah[reportId] = photo.path;
    notifyListeners();
    _save();
  }

  /// Ambil status terbaru tiap laporan. Laporan yang gagal dimuat tetap
  /// tampil dengan data terakhir (foto dan riwayat tidak hilang).
  Future<void> refresh({bool silent = false}) async {
    if (_loading) return;
    if (!_loaded) await load();
    if (_items.isEmpty) return;
    _loading = true;
    _error = null;
    if (!silent) notifyListeners();
    var gagal = 0;
    final diminta = _items;
    final hasil = <String, Report>{};
    await Future.wait(
      diminta.map((r) async {
        try {
          hasil[r.id] = await api.getReport(r.id);
        } on ApiException {
          gagal++;
        }
      }),
    );
    // Gabung ke daftar *terkini* per ID: laporan yang baru dikirim selama
    // refresh berjalan tetap ada (tidak tertimpa daftar lama).
    _items = [for (final r in _items) hasil[r.id] ?? r];
    if (gagal > 0 && !silent) {
      _error = gagal == diminta.length
          ? 'Status laporan belum bisa dimuat. Menampilkan data terakhir.'
          : '$gagal laporan belum bisa diperbarui.';
    }
    _loading = false;
    notifyListeners();
    await _save();
  }

  Report? byId(String id) {
    for (final r in _items) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// `GET /reports/:id` untuk satu laporan (dibuka dari daftar, FR-MB-06).
  Future<void> refreshOne(String id) async {
    try {
      final r = await api.getReport(id);
      _items = [for (final x in _items) x.id == id ? r : x];
      notifyListeners();
      await _save();
    } on ApiException {
      // Tetap tampilkan data terakhir.
    }
  }
}

/// Tugas petugas (mobile SRS FR-MB-08): `baru` dan `dikerjakan` di atas,
/// `selesai` di bawah; di dalamnya sumbatan paling parah dulu, lalu yang
/// paling lama ditugaskan.
class TaskRepository extends ChangeNotifier {
  List<Task> _items = const [];
  final Set<String> _knownIds = {};
  final _tugasMasuk = StreamController<Task>.broadcast();
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  /// Naik setiap [clear] (sesi berakhir). Respons dari generasi lama
  /// dibuang supaya tugas akun sebelumnya tidak muncul lagi.
  int _generasi = 0;
  Future<void>? _berjalan;

  List<Task> get items => _items;
  List<Task> get aktif => _items.where((t) => !t.selesai).toList();
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  /// Tugas yang belum pernah terlihat sejak daftar pertama dimuat.
  Stream<Task> get tugasMasuk => _tugasMasuk.stream;

  Task? byId(String id) {
    for (final t in _items) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Muat ulang tugas. Kalau sedang memuat, kembalikan permintaan yang
  /// sedang berjalan (pemanggil bisa menunggu hasilnya).
  Future<void> refresh({bool silent = false}) {
    final berjalan = _berjalan;
    if (berjalan != null) return berjalan;
    final generasi = _generasi;
    late final Future<void> f;
    f = _muat(generasi, silent: silent).whenComplete(() {
      if (identical(_berjalan, f)) _berjalan = null;
    });
    return _berjalan = f;
  }

  Future<void> _muat(int generasi, {required bool silent}) async {
    _loading = true;
    _error = null;
    if (!silent) notifyListeners();
    try {
      final tasks = await api.myTasks()
        ..sort(_urutan);
      if (generasi != _generasi) return;
      final sudahPernahMuat = _loaded;
      _items = tasks;
      _loaded = true;
      for (final t in tasks) {
        final baru = _knownIds.add(t.id);
        if (baru && sudahPernahMuat && !t.selesai) _tugasMasuk.add(t);
      }
    } on ApiException catch (e) {
      if (generasi != _generasi) return;
      if (!silent) _error = e.message;
      // Sesi berakhir: sessionServices ikut mengosongkan daftar ini.
      if (e.unauthorized) await sessionStore.logout();
    } finally {
      if (generasi == _generasi) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void replace(Task updated) {
    _items = [for (final t in _items) t.id == updated.id ? updated : t]
      ..sort(_urutan);
    notifyListeners();
  }

  static int _urutan(Task a, Task b) {
    if (a.selesai != b.selesai) return a.selesai ? 1 : -1;
    final skor = (b.skorSebelum ?? 0).compareTo(a.skorSebelum ?? 0);
    if (skor != 0) return skor;
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Kosongkan data petugas (sesi berakhir). Permintaan yang masih
  /// berjalan dibuang hasilnya; permintaan sesi baru tidak terhalang.
  void clear() {
    _generasi++;
    _berjalan = null;
    _loading = false;
    _items = const [];
    _knownIds.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}

/// Skor risiko per RW dari backend (`GET /rw/risk`). Dipakai peta risiko,
/// "risiko di wilayahmu" (proposal Tabel 4), dan skor RW sebelum/sesudah
/// verifikasi.
class RiskRepository extends ChangeNotifier {
  /// Kelurahan pilot **[ASUMSI]** untuk warga tanpa login.
  static const kelurahanPilot = 1;

  PetaRisiko? _data;
  bool _loading = false;
  String? _error;

  PetaRisiko? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  int get _kelurahan => sessionStore.value?.kelurahanId ?? kelurahanPilot;

  Future<PetaRisiko?> refresh() async {
    if (_loading) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await api.rwRisk(_kelurahan);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
    return _data;
  }
}

final reportRepository = ReportRepository();
final taskRepository = TaskRepository();
final riskRepository = RiskRepository();
