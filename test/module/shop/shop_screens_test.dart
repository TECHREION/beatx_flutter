import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/notification/model/notification_model.dart';
import 'package:beatx_flutter/module/notification/services/notification_interface.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';
import 'package:beatx_flutter/module/shop/controller/cart_controller.dart';
import 'package:beatx_flutter/module/shop/presentation/screens/shop_detail_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/screens/shop_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/widgets/cart_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/widgets/checkout_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/widgets/congratulation_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/widgets/event_tickets_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/widgets/get_tickets_screen.dart';
import 'package:beatx_flutter/module/shop/presentation/widgets/my_tickets_screen.dart';
import 'package:beatx_flutter/module/shop/model/cart_model.dart';
import 'package:beatx_flutter/module/shop/services/shop_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fake_shop.dart';

/// What the shared AppHeader reads on the shop tab.
final class _FakeProfile extends ProfileInterface {
  @override
  FutureRequest<Success<UserProfileModel>> getProfile() async =>
      Right(Success(data: const UserProfileModel(name: 'Listener')));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeNotifications extends NotificationInterface {
  @override
  FutureRequest<Success<NotificationFeed>> notifications({
    int page = 1,
    int limit = 30,
  }) async => Right(Success(data: const NotificationFeed()));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GetMaterialApp(home: screen));
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ShopInterface>(FakeShop());
    Get.put<ProfileInterface>(_FakeProfile());
    Get.put<NotificationInterface>(_FakeNotifications());
    Get.put(CartController());
  });
  tearDown(Get.reset);

  testWidgets('product detail shows server data and selects a size', (
    tester,
  ) async {
    await _pump(tester, const ShopDetailScreen(productId: 'p1'));

    expect(find.text('Tour T-Shirt'), findsOneWidget);
    expect(find.text('৳29.99'), findsOneWidget);
    expect(find.text('No reviews yet'), findsOneWidget);
    expect(find.text('IN STOCK'), findsOneWidget);

    // Unselected, the label is dimmed; selecting must rebuild it.
    TextStyle? style() => tester.widget<Text>(find.text('M')).style;
    expect(style()?.color, const Color(0xFFA7A3AA));
    await tester.ensureVisible(find.text('M'));
    await tester.tap(find.text('M'));
    await tester.pump();
    expect(style()?.color, Colors.white);
  });

  testWidgets('add to cart needs a size, then adds', (tester) async {
    await _pump(tester, const ShopDetailScreen(productId: 'p1'));

    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(find.text('Please select a size'), findsOneWidget);
    expect(CartController.instance.itemCount, 0);

    await tester.ensureVisible(find.text('M'));
    await tester.tap(find.text('M'));
    await tester.pump();
    await tester.tap(find.text('Add to Cart'));
    await tester.pump();
    expect(CartController.instance.itemCount, 1);
  });

  testWidgets('checkout shows the server quote and no fake payment', (
    tester,
  ) async {
    await _pump(
      tester,
      const CheckoutScreen(
        lines: [CartLine(productId: 'p1', title: 'Tour T-Shirt', size: 'M')],
      ),
    );

    expect(find.text('৳89.99'), findsOneWidget);
    expect(find.text('৳60.00'), findsOneWidget);
    expect(find.textContaining('7 coins'), findsOneWidget);
    expect(find.text('Apple Pay'), findsNothing);
    expect(find.text('VISA'), findsNothing);
    expect(find.text('Billal'), findsNothing);
  });

  testWidgets('the event list and ticket screen render', (tester) async {
    await _pump(tester, const EventTicketsScreen());
    expect(find.text('Live in Dhaka'), findsOneWidget);
    expect(find.text('Dhaka'), findsOneWidget);
    expect(find.text('Infinite Access Pass'), findsNothing);
    await tester.pumpWidget(const SizedBox());

    await _pump(tester, GetTicketScreen(event: dhakaLive));
    expect(find.text('৳25.00 each'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.pump();
    expect(find.text('৳50.00'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
  });

  testWidgets('the cart changes quantity and empties', (tester) async {
    CartController.instance.add(
      const CartLine(productId: 'p1', title: 'Tour T-Shirt', size: 'M'),
    );
    await _pump(tester, const CartScreen());
    expect(find.text('M'), findsOneWidget);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(find.text('Your cart is empty.'), findsOneWidget);
  });

  testWidgets('the shop lists products and a chip filters and highlights', (
    tester,
  ) async {
    final shop = Get.find<ShopInterface>() as FakeShop;
    await _pump(tester, const ShopScreen());

    expect(find.text('৳29.99'), findsOneWidget);
    expect(find.text('Artist Collections'), findsNothing);
    expect(find.text('Digital Art'), findsOneWidget);

    Color? chipText() =>
        tester.widget<Text>(find.text('Digital Art')).style?.color;
    expect(chipText(), const Color(0xFFA7A3AA));

    await tester.tap(find.text('Digital Art'));
    await tester.pump();
    await tester.pump();
    expect(chipText(), const Color(0xFF0B0B0C));
    expect(shop.productCategoriesAsked.last, 'digital-art');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('my tickets shows the entry code', (tester) async {
    await _pump(tester, const MyTicketsScreen());
    expect(find.text('ABCD1234'), findsOneWidget);
  });

  testWidgets('the success dialog shows real coins and the code', (
    tester,
  ) async {
    await _pump(
      tester,
      const CongratulationScreen(
        coins: 13,
        isTicket: true,
        entryCode: 'ABCD1234',
      ),
    );
    expect(find.textContaining('13 coins'), findsOneWidget);
    expect(find.text('ABCD1234'), findsOneWidget);
    expect(find.text('View My Tickets'), findsOneWidget);
  });
}
