import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../domain/wallet.dart';

final walletRepositoryProvider = Provider((ref) => WalletRepository(apiClient));

class WalletRepository {
  final Dio dio;
  WalletRepository(this.dio);
  Future<({double balance, double held, double pending, String currency})>
  summary() async {
    final response = await dio.get('/wallet');
    final data = response.data;
    if (data is! Map) throw const ApiFailure('تعذر قراءة المحفظة.');
    double amount(String key) {
      final v = double.tryParse('${data[key] ?? 0}');
      if (v == null || !v.isFinite) {
        throw const ApiFailure('تعذر قراءة الرصيد.');
      }
      return v;
    }

    return (
      balance: amount('balance'),
      held: amount('heldBalance'),
      pending: amount('pendingEarnings'),
      currency: '${data['currency'] ?? 'SAR'}',
    );
  }

  Future<({List<WalletTransaction> items, bool hasMore})> transactions({
    int page = 1,
    TransactionFilter purpose = TransactionFilter.all,
    String direction = 'all',
  }) async {
    final response = await dio.get(
      '/wallet/transactions',
      queryParameters: walletTransactionQuery(
        page: page,
        purpose: purpose,
        direction: direction,
      ),
    );
    final data = response.data;
    if (data is! Map || data['data'] is! List) {
      throw const ApiFailure('تعذر قراءة سجل المعاملات.');
    }
    final rows = data['data'] as List;
    final total = int.tryParse('${data['total']}');
    return (
      items: rows
          .map((v) => WalletTransaction.fromJson(Map<String, dynamic>.from(v)))
          .toList(),
      hasMore: total == null ? rows.length >= 20 : page * 20 < total,
    );
  }
}
