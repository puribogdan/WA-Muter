import 'package:flutter/foundation.dart';
import '../core/models/app_settings.dart';
import '../core/services/app_settings_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  final AppSettingsService _service;

  AppSettingsProvider(this._service);

  bool _isLoading = true;
  AppSettings _settings = const AppSettings();

  bool get isLoading => _isLoading;
  AppSettings get settings => _settings;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _settings = await _service.getSettings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setHideMutedInsteadOfSilence(bool value) async {
    _settings = _settings.copyWith(hideMutedInsteadOfSilence: value);
    await _service.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setMasterMuteEnabled(bool value) async {
    _settings = _settings.copyWith(masterMuteEnabled: value);
    await _service.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setKeepMutedLog(bool value) async {
    _settings = _settings.copyWith(keepMutedLog: value);
    await _service.saveSettings(_settings);
    notifyListeners();
  }
}
