import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/report.dart';
import '../models/task.dart';
import 'api_client.dart';
import 'session_store.dart';

/// Daftar laporan milik pengguna. Laporan yang baru dikirim langsung
/// muncul tanpa menunggu refresh, dan foto lokalnya dipakai sebagai
/// gambar sampai server mengirim `foto_url`.
class ReportRepository extends ChangeNotifier {
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

  /// Foto sesudah dibersihkan yang diambil di perangkat ini (petugas yang
  /// juga pelapor, atau mode contoh).
  File? localSesudah(String reportId) => _file(_localSesudah[reportId]);

  static File? _file(String? path) => path == null ? null : File(path);

  int count(String status) => _items.where((r) => r.status == status).length;

  void addSubmitted(Report report, File photo) {
    _localPhotos[report.id] = photo.path;
    _items = [report, ..._items.where((r) => r.id != report.id)];
    notifyListeners();
  }

  void setLocalSesudah(String reportId, File photo) {
    _localSesudah[reportId] = photo.path;
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    if (!silent) notifyListeners();
    try {
      _items = await api.myReports();
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
      if (e.unauthorized) await sessionStore.logout();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _items = const [];
    _localPhotos.clear();
    _localSesudah.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}

/// Tugas petugas, diurutkan: yang belum selesai di atas, prioritas tertinggi
/// lebih dulu (proposal 3.2 langkah 3: diurutkan dari skor tertinggi).
class TaskRepository extends ChangeNotifier {
  List<Task> _items = const [];
  final Set<String> _knownIds = {};
  final _tugasMasuk = StreamController<Task>.broadcast();
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<Task> get items => _items;
  List<Task> get aktif => _items.where((t) => !t.selesai).toList();
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  /// Tugas yang belum pernah terlihat sejak daftar pertama dimuat.
  /// Dipakai untuk notifikasi di dalam aplikasi.
  Stream<Task> get tugasMasuk => _tugasMasuk.stream;

  Task? byId(String id) {
    for (final t in _items) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> refresh({bool silent = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    if (!silent) notifyListeners();
    try {
      final tasks = await api.myTasks();
      tasks.sort(_urutan);
      final sudahPernahMuat = _loaded;
      _items = tasks;
      _loaded = true;
      for (final t in tasks) {
        final baru = _knownIds.add(t.id);
        if (baru && sudahPernahMuat && !t.selesai) _tugasMasuk.add(t);
      }
    } on ApiException catch (e) {
      // Refresh diam-diam (polling) tidak menampilkan error ke layar.
      if (!silent) _error = e.message;
      if (e.unauthorized) await sessionStore.logout();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Ganti satu tugas dengan versi terbaru dari server (mis. setelah
  /// verifikasi), lalu urutkan ulang.
  void replace(Task updated) {
    final list = [for (final t in _items) t.id == updated.id ? updated : t]
      ..sort(_urutan);
    _items = list;
    notifyListeners();
  }

  static int _urutan(Task a, Task b) {
    if (a.selesai != b.selesai) return a.selesai ? 1 : -1;
    return (b.skorPrioritas ?? 0).compareTo(a.skorPrioritas ?? 0);
  }

  void clear() {
    _items = const [];
    _knownIds.clear();
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}

final reportRepository = ReportRepository();
final taskRepository = TaskRepository();
