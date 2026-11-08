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
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<Report> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  File? localPhoto(String reportId) {
    final path = _localPhotos[reportId];
    return path == null ? null : File(path);
  }

  int count(String status) => _items.where((r) => r.status == status).length;

  void addSubmitted(Report report, File photo) {
    _localPhotos[report.id] = photo.path;
    _items = [report, ..._items.where((r) => r.id != report.id)];
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
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
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}

/// Tugas petugas, diurutkan: yang belum selesai di atas, prioritas tertinggi
/// lebih dulu (proposal 3.2 langkah 3: diurutkan dari skor tertinggi).
class TaskRepository extends ChangeNotifier {
  List<Task> _items = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<Task> get items => _items;
  List<Task> get aktif => _items.where((t) => !t.selesai).toList();
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final tasks = await api.myTasks();
      tasks.sort(_urutan);
      _items = tasks;
      _loaded = true;
    } on ApiException catch (e) {
      _error = e.message;
      if (e.unauthorized) await sessionStore.logout();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static int _urutan(Task a, Task b) {
    if (a.selesai != b.selesai) return a.selesai ? 1 : -1;
    return (b.skorPrioritas ?? 0).compareTo(a.skorPrioritas ?? 0);
  }

  void clear() {
    _items = const [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}

final reportRepository = ReportRepository();
final taskRepository = TaskRepository();
