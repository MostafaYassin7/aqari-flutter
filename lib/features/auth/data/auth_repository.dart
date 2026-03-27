import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/parse_helpers.dart';
import '../domain/models/user_model.dart';

class AuthRepository {
  final _dio = apiClient;

  Future<String> sendOtp(String phone) async {
    final res = await _dio.post(
      ApiEndpoints.sendOtp,
      data: {'phone': phone},
    );
    final data = res.data as Map<String, dynamic>?;
    // Dev mode: backend returns the code in the response
    return data?['code'] as String? ?? '';
  }

  Future<({String token, bool isNewUser, UserModel? user})> verifyOtp(
    String phone,
    String code,
  ) async {
    final res = await _dio.post(
      ApiEndpoints.verifyOtp,
      data: {'phone': phone, 'code': code},
    );
    final data = res.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      isNewUser: data['isNewUser'] as bool? ?? false,
      user: data['user'] != null
          ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Future<({String token, UserModel user})> completeProfile({
    required String name,
    String? email,
    required String role,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.completeProfile,
      data: ParseHelpers.buildBody({
        'name': name,
        'role': role,
        'email': email,
      }),
    );
    final data = res.data as Map<String, dynamic>;
    return (
      token: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }
}
