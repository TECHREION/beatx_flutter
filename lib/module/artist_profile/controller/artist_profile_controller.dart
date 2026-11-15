import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../home/controller/home_controller.dart';
import '../model/artist_profile_model.dart';
import '../services/artist_profile_service.dart';

/// One artist's public page, loaded from the API by [artistId].
class ArtistProfileController extends GetxController {
  ArtistProfileController(this.artistId, {ArtistProfileService? service})
    : _service =
          service ??
          (Get.isRegistered<AuthorizedPigeon>()
              ? ArtistProfileService(Get.find<AuthorizedPigeon>())
              : null);

  final String artistId;
  final ArtistProfileService? _service;

  final selectedTab = 0.obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final profile = Rxn<ArtistProfileModel>();
  final isFollowing = false.obs;
  final _followBusy = false.obs;

  /// The loaded profile; only read once [profile] is set.
  ArtistProfileModel get artist => profile.value!;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final service = _service;
    if (service == null) {
      errorMessage.value = 'Not available right now.';
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    errorMessage.value = '';

    final result = await service.load(artistId);
    result.fold((failure) => errorMessage.value = failure.uiMessage, (ok) {
      final data = ok.data;
      if (data == null) return;
      profile.value = data;
      isFollowing.value = data.isFollowing;
    });
    isLoading.value = false;
  }

  /// Flips at once and takes the server's answer; undone if the call fails.
  Future<void> toggleFollow() async {
    final service = _service;
    final current = profile.value;
    if (service == null || current == null || _followBusy.value) return;

    _followBusy.value = true;
    final before = isFollowing.value;
    isFollowing.value = !before;

    final result = await service.toggleFollow(artistId);
    result.fold(
      (failure) {
        isFollowing.value = before;
        Get.snackbar('Follow', failure.uiMessage);
      },
      (ok) {
        final (following, followers) = ok.data ?? (!before, 0);
        isFollowing.value = following;
        profile.value = current.copyWith(
          isFollowing: following,
          followerCount: followers,
        );
      },
    );
    _followBusy.value = false;
  }

  /// Plays one of the artist's songs through the home player flow.
  void playSong(String songId) {
    if (songId.isEmpty) return;
    final home = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());
    home.playSong(
      songId,
      queue: [for (final song in profile.value?.songs ?? const []) song.id],
    );
  }

  /// Plays the artist's top song.
  void playTop() {
    final songs = profile.value?.songs ?? const [];
    if (songs.isNotEmpty) playSong(songs.first.id);
  }

  void selectTab(int index) => selectedTab.value = index;
}
