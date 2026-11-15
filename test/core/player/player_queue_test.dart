import 'package:beatx_flutter/core/player/player_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlayerController player;
  late List<String> started;

  setUp(() {
    started = [];
    // The queue logic only: starting a track is recorded and makes it the
    // current one, as a real start would. No audio engine is created.
    player = PlayerController();
    Future<void> start(String id) async {
      started.add(id);
      player.trackId.value = id;
    }

    player.setQueue(['a', 'b', 'c'], current: 'b', start: start);
    player.trackId.value = 'b';
  });

  test('next and previous move through the list', () async {
    expect(player.hasNext, isTrue);
    expect(player.hasPrevious, isTrue);

    await player.next();
    expect(started, ['c']);
    expect(player.hasNext, isFalse, reason: 'last track, repeat off');
    expect(await player.next(), isFalse);

    await player.previous();
    await player.previous();
    expect(started, ['c', 'b', 'a']);
  });

  test('repeat all wraps around, repeat one is a mode of its own', () async {
    player.trackId.value = 'c';
    player.cycleRepeat();
    expect(player.repeatMode.value, PlayerRepeat.all);
    expect(player.hasNext, isTrue);
    await player.next();
    expect(started, ['a']);

    player.cycleRepeat();
    expect(player.repeatMode.value, PlayerRepeat.one);
    player.cycleRepeat();
    expect(player.repeatMode.value, PlayerRepeat.off);
  });

  test('shuffle keeps the current track and visits every other once', () async {
    player.setQueue(
      [for (var i = 0; i < 20; i++) 't$i'],
      current: 't5',
      start: (id) async {
        started.add(id);
        player.trackId.value = id;
      },
    );
    player.trackId.value = 't5';
    player.toggleShuffle();
    expect(player.shuffle.value, isTrue);

    while (await player.next()) {}
    expect(started, hasLength(19));
    expect(started.toSet(), hasLength(19));
    expect(started, isNot(contains('t5')));
  });

  test('a track outside the queue has no next', () {
    player.trackId.value = 'podcast-episode';
    expect(player.hasQueue, isFalse);
    expect(player.hasNext, isFalse);
  });
}
