import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/network/auth_storage.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_state.dart';

export '../../domain/models/auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  final _repo = AuthRepository();

  @override
  AuthState build() => const AuthState.initial();

  Future<void> sendOtp({
    required String phone,
    required String countryCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Combine country code + number for backend
      await _repo.sendOtp('$countryCode$phone');
      state = state.copyWith(
        isLoading: false,
        step: AuthStep.otpPending,
        phoneNumber: phone,
        countryCode: countryCode,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  /// Returns true on success (use state.isNewUser to decide where to navigate).
  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final fullPhone = '${state.countryCode}${state.phoneNumber}';
      final result = await _repo.verifyOtp(fullPhone, otp);

      await AuthStorage.saveToken(result.token);
      SocketService().connectAll(result.token);

      state = state.copyWith(
        isLoading: false,
        isNewUser: result.isNewUser,
        user: result.user,
        step: result.isNewUser ? AuthStep.registering : AuthStep.authenticated,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Called by RegisterScreen — maps isOwner bool to correct UserRole enum.
  Future<void> completeRegistration({
    required String name,
    String? email,
    required bool isOwner,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final role = isOwner ? UserRole.owner : UserRole.user;
      final result = await _repo.completeProfile(
        name: name,
        email: email,
        role: role,
      );
      await AuthStorage.saveToken(result.token);
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        step: AuthStep.authenticated,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<void> logout() async {
    SocketService().disconnectAll();
    await AuthStorage.clearAll();
    state = const AuthState.initial();
  }

  // Stub — social sign-in not yet supported by backend
  Future<void> socialSignIn() async {}

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const AuthState.initial();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
