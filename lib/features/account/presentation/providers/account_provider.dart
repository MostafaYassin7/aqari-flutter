import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

// ── User profile model ────────────────────────────────────────────────────────

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String userNumber; // 9-digit display number
  final String photoUrl;
  final bool isBroker;
  final String? establishmentName;
  final String? establishmentLogoUrl;
  final double rating;
  final int reviewCount;
  final double walletBalance;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.userNumber,
    required this.photoUrl,
    required this.isBroker,
    this.establishmentName,
    this.establishmentLogoUrl,
    required this.rating,
    required this.reviewCount,
    required this.walletBalance,
  });
}

// ── Mock user ─────────────────────────────────────────────────────────────────

const _mockUser = UserProfile(
  id: 'usr_001',
  name: 'محمد العتيبي',
  phone: '+966 50 123 4567',
  userNumber: '100234567',
  photoUrl: 'https://picsum.photos/seed/user001/200/200',
  isBroker: true,
  establishmentName: 'مكتب العتيبي للعقارات',
  establishmentLogoUrl: 'https://picsum.photos/seed/logo001/200/200',
  rating: 4.8,
  reviewCount: 47,
  walletBalance: 1250.0,
);

// ── Provider ──────────────────────────────────────────────────────────────────

/// Returns the logged-in user's profile, or null if not authenticated.
final userProfileProvider = Provider<UserProfile?>((ref) {
  final auth = ref.watch(authProvider);
  if (auth.step == AuthStep.authenticated) return _mockUser;
  return null;
});
