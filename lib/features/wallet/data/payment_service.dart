import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class PaymentResult {
  final String id;
  final String paymentStatus;
  final String? paymentURL;
  final String invoiceId;
  final double invoiceValue;

  const PaymentResult({
    required this.id,
    required this.paymentStatus,
    this.paymentURL,
    required this.invoiceId,
    required this.invoiceValue,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      id: (json['id'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'pending').toString(),
      paymentURL: (json['paymentURL'] as String?)?.isNotEmpty == true
          ? json['paymentURL'] as String
          : null,
      invoiceId: (json['invoiceId'] ?? '').toString(),
      invoiceValue:
          double.tryParse(json['invoiceValue']?.toString() ?? '0') ?? 0,
    );
  }
}

class PaymentService {
  /// Step 1 — POST /payment/initiate-session
  /// Returns sessionId + countryCode needed by MFInitiateSessionResponse.
  static Future<({String sessionId, String countryCode})> initiateSession(
    double amount,
  ) async {
    final response = await apiClient.post(
      ApiEndpoints.paymentInitiateSession,
      data: {'invoiceAmount': amount},
    );
    // After api_client unwrap: { "IsSuccess": true, "Data": { "SessionId": "...", "CountryCode": "KWD" } }
    final raw = Map<String, dynamic>.from(response.data as Map);
    final data = Map<String, dynamic>.from(raw['Data'] as Map);
    return (
      sessionId: data['SessionId'] as String,
      countryCode: (data['CountryCode'] ?? 'KWD') as String,
    );
  }

  /// Step 3 — POST /payment/execute
  static Future<PaymentResult> executePayment({
    required String sessionId,
    required double invoiceValue,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.paymentExecute,
      data: {
        'sessionId': sessionId,
        'invoiceValue': invoiceValue,
      },
    );
    return PaymentResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
