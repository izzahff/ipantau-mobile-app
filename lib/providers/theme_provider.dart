import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light/dark theme + notification preference, persisted locally.
class ThemeProvider extends ChangeNotifier {
  static const _kDark = 'tema_gelap';
  static const _kNotif = 'notifikasi';

  bool _dark = false;
  bool _notif = true;

  bool get isDark => _dark;
  bool get notifikasi => _notif;
  ThemeMode get mode => _dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _dark = prefs.getBool(_kDark) ?? false;
    _notif = prefs.getBool(_kNotif) ?? true;
    notifyListeners();
  }

  Future<void> setDark(bool v) async {
    _dark = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, v);
  }

  Future<void> setNotifikasi(bool v) async {
    _notif = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotif, v);
  }
}
