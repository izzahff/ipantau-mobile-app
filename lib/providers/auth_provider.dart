import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _pengguna;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  Map<String, dynamic>? get pengguna => _pengguna;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _token != null;
  String get peranan => _pengguna?['peranan'] ?? '';

  Future<bool> login(String email, String kataLaluan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await ApiService.login(
      email: email,
      kataLaluan: kataLaluan,
    );

    if (result['success'] == true) {
      _token = result['token'];
      _pengguna = result['pengguna'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('pengguna', jsonEncode(_pengguna));

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'] ?? 'Log masuk gagal.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _pengguna = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('pengguna');

    notifyListeners();
  }

  Future<void> applyPengguna(Map<String, dynamic> pengguna) async {
    _pengguna = Map<String, dynamic>.from(pengguna);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pengguna', jsonEncode(_pengguna));
    notifyListeners();
  }

  Future<bool> refreshPenggunaFromServer() async {
    if (_token == null) return false;
    final result = await ApiService.getMe(_token!);
    if (result['success'] == true && result['pengguna'] != null) {
      await applyPengguna(
        Map<String, dynamic>.from(result['pengguna'] as Map),
      );
      return true;
    }
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}