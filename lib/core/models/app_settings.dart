enum AppThemeMode { light, dark, system }

class AppSettings {
  final AppThemeMode themeMode;
  final bool customAlphabetEnabled;
  final bool onboardingComplete;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.customAlphabetEnabled = true,
    this.onboardingComplete = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? customAlphabetEnabled,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      customAlphabetEnabled: customAlphabetEnabled ?? this.customAlphabetEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'customAlphabetEnabled': customAlphabetEnabled,
        'onboardingComplete': onboardingComplete,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.byName(json['themeMode'] as String? ?? 'system'),
        customAlphabetEnabled: json['customAlphabetEnabled'] as bool? ?? true,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      );
}
