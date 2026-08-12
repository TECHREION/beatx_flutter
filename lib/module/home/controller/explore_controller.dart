import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/genre_model.dart';
import '../model/listen_model.dart';
import '../services/listen_interface.dart';
import '../services/linter_interface_impl.dart';

class ExploreController extends GetxController {
  final searchText = ''.obs;

  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final listenData = ListenMusicModel().obs;

  @override
  void onInit() {
    super.onInit();
    fetchListenData();
  }

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  Future<void> fetchListenData() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _listenInterface().getListen();

    result.fold((failure) => errorMessage.value = failure.uiMessage, (
      success,
    ) {
      listenData.value = success.data ?? ListenMusicModel();
    });

    isLoading.value = false;
  }

  List<FeaturedSong> get featured => listenData.value.featured;

  List<TrendingSong> get trending => listenData.value.trending;

  List<NewReleaseSong> get newReleases => listenData.value.newReleases;

  List<TopCategory> get topCategories => listenData.value.topCategories;

  List<DailyDiscoverySong> get dailyDiscovery =>
      listenData.value.dailyDiscovery;

  PaginatedSongs get onRepeat => listenData.value.onRepeat;

  PaginatedSongs get recentlyPlayed => listenData.value.recentlyPlayed;

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
