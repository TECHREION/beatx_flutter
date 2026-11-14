import 'package:beatx_flutter/core/player/equalizer/equalizer_controller.dart';
import 'package:beatx_flutter/core/player/equalizer/equalizer_service_ios.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.beatx/equalizer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  var processing = true;
  var itemHasAudioTrack = true;

  setUp(() {
    processing = true;
    itemHasAudioTrack = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'getConfiguration') return null;
      return <String, dynamic>{
        'frequencies': <double>[
          31,
          62,
          125,
          250,
          500,
          1000,
          2000,
          4000,
          8000,
          16000,
        ],
        'minDecibels': -12.0,
        'maxDecibels': 12.0,
        'gains': List<double>.filled(10, 0),
        'enabled': false,
        'processing': processing,
        'hasSeenItem': true,
        'itemHasAudioTrack': itemHasAudioTrack,
      };
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  test('availability follows the track, in both directions', () async {
    final controller = EqualizerController(
      service: IosEqualizerService(),
      store: FakeEqualizerStore(),
    )..onInit();
    addTearDown(controller.onClose);

    // A downloaded song: the tap is running.
    await wait(1200);
    expect(controller.isReady.value, isTrue);
    expect(controller.unavailableReason.value, EqualizerUnavailableReason.none);

    // The next track is HLS. The sliders must not stay up over it.
    processing = false;
    itemHasAudioTrack = false;
    await wait(2200);
    expect(controller.isReady.value, isFalse);
    expect(
      controller.unavailableReason.value,
      EqualizerUnavailableReason.incompatibleStream,
    );

    // And back to a downloaded song.
    processing = true;
    itemHasAudioTrack = true;
    await wait(2200);
    expect(controller.isReady.value, isTrue);
    expect(controller.unavailableReason.value, EqualizerUnavailableReason.none);
  });
}
