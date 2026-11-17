import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/genre-artist/controller/genre_controller.dart';
import 'package:beatx_flutter/module/home/model/listem_miusic_detalis_model.dart';
import 'package:beatx_flutter/module/home/presentation/screens/all_songs_screen.dart';
import 'package:beatx_flutter/module/home/services/listen_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Pages of [total] made-up songs per feed, named after the feed.
final class _FakeSongs extends ListenInterface {
  final int total = 45;
  final requests = <(SongFeed, int)>[];

  @override
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> browseSongs({
    required SongFeed feed,
    required String genreId,
    required int page,
    required int limit,
  }) async {
    requests.add((feed, page));
    final start = (page - 1) * limit;
    final count = (total - start).clamp(0, limit);
    return Right(
      Success(
        data: PagedResult.fromJson({
          'data': [
            for (var i = start; i < start + count; i++)
              {
                '_id': '${feed.name}-$i',
                'title': '${feed.label} song $i',
                'artist': 'Artist $i',
                'durationMs': 180000,
              },
          ],
          'total': total,
          'page': page,
          'limit': limit,
        }, ListenMusicDetailsModel.fromJson),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// No genre chips, and no network call for them.
class _NoGenres extends GenreController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  late _FakeSongs api;

  setUp(() {
    Get.testMode = true;
    api = _FakeSongs();
    Get.put<ListenInterface>(api);
    Get.put<GenreController>(_NoGenres(), permanent: true);
  });
  tearDown(Get.reset);

  Future<void> open(WidgetTester tester, {SongFeed? feed}) async {
    tester.view.physicalSize = const Size(402, 874) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        home: feed == null
            ? AllSongsScreen()
            : AllSongsScreen(initialFeed: feed),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists every song, loading more as it scrolls', (tester) async {
    await open(tester);

    expect(find.text('New Releases song 0'), findsOneWidget);
    expect(find.text('45 songs'), findsOneWidget);
    expect(api.requests, [(SongFeed.newReleases, 1)]);

    // Far past the first page: the rest is fetched on the way.
    await tester.scrollUntilVisible(
      find.text('New Releases song 44'),
      600,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('New Releases song 44'), findsOneWidget);
    expect(api.requests.map((r) => r.$2), containsAllInOrder([1, 2, 3]));
  });

  testWidgets('the tabs switch between the lists', (tester) async {
    await open(tester, feed: SongFeed.trending);
    expect(find.text('Trending song 0'), findsOneWidget);

    await tester.tap(find.text('All Songs').last);
    await tester.pumpAndSettle();

    expect(find.text('All Songs song 0'), findsOneWidget);
    expect(api.requests.last, (SongFeed.all, 1));
  });
}
