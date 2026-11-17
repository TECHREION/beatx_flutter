import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/core/player/progress_store.dart';
import 'package:beatx_flutter/core/player/progress_tracker.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerController player;
  late List<(String, int, bool)> sent;
  late ProgressTracker tracker;

  Future<bool> saver(String id, int positionMs, bool completed) async {
    sent.add((id, positionMs, completed));
    return true;
  }

  /// What `play` does to the player's state, without the audio.
  void startTrack(String id) {
    player.playCount.value++;
    player.trackId.value = id;
    player.position.value = Duration.zero;
    player.duration.value = Duration.zero;
    player.isPlaying.value = true;
  }

  setUp(() async {
    Get.testMode = true;
    await ProgressStore.clear();
    player = Get.put<PlayerController>(_SilentPlayer(), permanent: true);
    sent = [];
    tracker = ProgressTracker();
  });
  tearDown(() => Get.reset());

  test('a pause saves the position at once, on the device too', () async {
    startTrack('ep1');
    tracker.start('ep1', saver);
    player.duration.value = const Duration(minutes: 30);
    player.position.value = const Duration(minutes: 10);

    player.isPlaying.value = false;
    await Future<void>.delayed(Duration.zero);

    expect(sent, [('ep1', 600000, false)]);
    expect(ProgressStore.entry('ep1')?.position, const Duration(minutes: 10));
  });

  test('moving on from the end of a track marks it completed', () async {
    startTrack('c1');
    tracker.start('c1', saver);
    player.duration.value = const Duration(minutes: 5);
    player.position.value = const Duration(minutes: 4, seconds: 59);

    // The queue starts the next chapter straight away.
    startTrack('c2');
    await Future<void>.delayed(Duration.zero);

    expect(sent, [('c1', 300000, true)]);
    // Finished, so it is no longer remembered as a place to resume.
    expect(ProgressStore.entry('c1'), isNull);
  });

  test('switching away part-way saves where it was left', () async {
    startTrack('s1');
    tracker.start('s1', saver);
    player.duration.value = const Duration(minutes: 3);
    player.position.value = const Duration(minutes: 1);

    startTrack('s2');
    await Future<void>.delayed(Duration.zero);

    expect(sent, [('s1', 60000, false)]);
  });

  group('resume', () {
    const length = Duration(minutes: 30);

    test('the newer of the server and the device wins', () {
      ProgressStore.save('x', 120000);
      final deviceSaved = ProgressStore.entry('x')!.savedAt;

      // Server saved earlier: the device's position.
      expect(
        ProgressStore.choose(
          id: 'x',
          length: length,
          server: (
            position: const Duration(minutes: 5),
            completed: false,
            savedAt: deviceSaved.subtract(const Duration(hours: 1)),
          ),
        ),
        const Duration(minutes: 2),
      );
      // Server saved later (another device): the server's.
      expect(
        ProgressStore.choose(
          id: 'x',
          length: length,
          server: (
            position: const Duration(minutes: 5),
            completed: false,
            savedAt: deviceSaved.add(const Duration(hours: 1)),
          ),
        ),
        const Duration(minutes: 5),
      );
      // Offline: the device's.
      expect(
        ProgressStore.choose(id: 'x', length: length),
        const Duration(minutes: 2),
      );
    });

    test('finished or nearly finished starts over', () {
      expect(
        ProgressStore.resumeFrom(
          const Duration(minutes: 29, seconds: 58),
          length,
        ),
        Duration.zero,
      );
      expect(
        ProgressStore.choose(
          id: 'never-played',
          length: length,
          server: (
            position: const Duration(minutes: 10),
            completed: true,
            savedAt: null,
          ),
        ),
        Duration.zero,
      );
    });
  });
}
