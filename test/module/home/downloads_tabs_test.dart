import 'dart:io';

import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:beatx_flutter/module/audiobook/controller/audiobook_download_controller.dart';
import 'package:beatx_flutter/module/home/controller/download_controller.dart';
import 'package:beatx_flutter/module/home/presentation/screens/downloads_screen.dart';
import 'package:beatx_flutter/module/home/services/song_download_service.dart';
import 'package:beatx_flutter/module/podcast/controller/episode_download_controller.dart';
import 'package:beatx_flutter/module/watch/controller/video_download_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _SilentPlayer extends PlayerController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  // ignore: must_call_super
  void onClose() {}
}

void main() {
  late Directory temp;

  setUp(() async {
    Get.testMode = true;
    temp = await Directory.systemTemp.createTemp('downloads_tabs_test');
    SongDownloadService files(String folder) =>
        SongDownloadService(baseDirectory: () async => temp, folder: folder);
    Get.put<PlayerController>(_SilentPlayer(), permanent: true);
    Get.put(DownloadController(service: files('downloads')), permanent: true);
    Get.put(
      VideoDownloadController(service: files('video_downloads')),
      permanent: true,
    );
    Get.put(
      EpisodeDownloadController(service: files('episode_downloads')),
      permanent: true,
    );
    Get.put(
      AudiobookDownloadController(service: files('audiobook_downloads')),
      permanent: true,
    );
  });

  tearDown(() async {
    Get.reset();
    await temp.delete(recursive: true);
  });

  testWidgets('every tab opens on a narrow phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: DownloadsScreen()));
    await tester.runAsync(
      () => Future.wait([
        DownloadController.instance.ready(),
        VideoDownloadController.instance.ready(),
        EpisodeDownloadController.instance.ready(),
        AudiobookDownloadController.instance.ready(),
      ]),
    );
    await tester.pump();

    for (final (tab, empty) in [
      ('Videos', 'No downloaded videos yet'),
      ('Podcasts', 'No downloaded episodes yet'),
      ('Audiobooks', 'No downloaded audiobooks yet'),
    ]) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.text(empty), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
