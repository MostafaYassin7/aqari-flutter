/// App-wide constants for Aqar App.
/// Import this wherever you need keys, durations, or spacing values.
class AppConstants {
  AppConstants._();

  // ── App info ───────────────────────────────────────────
  static const String appName = 'عقار';
  static const String appNameEn = 'Aqar';
  static const String appVersion = '1.0.0';

  // ── SharedPreferences keys ─────────────────────────────
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';

  // ── Durations (ms) ─────────────────────────────────────
  static const int splashDurationMs = 2000;
  static const int animationFastMs = 200;
  static const int animationNormalMs = 300;
  static const int animationSlowMs = 500;

  // ── Spacing ────────────────────────────────────────────
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // ── Border radius ──────────────────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircle = 100.0;

  // ── UI dimensions ──────────────────────────────────────
  static const double listingCardImageHeight = 220.0;
  static const double bottomNavHeight = 60.0;
  static const double appBarHeight = 56.0;
  static const double buttonHeight = 52.0;
}

/// Named routes — single source of truth for all navigation paths.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String phoneInput = '/login/phone';
  static const String otp = '/login/otp';
  static const String register = '/login/register';
  static const String home = '/home';
  static const String propertyDetails = '/property/:id';
  static const String projectDetails = '/project/:id';
  static const String rentalDetails = '/rental/:id';
  static const String search = '/search';
  static const String addListing = '/add-listing';
  static const String account = '/account';
  static const String chat = '/chat';
  static const String chatDetail = '/chat/:id';
  static const String wallet = '/wallet';
  static const String notifications = '/notifications';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String profile = '/profile/:id';
  static const String subscription = '/subscription';
  static const String myListings = '/my-listings';
  static const String myDeals = '/my-deals';
  static const String bookings = '/bookings';
  static const String crm = '/crm';
  static const String promotion = '/promotion';
  static const String updateProfile = '/update-profile';
}
