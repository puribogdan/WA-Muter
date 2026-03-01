import 'package:flutter/foundation.dart';
import '../core/models/app_settings.dart';
import '../core/services/app_settings_service.dart';
import '../core/services/monetization_config.dart';
import '../core/services/purchase_service.dart';

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
    if (MonetizationConfig.adminPremiumOverride && !_settings.isPremium) {
      _settings = _settings.copyWith(isPremium: true);
      await _service.saveSettings(_settings);
    }
    await _syncPremiumFromStore(saveIfChanged: true);
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

  Future<void> setThemePreference(AppThemePreference value) async {
    _settings = _settings.copyWith(themePreference: value);
    await _service.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    if (MonetizationConfig.adminPremiumOverride) {
      value = true;
    }
    _settings = _settings.copyWith(isPremium: value);
    await _service.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> syncPremiumFromStore() async {
    await _syncPremiumFromStore(saveIfChanged: true);
    notifyListeners();
  }

  Future<void> _syncPremiumFromStore({required bool saveIfChanged}) async {
    if (MonetizationConfig.adminPremiumOverride) {
      if (!_settings.isPremium) {
        _settings = _settings.copyWith(isPremium: true);
        if (saveIfChanged) {
          await _service.saveSettings(_settings);
        }
      }
      return;
    }
    final remote = await PurchaseService.getIsPremiumEntitled();
    if (remote == null || remote == _settings.isPremium) return;
    _settings = _settings.copyWith(isPremium: remote);
    if (saveIfChanged) {
      await _service.saveSettings(_settings);
    }
  }
}
