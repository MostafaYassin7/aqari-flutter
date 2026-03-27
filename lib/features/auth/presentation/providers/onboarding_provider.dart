import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/auth_storage.dart';

/// Provides a SharedPreferences instance, cached for the app lifetime.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// True if the user has already completed the onboarding flow.
final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(AppConstants.keyHasSeenOnboarding) ?? false;
});

/// True if the user has a valid, non-expired JWT token.
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  return AuthStorage.isLoggedIn();
});

/// Call this after the user completes onboarding to persist the flag.
Future<void> markOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(AppConstants.keyHasSeenOnboarding, true);
}

/// Call this after successful login to persist the session flag.
Future<void> markLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(AppConstants.keyIsLoggedIn, true);
}
