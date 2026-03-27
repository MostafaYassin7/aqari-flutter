import '../../../../core/constants/app_enums.dart';
import '../../../../core/utils/parse_helpers.dart';

class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? profilePhoto;
  final String? bio;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.profilePhoto,
    this.bio,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.lastActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] ?? 'GUEST',
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      lastActive: ParseHelpers.toDateTimeNullable(json['lastActive']),
      createdAt: ParseHelpers.toDateTime(json['createdAt']),
    );
  }

  bool get isOwnerOrBroker =>
      role == UserRole.owner ||
      role == UserRole.broker ||
      role == UserRole.host;
}
