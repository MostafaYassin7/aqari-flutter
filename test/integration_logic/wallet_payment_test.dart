import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqar_app/core/network/api_failure.dart';
import 'package:aqar_app/features/wallet/data/wallet_repository.dart';
import 'package:aqar_app/features/wallet/data/payment_repository.dart';
import 'package:aqar_app/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:aqar_app/features/wallet/presentation/screens/payment_card_frame.dart';
import 'listing_api_test.dart' show RecordingAdapter;

Map<String, dynamic> transaction({
  String direction = 'debit',
  Object? amount = '12.50',
}) => {
  'id': direction,
  'type': direction,
  'referenceType': 'booking',
  'amount': amount,
  'createdAt': '2026-09-10T12:00:00Z',
};

typedef Page = ({List<WalletTransaction> items, bool hasMore});

class ControlledWallet extends WalletRepository {
  ControlledWallet() : super(Dio());
  final requests =
      <
        ({
          String direction,
          TransactionFilter purpose,
          int page,
          Completer<Page> result,
        })
      >[];
  @override
  Future<({double balance, double held, double pending, String currency})>
  summary() async =>
      (balance: 100.0, held: 20.0, pending: 30.0, currency: 'SAR');
  @override
  Future<Page> transactions({
    int page = 1,
    TransactionFilter purpose = TransactionFilter.all,
    String direction = 'all',
  }) {
    final result = Completer<Page>();
    requests.add((
      direction: direction,
      purpose: purpose,
      page: page,
      result: result,
    ));
    return result.future;
  }
}

void main() {
  test(
    'direction is independent from booking purpose; unknown direction stays neutral',
    () {
      final debit = WalletTransaction.fromJson(transaction());
      final credit = WalletTransaction.fromJson(
        transaction(direction: 'credit'),
      );
      final unknown = WalletTransaction.fromJson(
        transaction(direction: 'future_type'),
      );
      expect(debit.signedAmount, -12.5);
      expect(credit.signedAmount, 12.5);
      expect(unknown.isCredit || unknown.isDebit, false);
      expect(credit.type, TransactionType.booking);
      expect(
        walletTransactionQuery(
          direction: 'credit',
          purpose: TransactionFilter.bookings,
        ),
        {'page': 1, 'limit': 20, 'type': 'credit', 'referenceType': 'booking'},
      );
    },
  );
  test(
    'malformed financial amounts and dates are rejected rather than shown as zero or today',
    () {
      for (final value in [null, 'bad', 'NaN', 'Infinity']) {
        expect(
          () => WalletTransaction.fromJson(transaction(amount: value)),
          throwsFormatException,
        );
      }
      expect(
        () =>
            WalletTransaction.fromJson({...transaction(), 'createdAt': 'bad'}),
        throwsFormatException,
      );
    },
  );
  test(
    'older wallet response cannot overwrite a newer direction filter',
    () async {
      final repo = ControlledWallet();
      final c = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      final notifier = c.read(walletProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(repo.requests.length, 1);
      notifier.setDirection('credit');
      repo.requests[1].result.complete((
        items: [WalletTransaction.fromJson(transaction(direction: 'credit'))],
        hasMore: false,
      ));
      await Future<void>.delayed(Duration.zero);
      repo.requests[0].result.complete((
        items: [WalletTransaction.fromJson(transaction())],
        hasMore: true,
      ));
      await Future<void>.delayed(Duration.zero);
      final state = c.read(walletProvider);
      expect(state.direction, 'credit');
      expect(state.transactions.single.isCredit, true);
      expect(state.hasMore, false);
      expect(
        state.balance,
        100,
      ); // Held funds are not subtracted a second time.
      expect(state.heldBalance, 20);
      expect(state.pendingEarnings, 30);
    },
  );
  test(
    'gateway contract uses tokenized session, amount, and verified redirect only',
    () async {
      final adapter = RecordingAdapter()
        ..body = {
          'IsSuccess': true,
          'Data': {'SessionId': 'gateway-session', 'CountryCode': 'SAR'},
        };
      final repo = PaymentRepository(Dio()..httpClientAdapter = adapter);
      final session = await repo.initiate(100);
      expect(adapter.request.path, '/payment/initiate-session');
      expect(adapter.request.data, {'invoiceAmount': 100.0});
      expect(session.cardOrigin, 'https://sa.myfatoorah.com');
      adapter.body = {
        'id': 'payment',
        'paymentURL': 'https://sa.myfatoorah.com/verify',
      };
      expect(
        (await repo.execute('tokenized-session', 100))!.host,
        'sa.myfatoorah.com',
      );
      expect(adapter.request.data, {
        'sessionId': 'tokenized-session',
        'invoiceValue': 100.0,
      });
      adapter.body = {
        'id': 'payment',
        'paymentURL': 'https://myfatoorah.com.attacker.example/verify',
      };
      await expectLater(
        repo.execute('tokenized-session', 100),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.mayHaveCommitted,
            'uncertain write',
            true,
          ),
        ),
      );
    },
  );
  test(
    'card HTML escapes remote session values and accepts gateway messages only',
    () {
      final html = paymentCardHtml(
        const PaymentSession("id'</script>&", 'SAR'),
      );
      expect(html, isNot(contains("id'</script>&")));
      expect(html, contains(r'\u0027'));
      expect(html, contains("origin.protocol!=='https:'"));
      expect(html, isNot(contains('Authorization')));
    },
  );
}
