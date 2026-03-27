import 'package:flutter/foundation.dart';

import 'user_model.dart';

export 'user_model.dart';

enum AuthStep {
  initial,       // Login options screen
  otpPending,    // Waiting for OTP entry
  registering,   // New user completing profile
  authenticated, // Fully logged in
}

@immutable
class AuthState {
  final AuthStep step;
  final String phoneNumber;
  final String countryCode;
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isNewUser;

  const AuthState({
    this.step = AuthStep.initial,
    this.phoneNumber = '',
    this.countryCode = '+966',
    this.isLoading = false,
    this.error,
    this.user,
    this.isNewUser = false,
  });

  const AuthState.initial()
      : step = AuthStep.initial,
        phoneNumber = '',
        countryCode = '+966',
        isLoading = false,
        error = null,
        user = null,
        isNewUser = false;

  AuthState copyWith({
    AuthStep? step,
    String? phoneNumber,
    String? countryCode,
    bool? isLoading,
    String? error,
    bool clearError = false,
    UserModel? user,
    bool? isNewUser,
  }) {
    return AuthState(
      step: step ?? this.step,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      user: user ?? this.user,
      isNewUser: isNewUser ?? this.isNewUser,
    );
  }
}
