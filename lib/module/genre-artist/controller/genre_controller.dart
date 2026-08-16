import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/genre_model.dart';
import '../services/genre_artist_interface.dart';
import '../services/genre_artist_interface_impl.dart';

/// Every genre the backend knows about, behind `GET /genre`.
///
/// Shared rather than screen-scoped: the list is small, changes rarely and is
/// wanted by anything that browses or filters by genre, so it is fetched once
/// and kept.
class GenreController extends GetxController {
  /// The shared instance, registered on first use.
  static GenreController get instance {
    if (!Get.isRegistered<GenreController>()) {
      Get.put(GenreController(), permanent: true);
    }
    return Get.find<GenreController>();
  }

  final genres = <GenreModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so an empty grid can be told apart
  /// from one that simply has not been asked for yet.
  final hasLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  GenreArtistInterface _genreInterface() {
    if (!Get.isRegistered<GenreArtistInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<GenreArtistInterface>(
        GenreArtistInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<GenreArtistInterface>();
  }

  Future<void> fetch() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = '';

    final result = await _genreInterface().getGenres();

    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => genres.assignAll(success.data ?? const []),
    );

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// The genre behind [id], or null when the list holds none — useful for
  /// turning a song's genre id into a name.
  GenreModel? byId(String id) {
    for (final genre in genres) {
      if (genre.id == id) return genre;
    }
    return null;
  }
}
