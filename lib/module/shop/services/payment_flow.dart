import 'dart:math';

import '../../../core/api_handler/failure.dart';
import '../model/purchase_model.dart';

/// A fresh UUID v4, used as the `Idempotency-Key` of one checkout attempt.
String newIdempotencyKey([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// True when [failure] means the request may or may not have reached the
/// server, which is the one case where retrying must reuse the same key.
bool isUncertainFailure(DataCRUDFailure failure) =>
    failure.failure == Failure.timeout ||
    failure.failure == Failure.socketFailure;

/// How a gateway page's url relates to the end of the payment.
enum GatewayStep {
  /// Still paying.
  paying,

  /// The callback is loading. The server must receive it, so the page cannot
  /// be blocked or closed before the request goes out.
  callback,

  /// The server has handled the callback and redirected to the web result.
  finished,
}

GatewayStep gatewayStepOf(String url) {
  if (url.contains('/shop/payment-result')) return GatewayStep.finished;
  if (url.contains('/payments/callback/')) return GatewayStep.callback;
  return GatewayStep.paying;
}

/// How a purchase attempt ended up, for the screen to show.
class PurchaseOutcome {
  const PurchaseOutcome({
    required this.status,
    this.coinsAwarded = 0,
    this.entryCode = '',
  });

  final PurchaseStatus status;
  final int coinsAwarded;
  final String entryCode;

  factory PurchaseOutcome.of(Purchase purchase) => PurchaseOutcome(
    status: purchase.status,
    coinsAwarded: purchase.coinsAwarded,
    entryCode: purchase.entryCode,
  );
}

/// One unpaid purchase: opens its payment page and finds out what happened.
class PaymentSession {
  PaymentSession({
    required this.redirectUrl,
    required this.readPurchase,
    required this.openPage,
    Future<void> Function(Duration)? wait,
    this.attempts = 5,
    this.interval = const Duration(milliseconds: 1500),
  }) : _wait = wait ?? Future<void>.delayed;

  final String redirectUrl;

  /// Reads the purchase back; null when that request failed.
  final Future<Purchase?> Function() readPurchase;

  /// Shows the page and completes when it closes.
  final Future<void> Function(String url) openPage;
  final Future<void> Function(Duration) _wait;
  final int attempts;
  final Duration interval;

  /// Shows the payment page; completes when it closes.
  Future<void> open() => openPage(redirectUrl);

  /// Reads the result. The page can close a moment before the server settles
  /// the payment, so a pending answer is asked again a few times.
  Future<PurchaseOutcome> check() async {
    var outcome = const PurchaseOutcome(status: PurchaseStatus.pending);
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) await _wait(interval);
      final purchase = await readPurchase();
      if (purchase == null) continue;
      outcome = PurchaseOutcome.of(purchase);
      if (outcome.status != PurchaseStatus.pending) break;
    }
    return outcome;
  }
}

/// A created purchase: either [settled] already (nothing was due), or awaiting
/// payment through [session].
class PurchaseAttempt {
  const PurchaseAttempt({this.settled, this.session});

  final PurchaseOutcome? settled;
  final PaymentSession? session;
}

/// A purchase the server refused or could not be asked for, with the message
/// to show the buyer.
class PurchaseFailure implements Exception {
  const PurchaseFailure(this.message);

  final String message;

  @override
  String toString() => 'PurchaseFailure($message)';
}
