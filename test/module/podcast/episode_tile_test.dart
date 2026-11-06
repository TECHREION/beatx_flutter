import 'package:beatx_flutter/module/podcast/model/podcast_home_model.dart';
import 'package:beatx_flutter/module/podcast/presentation/widget/episode_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a new episode with a two-line title fits the tile', (
    tester,
  ) async {
    final episode = RecentEpisode.fromJson({
      '_id': 'e1',
      'podcastId': {'_id': 'p1', 'title': 'Show'},
      'episodeNumber': 3,
      'seasonNumber': 1,
      'title': 'A very long episode title that takes up two whole lines here',
      'durationMs': 60000,
      'publishedAt': DateTime.now().toIso8601String(),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 370, child: EpisodeTile(episode: episode)),
        ),
      ),
    );

    // Layout overflow would have been reported as an exception here.
    expect(tester.takeException(), isNull);
    expect(find.text('NEW'), findsOneWidget);
    expect(tester.getSize(find.byType(EpisodeTile)).height, greaterThan(92));
  });
}
