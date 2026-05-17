import 'dart:convert';

import 'package:dio/dio.dart';

import 'auth_storage.dart';

const String kBaseUrl = 'https://api.aqora.sa/api/v1';

final Dio apiClient = _createDio();

Dio _createDio() {
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
        final token = await AuthStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },

      onResponse: (response, handler) {
        final body = response.data;
        if (body is Map) {
          final Map<String, dynamic> bodyMap = Map<String, dynamic>.from(
            body as Map,
          );
          if (bodyMap['success'] == true) {
            final data = bodyMap['data'];
            response.data = jsonDecode(jsonEncode(data));
            handler.next(response);
          } else {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                message:
                    bodyMap['message'] as String? ?? 'Something went wrong',
                type: DioExceptionType.badResponse,
              ),
            );
          }
        } else {
          handler.next(response);
        }
      },

      onError: (error, handler) async {
        final response = error.response;
        String message = 'Something went wrong. Please try again.';

        if (response != null) {
          final body = response.data;
          if (body is Map) {
            final m = Map<String, dynamic>.from(body as Map);
            message = m['message'] as String? ?? message;
          }
          switch (response.statusCode) {
            case 401:
              await AuthStorage.clearAll();
              message = 'Session expired. Please login again.';
            case 403:
              message = 'You do not have permission to do this.';
            case 404:
              message = 'Not found.';
            case 429:
              message = 'Too many requests. Please wait a moment.';
            case 500:
              message = 'Server error. Please try again later.';
            default:
              break;
          }
        } else {
          message = 'No internet connection. Please check your network.';
        }

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            message: message,
            type: error.type,
          ),
        );
      },
    ),
  );

  return dio;
}
