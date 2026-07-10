import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/audiobook_model.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';

class AudiobookController extends GetxController {
  static const String allGenres = 'All Genres';

  final home = const HomeAudiobookData().obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;
  final selectedGenre = allGenres.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHome();
  }

  AudioBookInterface _audioBookInterface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  Future<void> fetchHome() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _audioBookInterface().audiobookHome();

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      home.value = success.data ?? const HomeAudiobookData();
      if (!genres.contains(selectedGenre.value)) {
        selectedGenre.value = allGenres;
      }
    });

    isLoading.value = false;
  }

  void selectGenre(String genre) => selectedGenre.value = genre;

  List<ContinueListeningBook> get continueListening =>
      home.value.continueListening;

  ContinueListeningBook? get currentBook =>
      continueListening.isEmpty ? null : continueListening.first;

  /// The next book queued behind [currentBook], rendered as the compact card.
  ContinueListeningBook? get queuedBook =>
      continueListening.length > 1 ? continueListening[1] : null;

  List<Bestseller> get bestsellers => home.value.bestsellers;

  List<TrendingAudiobook> get trending => home.value.trending;

  /// `All Genres` followed by every distinct genre present in the response.
  List<String> get genres {
    final names = <String>{
      for (final book in home.value.newReleases) book.genreName,
      for (final book in home.value.trending) book.genreName,
    }..removeWhere((name) => name.isEmpty);

    return [allGenres, ...names];
  }

  List<Audiobook> get newReleases {
    final books = home.value.newReleases;
    if (selectedGenre.value == allGenres) return books;
    return books
        .where((book) => book.genreName == selectedGenre.value)
        .toList();
  }
}
