class AppSettings {
  final bool hideMutedInsteadOfSilence;
  final bool keepMutedLog;

  const AppSettings({
    this.hideMutedInsteadOfSilence = false,
    this.keepMutedLog = false,
  });

  AppSettings copyWith({
    bool? hideMutedInsteadOfSilence,
    bool? keepMutedLog,
  }) {
    return AppSettings(
      hideMutedInsteadOfSilence:
          hideMutedInsteadOfSilence ?? this.hideMutedInsteadOfSilence,
      keepMutedLog: keepMutedLog ?? this.keepMutedLog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hideMutedInsteadOfSilence': hideMutedInsteadOfSilence,
      'keepMutedLog': keepMutedLog,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      hideMutedInsteadOfSilence:
          json['hideMutedInsteadOfSilence'] as bool? ?? false,
      keepMutedLog: json['keepMutedLog'] as bool? ?? false,
    );
  }
}
