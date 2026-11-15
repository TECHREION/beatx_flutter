import 'package:beatx_flutter/core/common/widget/mini_player_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _playerKey = Key('mini-player');

Widget _app(Widget home) => GetMaterialApp(
  navigatorObservers: [MiniPlayerHost.observer],
  builder: (context, child) => MiniPlayerOverlay(
    player: const SizedBox(key: _playerKey, height: 60),
    child: child!,
  ),
  home: home,
);

bool _playerVisible(WidgetTester tester) =>
    tester.widget<Visibility>(find.byType(Visibility).first).visible;

double _playerBottom(WidgetTester tester) =>
    tester.widget<Positioned>(find.byType(Positioned).last).bottom!;

void main() {
  setUp(() => Get.testMode = true);

  testWidgets('shown on ordinary screens, at the bottom', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
    await tester.pumpAndSettle();
    expect(_playerVisible(tester), isTrue);
    expect(_playerBottom(tester), 0);
  });

  testWidgets('sits above a bottom bar and follows pushes and pops', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: Text('tabs'),
          bottomNavigationBar: MiniPlayerAnchor(
            child: SizedBox(height: 80, child: Text('nav')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_playerBottom(tester), 80);

    Get.to(() => const Scaffold(body: Text('details')));
    await tester.pumpAndSettle();
    expect(_playerBottom(tester), 0);
    expect(_playerVisible(tester), isTrue);

    Get.back();
    await tester.pumpAndSettle();
    expect(_playerBottom(tester), 80);
  });

  testWidgets('hidden on opted-out screens and while a dialog is open', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const Scaffold(body: Text('home'))));
    await tester.pumpAndSettle();

    Get.to(
      () => const MiniPlayerHidden(child: Scaffold(body: Text('full player'))),
    );
    await tester.pumpAndSettle();
    expect(_playerVisible(tester), isFalse);

    Get.back();
    await tester.pumpAndSettle();
    expect(_playerVisible(tester), isTrue);

    Get.dialog(const AlertDialog(content: Text('hi')));
    await tester.pumpAndSettle();
    expect(_playerVisible(tester), isFalse);

    Get.back();
    await tester.pumpAndSettle();
    expect(_playerVisible(tester), isTrue);
  });
}
