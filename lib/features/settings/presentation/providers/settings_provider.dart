import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum AppLanguage { arabic, english }

extension AppLanguageX on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.english:
        return 'English';
    }
  }
}

enum AppThemeMode { light, dark, system }

const themePreferenceKey = 'aqar_theme_mode';
final initialThemeModeProvider = Provider<AppThemeMode>(
  (ref) => AppThemeMode.system,
);
AppThemeMode savedThemeMode(String? value) => AppThemeMode.values.firstWhere(
  (mode) => mode.name == value,
  orElse: () => AppThemeMode.system,
);

extension AppThemeModeX on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.light:
        return 'فاتح';
      case AppThemeMode.dark:
        return 'داكن';
      case AppThemeMode.system:
        return 'تلقائي';
    }
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState {
  final AppLanguage language;
  final AppThemeMode themeMode;
  final bool pushNotifications;
  final bool newMessages;
  final bool bookingUpdates;
  final bool searchAlerts;
  final bool promotions;

  const SettingsState({
    required this.language,
    required this.themeMode,
    required this.pushNotifications,
    required this.newMessages,
    required this.bookingUpdates,
    required this.searchAlerts,
    required this.promotions,
  });

  SettingsState copyWith({
    AppLanguage? language,
    AppThemeMode? themeMode,
    bool? pushNotifications,
    bool? newMessages,
    bool? bookingUpdates,
    bool? searchAlerts,
    bool? promotions,
  }) => SettingsState(
    language: language ?? this.language,
    themeMode: themeMode ?? this.themeMode,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    newMessages: newMessages ?? this.newMessages,
    bookingUpdates: bookingUpdates ?? this.bookingUpdates,
    searchAlerts: searchAlerts ?? this.searchAlerts,
    promotions: promotions ?? this.promotions,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => SettingsState(
    language: AppLanguage.arabic,
    themeMode: ref.read(initialThemeModeProvider),
    pushNotifications: true,
    newMessages: true,
    bookingUpdates: true,
    searchAlerts: false,
    promotions: false,
  );

  void setLanguage(AppLanguage v) => state = state.copyWith(language: v);
  Future<void> setThemeMode(AppThemeMode v) async {
    state = state.copyWith(themeMode: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themePreferenceKey, v.name);
  }

  void setPushNotifications(bool v) {
    // Turning off master also disables all sub-toggles
    state = state.copyWith(
      pushNotifications: v,
      newMessages: v ? state.newMessages : false,
      bookingUpdates: v ? state.bookingUpdates : false,
      searchAlerts: v ? state.searchAlerts : false,
      promotions: v ? state.promotions : false,
    );
  }

  void setNewMessages(bool v) => state = state.copyWith(newMessages: v);
  void setBookingUpdates(bool v) => state = state.copyWith(bookingUpdates: v);
  void setSearchAlerts(bool v) => state = state.copyWith(searchAlerts: v);
  void setPromotions(bool v) => state = state.copyWith(promotions: v);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
