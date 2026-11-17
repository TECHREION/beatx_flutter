import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/genre-artist/controller/genre_controller.dart';
import 'package:beatx_flutter/module/podcast/model/episodes_model.dart';
import 'package:beatx_flutter/module/podcast/model/search_category_model.dart';
import 'package:beatx_flutter/module/podcast/presentation/screen/all_episodes_screen.dart';
import 'package:beatx_flutter/module/podcast/services/podcast_interface.dart';
import 'package:beatx_flutter/module/watch/model/watch_model.dart';
import 'package:beatx_flutter/module/watch/presentation/screen/all_videos_screen.dart';
import 'package:beatx_flutter/module/watch/services/watch_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 30 shows of 2 episodes each, paged the way `/podcasts/search` pages them.
final class _FakePodcasts extends PodcastInterface {
  static const shows = 30;
  final pagesAsked = <int>[];

  @override
  FutureRequest<Success<PagedResult<CategoryPodcast>>> searchPodcast({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    pagesAsked.add(page);
    final start = (page - 1) * limit;
    return Right(
      Success(
        data: PagedResult(
          items: [
            for (var i = start; i < start + limit && i < shows; i++)
              CategoryPodcast.fromJson({'_id': 'p$i', 'title': 'Show $i'}),
          ],
          total: shows,
          page: page,
          limit: limit,
        ),
      ),
    );
  }

  @override
  FutureRequest<Success<List<EpisodeModel>>> podcastEpisodes(
    String id, {
    int page = 1,
    int limit = 100,
  }) async {
    final n = int.parse(id.substring(1));
    return Right(
      Success(
        data: [
          for (var e = 0; e < 2; e++)
            EpisodeModel.fromJson({
              'data': [
                {
                  '_id': '$id-e$e',
                  'title': 'Show $n episode $e',
                  'episodeNumber': e + 1,
                  'seasonNumber': 1,
                  // Newer shows have newer episodes.
                  'publishedAt': DateTime(
                    2026,
                    1,
                    1,
                  ).add(Duration(days: n * 2 + e)).toIso8601String(),
                },
              ],
            }),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeVideos extends VideoInterface {
  final asked = <(VideoFeed, int)>[];

  @override
  FutureRequest<Success<PagedResult<VideoModel>>> browseVideos({
    required VideoFeed feed,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    asked.add((feed, page));
    final start = (page - 1) * limit;
    return Right(
      Success(
        data: PagedResult(
          items: [
            for (var i = start; i < start + limit && i < 30; i++)
              VideoModel.fromJson({
                '_id': '${feed.name}$i',
                'title': '${feed.label} video $i',
              }),
          ],
          total: 30,
          page: page,
          limit: limit,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoGenres extends GenreController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  testWidgets('Podcasts "See all activity" lists every show\'s episodes, '
      'newest first, a page of shows at a time', (tester) async {
    final api = _FakePodcasts();
    Get.put<PodcastInterface>(api);

    await show(tester, const AllEpisodesScreen());

    // The first 20 shows; the newest episode is the last show's last one.
    expect(api.pagesAsked, [1]);
    expect(find.text('Show 19 episode 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Show 29 episode 1'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(api.pagesAsked, [1, 2]);
    expect(find.text('Show 29 episode 1'), findsOneWidget);
  });

  testWidgets('Watch "View All" lists videos and switches tabs', (
    tester,
  ) async {
    final api = _FakeVideos();
    Get.put<VideoInterface>(api);
    Get.put<GenreController>(_NoGenres(), permanent: true);

    await show(tester, AllVideosScreen());
    expect(find.text('Trending video 0'), findsOneWidget);

    await tester.tap(find.text('All Videos').last);
    await tester.pumpAndSettle();
    expect(find.text('All Videos video 0'), findsOneWidget);
    expect(api.asked.last, (VideoFeed.all, 1));
  });
}
