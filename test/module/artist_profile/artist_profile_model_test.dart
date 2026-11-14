import 'package:beatx_flutter/module/artist_profile/model/artist_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads GET /artists/:id as the test server answers it', () {
    final artist = ArtistProfileModel.fromJson(
      {
        '_id': '6ae02d25db3cacd54205affb',
        'name': 'BeatX Artist',
        'stageName': 'test',
        'avatar': 'https://cdn.example/avatar.webp',
        'coverImageUrl': null,
        'isVerified': true,
        'bio': 'Hello testing',
        'genres': [
          {'_id': null, 'name': 'Pop'},
          {'_id': 'g2', 'name': 'Rock'},
        ],
        'followerCount': 1200,
        'isFollowing': false,
        'monthlyListeners': 3,
      },
      songs: [
        ArtistSongModel.fromJson({
          '_id': 's1',
          'title': 'Hum',
          'playCount': 1520000,
          'coverUrl': 'https://cdn.example/hum.webp',
        }, 0),
      ],
    );

    expect(artist.name, 'test');
    expect(artist.heroImage, 'https://cdn.example/avatar.webp');
    expect(artist.rank, 'Verified');
    expect(artist.genres, ['Pop', 'Rock']);
    expect(artist.monthlyListeners, '3 monthly listeners · 1.2K followers');
    expect(artist.songs.single.rank, '01');
    expect(artist.songs.single.plays, '1.5M plays');
    expect(artist.playlistCover, 'https://cdn.example/hum.webp');

    final followed = artist.copyWith(isFollowing: true, followerCount: 1201);
    expect(followed.monthlyListeners, '3 monthly listeners · 1.2K followers');
    expect(followed.isFollowing, isTrue);
  });

  test('tour date reads the event date, city and sold-out flag', () {
    final tour = TourDateModel.fromJson({
      '_id': 'e1',
      'title': 'Live in Dhaka',
      'venue': 'City Arena',
      'city': 'Dhaka',
      'eventDate': '2026-12-01T18:00:00.000Z',
      'soldOut': true,
    });
    expect(tour.month, 'DEC');
    expect(tour.venue, 'City Arena');
    expect(tour.location, 'Dhaka');
    expect(tour.isSoldOut, isTrue);
    expect(tour.event, isNotNull);
  });
}
