enum AppThemePreference {
  system,
  light,
  dark;

  String get storageValue => name;

  static AppThemePreference fromStorage(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      case 'system':
      default:
        return AppThemePreference.system;
    }
  }
}

class AppSettings {
  final bool masterMuteEnabled;
  final bool hideMutedInsteadOfSilence;
  final bool keepMutedLog;
  final AppThemePreference themePreference;
  final bool isPremium;

  const AppSettings({
    this.masterMuteEnabled = true,
    this.hideMutedInsteadOfSilence = false,
    this.keepMutedLog = true,
    this.themePreference = AppThemePreference.system,
    this.isPremium = false,
  });

  AppSettings copyWith({
    bool? masterMuteEnabled,
    bool? hideMutedInsteadOfSilence,
    bool? keepMutedLog,
    AppThemePreference? themePreference,
    bool? isPremium,
  }) {
    return AppSettings(
      masterMuteEnabled: masterMuteEnabled ?? this.masterMuteEnabled,
      hideMutedInsteadOfSilence:
          hideMutedInsteadOfSilence ?? this.hideMutedInsteadOfSilence,
      keepMutedLog: keepMutedLog ?? this.keepMutedLog,
      themePreference: themePreference ?? this.themePreference,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masterMuteEnabled': masterMuteEnabled,
      'hideMutedInsteadOfSilence': hideMutedInsteadOfSilence,
      'keepMutedLog': keepMutedLog,
      'themePreference': themePreference.storageValue,
      'isPremium': isPremium,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      masterMuteEnabled: json['masterMuteEnabled'] as bool? ?? true,
      hideMutedInsteadOfSilence:
          json['hideMutedInsteadOfSilence'] as bool? ?? false,
      keepMutedLog: json['keepMutedLog'] as bool? ?? true,
      themePreference:
          AppThemePreference.fromStorage(json['themePreference'] as String?),
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}
