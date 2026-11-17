import 'package:beatx_flutter/core/player/now_playing.dart';
import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/audiobook/presentation/widget/downloaded_audiobook_list.dart';
import 'package:beatx_flutter/module/home/model/downloaded_song_model.dart';
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

DownloadedSong _chapter(String id, String title, int number) => DownloadedSong(
  id: id,
  downloadId: 'd',
  title: title,
  artist: 'Author',
  artworkUrl: '',
  fileName: '$id.mp3',
  fileSize: 1,
  durationMs: 60000,
  genre: '',
  downloadedAt: DateTime(2026),
  groupId: 'book',
  groupTitle: 'The Book',
  trackNumber: number,
);

void main() {
  late PlayerController player;
  final played = <String>[];

  setUp(() {
    Get.testMode = true;
    played.clear();
    player = Get.put<PlayerController>(_SilentPlayer(), permanent: true);
    // What playing a downloaded two-chapter book offline sets up.
    player.setNowPlaying(
      NowPlayingContext(
        kind: NowPlayingKind.chapter,
        collectionId: 'book',
        collectionTitle: 'The Book',
        collectionSubtitle: 'Author',
        entries: const [
          NowPlayingEntry(id: 'c1', title: 'The Beginning', label: 'Chapter 1'),
          NowPlayingEntry(id: 'c2', title: 'The Middle', label: 'Chapter 2'),
        ],
        playEntry: (id) async => played.add(id),
      ),
    );
    player.trackId.value = 'c1';
    player.title.value = 'The Beginning';
    player.artist.value = 'Author';
  });
  tearDown(() => Get.reset());

  testWidgets('an offline book shows its chapters and plays the one picked', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: PlayerScreen()));
    await tester.pump();

    expect(find.text('PLAYING FROM AUDIOBOOK'), findsOneWidget);
    expect(find.text('CHAPTER 1 OF 2'), findsOneWidget);
    expect(find.text('CHAPTERS'), findsOneWidget);

    // The badge itself opens the chapter list.
    await tester.tap(find.text('CHAPTER 1 OF 2'));
    await tester.pumpAndSettle();

    expect(find.text('The Middle'), findsOneWidget);
    expect(find.text('PAUSED · Chapter 1 of 2'), findsOneWidget);

    await tester.tap(find.text('The Middle'));
    await tester.pump();
    expect(played, ['c2']);
  });

  test('saved chapters play in chapter order', () {
    final ordered = DownloadedAudiobookList.inOrder([
      _chapter('c2', 'Two', 2),
      _chapter('c1', 'One', 1),
    ]);
    expect(ordered.map((c) => c.id), ['c1', 'c2']);
    expect(DownloadedAudiobookList.chapterLabel(ordered.last, 1), 'Chapter 2');
  });
}
