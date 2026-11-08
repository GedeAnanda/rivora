import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';
import 'api_client.dart';

/// Sesi login, disimpan di perangkat supaya tidak perlu masuk ulang
/// setiap app dibuka (penting saat demo).
class SessionStore extends ValueNotifier<Session?> {
  SessionStore() : super(null);

  static const _key = 'rivora.session';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      _set(Session.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } on FormatException {
      await prefs.remove(_key);
    }
  }

  Future<void> login(String username, String password) async {
    final session = await api.login(username, password);
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
