import 'package:get/get.dart';

import '../model/genre_model.dart';
import '../model/recent_track_model.dart';

class ExploreController extends GetxController {
  final searchText = ''.obs;

  final genres = const <GenreModel>[
    GenreModel(title: 'Pop', image: 'assets/image/1.png'),
    GenreModel(title: 'Synth Wave', image: 'assets/image/2.png'),
    GenreModel(title: 'Rock', image: 'assets/image/3.png'),
    GenreModel(title: 'Jazz', image: 'assets/image/4.png'),
    GenreModel(title: 'Hip Hop & Soul', image: 'assets/image/5.png'),
    GenreModel(title: 'Shop', image: 'assets/image/Robot.png'),
    GenreModel(title: 'Podcasts', image: 'assets/image/onboarding1.png'),
    GenreModel(title: 'Audiobooks', image: 'assets/image/UK.png'),
  ].obs;

  final recentTracks = const <RecentTrackModel>[
    RecentTrackModel(
      image: 'assets/image/2.png',
      title: 'Amar Hote Hote',
      artist: 'Mokhlesul Islam Nilu',
      duration: '4:20',
    ),
    RecentTrackModel(
      image: 'assets/image/1.png',
      title: 'Tumi Onek Dami',
      artist: 'Fahim Islam',
      duration: 'NEW',
    ),
    RecentTrackModel(
      image: 'assets/image/3.png',
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
