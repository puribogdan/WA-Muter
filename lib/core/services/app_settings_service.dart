import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import 'native_bridge.dart';

class AppSettingsService {
  static const _settingsKey = 'app_settings_v1';

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    final settings = raw == null || raw.isEmpty
        ? const AppSettings()
        : AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    await NativeBridge.saveAppSettings(settings.toJson());
    return settings;
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    await NativeBridge.saveAppSettings(settings.toJson());
  }
}
