import 'package:beatx_flutter/module/shop/model/purchase_model.dart';
import 'package:beatx_flutter/module/shop/services/payment_flow.dart';
import 'package:flutter_test/flutter_test.dart';

ShopOrder _order(PurchaseStatus status) =>
    ShopOrder(id: 'o', status: status, coinsAwarded: 9);

void main() {
  test('idempotency keys are UUID v4 and differ', () {
    final key = newIdempotencyKey();
    expect(
      key,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newIdempotencyKey(), isNot(key));
  });

  group('gatewayStepOf', () {
    test('the gateway itself is still paying', () {
      expect(
        gatewayStepOf('https://x/api/v1/payments/dummy/abc'),
        GatewayStep.paying,
      );
    });

    test('the callback must be allowed to load', () {
      expect(
        gatewayStepOf('https://x/api/v1/payments/callback/dummy?id=1'),
        GatewayStep.callback,
      );
    });

    test('the web result page means the server is done', () {
      expect(
        gatewayStepOf(
          'https://x/beatx-frontend/shop/payment-result?kind=merch&orderId=1',
        ),
        GatewayStep.finished,
      );
    });
  });

  group('PaymentSession.check', () {
    PaymentSession session(List<ShopOrder?> answers) => PaymentSession(
      redirectUrl: 'https://pay',
      openPage: (_) async {},
      wait: (_) async {},
      readPurchase: () async => answers.removeAt(0),
    );

    test('asks again while the payment is settling', () async {
      final outcome = await session([
        _order(PurchaseStatus.pending),
        null,
        _order(PurchaseStatus.paid),
      ]).check();
      expect(outcome.status, PurchaseStatus.paid);
      expect(outcome.coinsAwarded, 9);
    });

    test('stops at a final answer', () async {
      final answers = [
        _order(PurchaseStatus.failed),
        _order(PurchaseStatus.paid),
      ];
      final outcome = await session(answers).check();
      expect(outcome.status, PurchaseStatus.failed);
      expect(answers, hasLength(1));
    });

    test('stays pending when it never settles or cannot be read', () async {
      final outcome = await session(
        List<ShopOrder?>.filled(5, null, growable: true),
      ).check();
      expect(outcome.status, PurchaseStatus.pending);
    });
  });
}
