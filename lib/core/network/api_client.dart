import 'package:dio/dio.dart';
import 'api_failure.dart';
import '../diagnostics/safe_diagnostics.dart';
import 'auth_storage.dart';
import '../preview/ui_preview.dart';

const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.aqora.sa/api/v1',
);
final Dio apiClient = createApiClient();

Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (uiPreview) {
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'UI preview: network disabled',
              type: DioExceptionType.cancel,
            ),
          );
          return;
        }
        final token = await AuthStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final body = response.data;
        if (body is Map && body['success'] == false) {
          final failure = ApiFailure.fromBody(body);
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: failure,
              message: failure.message,
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }
        if (body is Map && body['success'] == true) {
          response.data = body['data'];
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response == null ||
            (error.response?.statusCode ?? 0) >= 500) {
          reportDiagnostic(
            error.response == null
                ? DiagnosticEvent.networkFailure
                : DiagnosticEvent.serverFailure,
            statusCode: error.response?.statusCode,
          );
        }
        if (error.response?.statusCode == 401) await AuthStorage.clearAll();
        final failure = ApiFailure.fromError(error);
        handler.reject(
          error.copyWith(error: failure, message: failure.message),
        );
      },
    ),
  );
  return dio;
}
