import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/watch/controller/liked_videos_controller.dart';
import 'package:beatx_flutter/module/watch/model/like_unlike_model.dart';
import 'package:beatx_flutter/module/watch/model/watch_model.dart';
import 'package:beatx_flutter/module/watch/presentation/screen/liked_videos_screen.dart';
import 'package:beatx_flutter/module/watch/services/watch_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// `GET /videos/liked` as the backend answers it: no channel on the rows.
VideoModel _video(String id, String title) => VideoModel.fromJson({
  '_id': id,
  'title': title,
  'coverUrl': '',
  'genre': {'_id': 'g1', 'name': 'Live'},
  'durationMs': 125000,
  'isLiked': true,
});

final class _FakeVideos extends VideoInterface {
  final liked = [_video('v1', 'Live at the Arena'), _video('v2', 'Acoustic')];
  final toggled = <String>[];

  @override
  FutureRequest<Success<List<VideoModel>>> getLikedVideos() async =>
      Right(Success(data: liked.toList()));

  @override
  FutureRequest<Success<PagedResult<VideoModel>>> likedVideosPage({
    required int page,
    required int limit,
  }) async {
    final start = (page - 1) * limit;
    final items = liked.skip(start).take(limit).toList();
    return Right(
      Success(
        data: PagedResult(
          items: items,
          total: liked.length,
          page: page,
          limit: limit,
        ),
      ),
    );
  }

  @override
  FutureRequest<Success<LikeUnlikeModel>> likeUnlike(String id) async {
    toggled.add(id);
    liked.removeWhere((video) => video.id == id);
    return Right(Success(data: LikeUnlikeModel(liked: false, likeCount: 0)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeVideos api;

  setUp(() {
    Get.testMode = true;
    api = _FakeVideos();
    Get.put<VideoInterface>(api);
  });

  tearDown(Get.reset);

  test('loads the liked videos, and unliking one drops it', () async {
    final ctrl = LikedVideosController.instance;
    await ctrl.fetch();

    expect(
      [for (final v in ctrl.videos) v.title],
      ['Live at the Arena', 'Acoustic'],
    );
    expect(ctrl.isLiked('v2'), isTrue);

    await ctrl.unlike(ctrl.videos.first);
    expect(api.toggled, ['v1']);
    expect([for (final v in ctrl.videos) v.id], ['v2']);
  });

  testWidgets('the screen lists them on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: LikedVideosScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Liked Videos'), findsOneWidget);
    expect(find.text('Live at the Arena'), findsOneWidget);
    expect(find.text('Acoustic'), findsOneWidget);
    expect(find.text('2:05'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
