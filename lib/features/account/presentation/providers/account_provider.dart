import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── User profile model ────────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final String? bio;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastActive;
  final double? walletBalance;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.photoUrl,
    this.bio,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    this.lastActive,
    this.walletBalance,
  });

  bool get hasEmail => email != null && email!.trim().isNotEmpty;
  bool get hasBio => bio != null && bio!.trim().isNotEmpty;

  String get roleLabel {
    switch (role) {
      case UserRole.owner:
        return 'مالك';
      case UserRole.broker:
        return 'وسيط';
      case UserRole.host:
        return 'مضيف';
      default:
        return 'مستخدم';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Returns the logged-in user's profile, or null if not authenticated.
final userProfileProvider = Provider<UserProfile?>((ref) {
  final user = ref.watch(authProvider.select((state) => state.user));
  if (user == null) {
    return null;
  }

  final name = user.name?.trim();
  final email = user.email?.trim();
  final bio = user.bio?.trim();

  return UserProfile(
    id: user.id,
    name: (name == null || name.isEmpty) ? 'مستخدم عقار' : name,
    phone: user.phone,
    email: (email == null || email.isEmpty) ? null : email,
    photoUrl: user.profilePhoto,
    bio: (bio == null || bio.isEmpty) ? null : bio,
    role: user.role,
    isVerified: user.isVerified,
    isActive: user.isActive,
    createdAt: user.createdAt,
    lastActive: user.lastActive,
  );
});
