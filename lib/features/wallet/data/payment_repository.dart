import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';

final paymentRepositoryProvider = Provider(
  (ref) => PaymentRepository(apiClient),
);

class PaymentSession {
  final String id, country;
  const PaymentSession(this.id, this.country);
  String get cardOrigin => country == 'SAR'
      ? 'https://sa.myfatoorah.com'
      : 'https://demo.myfatoorah.com';
}

class PaymentRepository {
  final Dio dio;
  PaymentRepository(this.dio);
  Future<PaymentSession> initiate(double amount) async {
    if (!amount.isFinite || amount < 100) {
      throw const ApiFailure('الحد الأدنى 100 ريال');
    }
    final response = await dio.post(
      '/payment/initiate-session',
      data: {'invoiceAmount': amount},
    );
    final body = response.data;
    if (body is! Map ||
        body['IsSuccess'] != true ||
        body['Data'] is! Map ||
        body['Data']['SessionId'] is! String) {
      throw const ApiFailure('تعذر بدء جلسة الدفع. حاول مجدداً.');
    }
    return PaymentSession(
      body['Data']['SessionId'],
      body['Data']['CountryCode'] ?? 'KWT',
    );
  }

  Future<Uri?> execute(String sessionId, double amount) async {
    final response = await dio.post(
      '/payment/execute',
      data: {'sessionId': sessionId, 'invoiceValue': amount},
    );
    final data = response.data;
    if (data is! Map || data['id'] is! String) {
      throw const ApiFailure(
        'تعذر تأكيد نتيجة الدفع. تحقق من المحفظة قبل إعادة الدفع.',
        {},
        null,
        true,
      );
    }
    if (data['paymentURL'] == null) return null;
    final url = Uri.tryParse('${data['paymentURL']}');
    if (url == null ||
        url.scheme != 'https' ||
        !(url.host == 'myfatoorah.com' ||
            url.host.endsWith('.myfatoorah.com'))) {
      throw const ApiFailure(
        'تعذر فتح صفحة التحقق من الدفع. تحقق من المحفظة.',
        {},
        null,
        true,
      );
    }
    return url;
  }
}
