import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/availability/app_availability_controller.dart';
import 'package:beatx_flutter/core/availability/availability_banners.dart';
import 'package:beatx_flutter/core/availability/public_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Map<String, dynamic> _announcing(String version, {bool maintenance = false}) =>
    {
      'maintenanceMode': maintenance,
      'allowNewRegistrations': true,
      'announcement': {'text': 'Hello', 'updatedAt': version},
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(Get.reset);

  group('PublicSettings', () {
    test('an unknown server is treated as healthy', () {
      final settings = PublicSettings.fromJson(const {});
      expect(settings.maintenanceMode, isFalse);
      expect(settings.allowNewRegistrations, isTrue);
      expect(settings.announcement, isNull);
    });

    test('reads closed registration and maintenance', () {
      final settings = PublicSettings.fromJson(const {
        'maintenanceMode': true,
        'allowNewRegistrations': false,
        'announcement': null,
      });
      expect(settings.maintenanceMode, isTrue);
      expect(settings.allowNewRegistrations, isFalse);
    });

    test('a blank announcement is no announcement', () {
      final settings = PublicSettings.fromJson(const {
        'announcement': {'text': '  ', 'updatedAt': 'v1'},
      });
      expect(settings.announcement, isNull);
    });
  });

  group('AppAvailabilityController', () {
    AppAvailabilityController build(
      Future<Map<String, dynamic>> Function() fetch,
    ) => AppAvailabilityController(fetchSettings: fetch);

    test('a dismissed announcement stays closed until it changes', () async {
      var version = 'v1';
      final controller = build(() async => _announcing(version));
      await controller.check();
      expect(controller.visibleAnnouncement?.text, 'Hello');

      await controller.dismissAnnouncement();
      expect(controller.visibleAnnouncement, isNull);

      await controller.check();
      expect(controller.visibleAnnouncement, isNull);

      version = 'v2';
      await controller.check();
      expect(controller.visibleAnnouncement?.text, 'Hello');
    });

    test('a failed check keeps the last answer', () async {
      var fail = false;
      final controller = build(() async {
        if (fail) throw Exception('offline');
        return {'maintenanceMode': true};
      });
      await controller.check();

      fail = true;
      await controller.check();
      expect(controller.settings.value.maintenanceMode, isTrue);
    });
  });

  group('AvailabilityBanners', () {
    Future<void> pump(WidgetTester tester, Map<String, dynamic> json) async {
      final controller = AppAvailabilityController(
        fetchSettings: () async => json,
      );
      Get.put(controller);
      await tester.runAsync(controller.check);
      // Built the way main.dart builds it: above the Navigator, with no
      // Overlay in reach, which is what a tooltip would trip over.
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AvailabilityBanners(child: child!),
          home: const Scaffold(body: Text('page')),
        ),
      );
    }

    testWidgets('a healthy server shows only the page', (tester) async {
      await pump(tester, const {});
      expect(find.text('page'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      expect(find.textContaining('maintenance'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await Get.delete<AppAvailabilityController>(); // Stops its poll timer.
    });

    testWidgets('shows maintenance and an announcement that closes', (
      tester,
    ) async {
      await pump(tester, _announcing('v1', maintenance: true));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('maintenance'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(find.text('Hello'), findsNothing);
      // Maintenance cannot be closed.
      expect(find.textContaining('maintenance'), findsOneWidget);
      expect(find.text('page'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await Get.delete<AppAvailabilityController>(); // Stops its poll timer.
    });
  });
}
