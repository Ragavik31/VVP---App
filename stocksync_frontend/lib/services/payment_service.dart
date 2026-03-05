import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  late Razorpay _razorpay;
  Completer<bool>? _paymentCompleter;

  Future<bool> pay(double amount) async {
    _paymentCompleter = Completer<bool>();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    var options = {
      'key': 'rzp_test_RP2Idj9ADIERN7',   
      'amount': (amount * 100).toInt(), 
      'name': 'StockSync',
      'description': 'Vaccine Order Payment',
      'timeout': 120,
      'prefill': {
        'contact': '9876543210',
        'email': 'client@email.com'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _paymentCompleter?.complete(false);
    }

    return _paymentCompleter!.future;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _paymentCompleter?.complete(true);
    _dispose();
  }

  void _handleError(PaymentFailureResponse response) {
    _paymentCompleter?.complete(false);
    _dispose();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _dispose() {
    _razorpay.clear();
  }
}
