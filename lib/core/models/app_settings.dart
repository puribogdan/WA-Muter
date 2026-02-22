class AppSettings {
  final bool masterMuteEnabled;
  final bool hideMutedInsteadOfSilence;
  final bool keepMutedLog;

  const AppSettings({
    this.masterMuteEnabled = true,
    this.hideMutedInsteadOfSilence = false,
    this.keepMutedLog = true,
  });

  AppSettings copyWith({
    bool? masterMuteEnabled,
    bool? hideMutedInsteadOfSilence,
    bool? keepMutedLog,
  }) {
    return AppSettings(
      masterMuteEnabled: masterMuteEnabled ?? this.masterMuteEnabled,
      hideMutedInsteadOfSilence:
          hideMutedInsteadOfSilence ?? this.hideMutedInsteadOfSilence,
      keepMutedLog: keepMutedLog ?? this.keepMutedLog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masterMuteEnabled': masterMuteEnabled,
      'hideMutedInsteadOfSilence': hideMutedInsteadOfSilence,
      'keepMutedLog': keepMutedLog,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      masterMuteEnabled: json['masterMuteEnabled'] as bool? ?? true,
      hideMutedInsteadOfSilence:
          json['hideMutedInsteadOfSilence'] as bool? ?? false,
      keepMutedLog: json['keepMutedLog'] as bool? ?? true,
    );
  }
}
