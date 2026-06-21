import 'dart:async';

class PaymentEventService {
  static final _controller = StreamController<void>.broadcast();

  static Stream<void> get onPaymentConfirmed => _controller.stream;

  static void notifyPaymentConfirmed() => _controller.add(null);
}
