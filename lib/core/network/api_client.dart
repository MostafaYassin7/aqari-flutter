import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'auth_storage.dart';

const String kBaseUrl = 'http://136.111.230.89:3000/api/v1';

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
      // 1. Attach JWT token to every request
      onRequest: (options, handler) async {
        final token = await AuthStorage.getToken();
        log('=== INTERCEPTOR token: $token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },

      // 2. Unwrap { success, data, message } envelope
      onResponse: (response, handler) {
        final body = response.data;
        print('=== INTERCEPTOR body.runtimeType: ${body.runtimeType}');
        print('=== INTERCEPTOR body is Map: ${body is Map}');
        print(
          '=== INTERCEPTOR body is Map<String,dynamic>: ${body is Map<String, dynamic>}',
        );
        if (body is Map) {
          final Map<String, dynamic> bodyMap = Map<String, dynamic>.from(
            body as Map,
          );
          print('=== INTERCEPTOR keys: ${bodyMap.keys.toList()}');
          print('=== INTERCEPTOR success: ${bodyMap['success']}');
          if (bodyMap['success'] == true) {
            final data = bodyMap['data'];
            print('=== INTERCEPTOR data.runtimeType: ${data.runtimeType}');
            if (data is Map) {
              print(
                '=== INTERCEPTOR data keys: ${Map<String, dynamic>.from(data as Map).keys.toList()}',
              );
            }
            response.data = jsonDecode(jsonEncode(data));
            print('=== INTERCEPTOR after decode: ${response.data.runtimeType}');
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
          print('=== INTERCEPTOR not a Map, passing through');
          handler.next(response);
        }
      },

      // 3. Map errors to user-friendly messages
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

  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      compact: true,
    ),
  );

  return dio;
}
