import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/module/shop/controller/cart_controller.dart';
import 'package:beatx_flutter/module/shop/controller/checkout_controller.dart';
import 'package:beatx_flutter/module/shop/controller/get_ticket_controller.dart';
import 'package:beatx_flutter/module/shop/controller/shop_detail_controller.dart';
import 'package:beatx_flutter/module/shop/model/cart_model.dart';
import 'package:beatx_flutter/module/shop/model/event_model.dart';
import 'package:beatx_flutter/module/shop/model/purchase_model.dart';
import 'package:beatx_flutter/module/shop/services/payment_flow.dart';
import 'package:beatx_flutter/module/shop/services/shop_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fake_shop.dart';

const _line = CartLine(productId: 'p1', title: 'Tour T-Shirt', size: 'M');

Right<Never, Success<CreatedPurchase<ShopOrder>>> _awaitingPayment() => Right(
  Success(
    data: const CreatedPurchase(
      purchase: ShopOrder(id: 'o1', status: PurchaseStatus.pending),
      payment: PaymentInfo(redirectUrl: 'https://pay/o1'),
    ),
  ),
);

void main() {
  late FakeShop shop;

  setUp(() {
    Get.testMode = true;
    shop = FakeShop();
    Get.put<ShopInterface>(shop);
    Get.put(CartController());
  });
  tearDown(Get.reset);

  group('CartController', () {
    test('the same item adds up; another size is another line', () {
      final cart = CartController.instance;
      cart.add(_line);
      cart.add(_line);
      cart.add(
        const CartLine(productId: 'p1', title: 'Tour T-Shirt', size: 'L'),
      );
      expect(cart.lines, hasLength(2));
      expect(cart.itemCount, 3);
    });

    test('a quantity of zero removes the line', () {
      final cart = CartController.instance;
      cart.add(_line);
      cart.setQuantity(_line, 0);
      expect(cart.lines, isEmpty);
    });
  });

  group('ShopDetailController', () {
    Future<ShopDetailController> loaded() async {
      final controller = ShopDetailController('p1');
      await controller.load();
      return controller;
    }

    test('requires a size, as the API does', () async {
      final controller = await loaded();
      expect(controller.selectionProblem, 'Please select a size');

      controller.selectSize(controller.product.value!.sizes.last);
      expect(controller.selectionProblem, isNull);
      expect(controller.toLine().size, 'M');
    });

    test('preselects a colour in stock and refuses one that is not', () async {
      final controller = await loaded();
      final colors = controller.product.value!.colors;
      expect(controller.selectedColor.value?.name, 'Black');

      controller.selectColor(colors.last);
      expect(controller.selectedColor.value?.name, 'Black');
    });
  });

  group('CheckoutController', () {
    late List<String> opened;

    CheckoutController build({bool fromCart = false}) {
      opened = [];
      final controller = CheckoutController(
        lines: const [_line],
        fromCart: fromCart,
        openPaymentPage: (url) async => opened.add(url),
      );
      controller.firstNameController.text = 'Ayesha';
      controller.lastNameController.text = 'Rahman';
      controller.addressController.text = 'Road 1';
      controller.cityController.text = 'Dhaka';
      controller.postalCodeController.text = '1000';
      return controller;
    }

    test('a blank field stops the order before the API', () async {
      final controller = build()..cityController.text = '  ';
      await expectLater(
        controller.confirm(),
        throwsA(
          isA<PurchaseFailure>().having(
            (failure) => failure.message,
            'message',
            contains('city'),
          ),
        ),
      );
      expect(shop.orderKeys, isEmpty);
    });

    test('a timeout retries with the same key', () async {
      final controller = build();
      shop.createAnswers.addAll([timedOut(), _awaitingPayment()]);

      await expectLater(controller.confirm(), throwsA(isA<PurchaseFailure>()));
      await controller.confirm();

      expect(shop.orderKeys, hasLength(2));
      expect(shop.orderKeys.first, shop.orderKeys.last);
    });

    test('a refusal retries with a new key', () async {
      final controller = build();
      shop.createAnswers.addAll([
        serverError('Insufficient stock'),
        _awaitingPayment(),
      ]);

      await expectLater(
        controller.confirm(),
        throwsA(
          isA<PurchaseFailure>().having(
            (failure) => failure.message,
            'message',
            'Insufficient stock',
          ),
        ),
      );
      await controller.confirm();

      expect(shop.orderKeys.first, isNot(shop.orderKeys.last));
    });

    test('confirming again goes back to the unpaid order', () async {
      final controller = build();
      shop.createAnswers.add(_awaitingPayment());

      final first = await controller.confirm();
      final second = await controller.confirm();

      expect(second.session, same(first.session));
      expect(shop.orderKeys, hasLength(1));
    });

    test('editing the address makes a new order, with a new key', () async {
      final controller = build();
      shop.createAnswers.addAll([_awaitingPayment(), _awaitingPayment()]);

      await controller.confirm();
      controller.addressController.text = 'Road 2';
      await controller.confirm();

      expect(shop.orderKeys, hasLength(2));
      expect(shop.orderKeys.first, isNot(shop.orderKeys.last));
    });

    test('the session opens the gateway and reads the server result', () async {
      final controller = build();
      shop.createAnswers.add(_awaitingPayment());

      final attempt = await controller.confirm();
      await attempt.session!.open();
      final outcome = await attempt.session!.check();

      expect(opened, ['https://pay/o1']);
      expect(outcome.status, PurchaseStatus.paid);
      expect(outcome.coinsAwarded, 7);
    });

    test('a free order settles at once without a payment page', () async {
      final controller = build();
      shop.createAnswers.add(
        Right(
          Success(
            data: const CreatedPurchase(
              purchase: ShopOrder(id: 'o1', status: PurchaseStatus.paid),
            ),
          ),
        ),
      );

      final attempt = await controller.confirm();

      expect(attempt.session, isNull);
      expect(attempt.settled?.status, PurchaseStatus.paid);
    });

    test('only a paid cart order empties the cart', () {
      final cart = CartController.instance..add(_line);
      final fromCart = build(fromCart: true);
      fromCart.settle(const PurchaseOutcome(status: PurchaseStatus.failed));
      expect(cart.lines, hasLength(1));

      build().settle(const PurchaseOutcome(status: PurchaseStatus.paid));
      expect(cart.lines, hasLength(1));

      fromCart.settle(const PurchaseOutcome(status: PurchaseStatus.paid));
      expect(cart.lines, isEmpty);
    });
  });

  group('GetTicketController', () {
    Future<GetTicketController> loaded() async {
      final controller = GetTicketController(
        dhakaLive,
        openPaymentPage: (_) async {},
      )..onInit();
      await pumpEventQueue();
      return controller;
    }

    Right<Never, Success<CreatedPurchase<TicketOrder>>> awaiting() => Right(
      Success(
        data: const CreatedPurchase(
          purchase: TicketOrder(id: 'k1', status: PurchaseStatus.pending),
          payment: PaymentInfo(redirectUrl: 'https://pay/k1'),
        ),
      ),
    );

    test('quotes the first available tier, then each change', () async {
      final controller = await loaded();
      expect(controller.quote.value?.totalDisplay, '৳25.00');

      controller.increment();
      await pumpEventQueue();
      expect(controller.quote.value?.totalDisplay, '৳50.00');
      expect(shop.ticketQuotes.last, 't1:2');
    });

    test('quantity stops at ten, and at what the tier has left', () async {
      final controller = await loaded();
      for (var i = 0; i < 20; i++) {
        controller.increment();
      }
      expect(controller.quantity.value, GetTicketController.maxPerOrder);

      controller.selectTier(controller.event.value.tiers.last);
      await pumpEventQueue();
      expect(controller.quantity.value, 3);
      expect(shop.ticketQuotes.last, 't2:3');
    });

    test('changing the quantity starts a new booking', () async {
      final controller = await loaded();
      shop.buyAnswers.addAll([awaiting(), awaiting()]);

      final first = await controller.buy();
      controller.increment();
      await pumpEventQueue();
      final second = await controller.buy();

      expect(second.session, isNot(same(first.session)));
      expect(shop.ticketKeys.first, isNot(shop.ticketKeys.last));
    });

    test('an unchanged selection returns to the unpaid booking', () async {
      final controller = await loaded();
      shop.buyAnswers.add(awaiting());

      final first = await controller.buy();
      final second = await controller.buy();

      expect(second.session, same(first.session));
      expect(shop.ticketKeys, hasLength(1));
    });

    test('a paid ticket reports its entry code', () async {
      final controller = await loaded();
      shop.buyAnswers.add(awaiting());

      final attempt = await controller.buy();
      final outcome = await attempt.session!.check();

      expect(outcome.entryCode, 'ABCD1234');
    });

    test('a sold-out event cannot be bought', () async {
      final soldOut = ShopEvent.fromJson(const {
        '_id': 'e',
        'ticketTiers': [
          {'_id': 't', 'name': 'General', 'remaining': 0},
        ],
      });
      expect(soldOut.tiers.single.isSoldOut, isTrue);
    });
  });
}
