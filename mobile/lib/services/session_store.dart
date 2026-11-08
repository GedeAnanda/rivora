import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';
import 'api_client.dart';

/// Sesi petugas, disimpan di perangkat supaya tidak perlu masuk ulang
/// setiap app dibuka. `null` = warga tanpa login (mobile SRS bagian 2).
class SessionStore extends ValueNotifier<Session?> {
  SessionStore() : super(null);

  static const _key = 'rivora.session';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final s = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (s.isPetugas) {
        _set(s);
      } else {
        await prefs.remove(_key);
      }
    } on Object {
      await prefs.remove(_key);
    }
  }

  /// Hanya akun petugas yang diterima (mobile SRS FR-MB-07).
  Future<void> login(String username, String password) async {
    final session = await api.login(username, password);
    if (!session.isPetugas) {
      throw const ApiException('Akun ini bukan akun petugas.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
    _set(session);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    _set(null);
  }

  void _set(Session? session) {
    api.token = session?.token;
    value = session;
  }
}

final sessionStore = SessionStore();
