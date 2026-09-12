import 'package:dio/dio.dart';
import '../diagnostics/safe_diagnostics.dart';

class ApiFailure implements Exception {
  final String message;
  final Map<String, String> fieldErrors;
  final int? statusCode;
  final bool mayHaveCommitted;
  const ApiFailure(
    this.message, [
    this.fieldErrors = const {},
    this.statusCode,
    this.mayHaveCommitted = false,
  ]);
  factory ApiFailure.fromBody(dynamic body) {
    final fields = <String, String>{};
    String flatten(dynamic value) =>
        value is List ? value.map(flatten).join('، ') : '$value';
    final raw = body is Map ? body['message'] : body;
    final messages = raw is List
        ? raw.map(flatten).toList()
        : raw is String
        ? [raw]
        : <String>[];
    if (body is Map) {
      final structured = body['fieldErrors'] ?? body['errors'];
      if (structured is Map) {
        for (final entry in structured.entries) {
          fields['${entry.key}'] = flatten(entry.value);
        }
      }
    }
    // Nest's deployed filter joins class-validator messages with commas.
    for (final message in messages.expand(
      (m) => m.split(RegExp(r',\s+(?=[a-zA-Z]\w*\s)')),
    )) {
      final match = RegExp(
        r'^([a-zA-Z]\w*)(?:\.\w+)?\s+(?:must|should|is|required|cannot)\b',
      ).firstMatch(message);
      if (match != null) fields.putIfAbsent(match[1]!, () => message);
    }
    return ApiFailure(
      messages.isEmpty ? 'تعذر إكمال الطلب. حاول مجدداً.' : messages.join('، '),
      fields,
    );
  }
  factory ApiFailure.fromError(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final status = error.response?.statusCode;
      final uncertain = error.response == null || (status ?? 0) >= 500;
      if (status == 401 || status == 403 || (status ?? 0) >= 500) {
        return ApiFailure(
          status == 401
              ? 'انتهت الجلسة. سجّل الدخول مجدداً.'
              : status == 403
              ? 'ليس لديك صلاحية لإكمال هذا الطلب.'
              : 'تعذر إكمال الطلب لدى الخادم. حاول مجدداً.',
          {},
          status,
          uncertain,
        );
      }
      final failure = error.error is ApiFailure
          ? error.error as ApiFailure
          : error.response == null
          ? const ApiFailure('تعذر الاتصال. تحقق من الشبكة وحاول مجدداً.')
          : ApiFailure.fromBody(error.response?.data);
      return ApiFailure(
        failure.message,
        failure.fieldErrors,
        error.response?.statusCode ?? failure.statusCode,
        uncertain || failure.mayHaveCommitted,
      );
    }
    reportDiagnostic(DiagnosticEvent.parsingFailure);
    return const ApiFailure('تعذر إكمال الطلب. حاول مجدداً.');
  }
  @override
  String toString() => message;
}
