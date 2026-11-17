import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/common/widget/app_header.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/core/theme/app_sizes.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _FakeProfile extends ProfileInterface {
  @override
  FutureRequest<Success<UserProfileModel>> getProfile() async =>
      Right(Success(data: const UserProfileModel(name: 'Listener')));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ProfileInterface>(_FakeProfile());
  });
  tearDown(Get.reset);

  for (final width in [320.0, 360.0, 430.0]) {
    testWidgets('title, search field and bell fit at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var opened = 0;
      for (final (title, hint) in [
        ('Watch', 'Search videos'),
        ('Podcasts', 'Search podcasts'),
        ('Audiobook', 'Search audiobooks'),
        ('Shop', 'Search products'),
      ]) {
        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: AppHeader(
                title: title,
                searchHint: hint,
                notificationBadge: '3',
                onSearchTap: () => opened++,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text(title), findsOneWidget);
        expect(find.text(hint), findsOneWidget);
        // The field sits between the title and the bell.
        final titleRight = tester.getTopRight(find.text(title)).dx;
        final fieldLeft = tester
            .getTopLeft(find.byIcon(Icons.search_rounded))
            .dx;
        final bellLeft = tester
            .getTopLeft(find.byIcon(Icons.notifications_rounded))
            .dx;
        expect(fieldLeft, greaterThan(titleRight));
        expect(bellLeft, greaterThan(fieldLeft));

        await tester.tap(find.text(hint));
      }
      expect(opened, 4);
    });
  }

  testWidgets('a titled header puts its buttons at the right edge, like '
      'the logo header', (tester) async {
    tester.view.physicalSize = const Size(390, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final title in ['Watch', 'Podcasts', 'Audiobook', 'Shop', null]) {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: AppHeader(
              title: title,
              showLogo: title == null,
              notificationBadge: '3',
              onSearchTap: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final bell = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.notifications_rounded),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(bell.right, closeTo(390 - AppSizes.screenHorizontalPadding, 0.5));
    }
  });

  testWidgets('a trailing button (the Shop\'s cart) replaces the bell', (
    tester,
  ) async {
    var openedCart = 0;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: AppHeader(
            title: 'Shop',
            onSearchTap: () {},
            trailing: AppHeaderActionButton(
              icon: Icons.shopping_cart_outlined,
              badge: '12',
              onTap: () => openedCart++,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.notifications_rounded), findsNothing);
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    expect(openedCart, 1);
  });
}
