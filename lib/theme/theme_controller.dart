import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zim_tracker/theme/volt_theme.dart';

/// Owns the app-wide dark/light toggle. VoltTheme.isDark is the actual
/// source of truth read by every color getter (kept there so VoltTheme
/// doesn't need a BuildContext to know which palette to use); this
/// controller's job is just to flip that flag, persist the choice, and
/// notify listeners so Provider-watching widgets rebuild.
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'is_dark_mode_v1';

  ThemeController() {
    _loadSaved();
  }

  bool get isDark => VoltTheme.isDark;

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey);
    if (saved != null && saved != VoltTheme.isDark) {
      VoltTheme.isDark = saved;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    VoltTheme.isDark = !VoltTheme.isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, VoltTheme.isDark);
  }
}
