import 'package:get/get.dart';

import '../model/genre_model.dart';
import '../model/recent_track_model.dart';

class ExploreController extends GetxController {
  final searchText = ''.obs;

  final genres = const <GenreModel>[
    GenreModel(title: 'Pop', image: 'assets/image/genre_pop.png'),
    GenreModel(title: 'Synth Wave', image: 'assets/image/genre_synth_wave.png'),
    GenreModel(title: 'Rock', image: 'assets/image/genre_rock.png'),
    GenreModel(title: 'Jazz', image: 'assets/image/genre_jazz.png'),
    GenreModel(
      title: 'Hip Hop & Soul',
      image: 'assets/image/genre_hiphop_soul.png',
    ),
    GenreModel(title: 'Shop', image: 'assets/image/genre_shop.png'),
    GenreModel(title: 'Podcasts', image: 'assets/image/genre_podcasts.png'),
    GenreModel(title: 'Audiobooks', image: 'assets/image/genre_audiobooks.png'),
  ].obs;

  final recentTracks = const <RecentTrackModel>[
    RecentTrackModel(
      image: 'assets/image/Album Art.png',
      title: 'Amar Hote Hote',
      artist: 'Mokhlesul Islam Nilu',
      duration: '4:20',
    ),
    RecentTrackModel(
      image: 'assets/image/Container.png',
      title: 'Tumi Onek Dami',
      artist: 'Fahim Islam',
      duration: 'NEW',
    ),
    RecentTrackModel(
      image: 'assets/image/Album Art (1).png',
      title: 'Emon Ekta Golpo',
      artist: 'Nabila',
      duration: '3:15',
    ),
  ].obs;

  void updateSearch(String value) {
    searchText.value = value;
  }

  void clearRecentSearches() {
    recentTracks.clear();
  }
}
