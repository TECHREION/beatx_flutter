import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/audio_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The shared player, minus the audio engine (which needs a device).
class _SilentPlayer extends PlayerController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  // ignore: must_call_super
  void onClose() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    final player = Get.put<PlayerController>(_SilentPlayer(), permanent: true);
    player.title.value = 'Aniket Prantor — a rather long song title';
    player.artist.value = 'Artcell';
  });
  tearDown(() => Get.reset());

  // Logical sizes and safe-area insets of real phones, smallest first.
  const phones = {
    'iPhone SE': (Size(375, 667), EdgeInsets.only(top: 20)),
    'iPhone 13 mini': (Size(375, 812), EdgeInsets.only(top: 50, bottom: 34)),
    'small Android': (Size(360, 640), EdgeInsets.only(top: 24)),
    'iPhone 16 Pro': (Size(402, 874), EdgeInsets.only(top: 62, bottom: 34)),
    'iPhone 16 Pro Max': (Size(440, 956), EdgeInsets.only(top: 62, bottom: 34)),
  };

  for (final MapEntry(key: name, value: (size, insets)) in phones.entries) {
    testWidgets('fits $name without scrolling', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      tester.view.padding = FakeViewPadding(
        top: insets.top * 3,
        bottom: insets.bottom * 3,
      );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const GetMaterialApp(home: PlayerScreen()));
      await tester.pump();

      // No overflow was reported, nothing scrolls, and the actions bar sits
      // inside the safe area.
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      final like = tester.getBottomLeft(find.text('LIKE'));
      expect(like.dy, lessThanOrEqualTo(size.height - insets.bottom));
      final cover = tester.getSize(
        find
            .ancestor(
              of: find.text('Artcell'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(cover.height, inInclusiveRange(140, 350));
    });
  }
}
