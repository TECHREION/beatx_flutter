import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/listem_miusic_detalis_model.dart';
import '../services/listen_interface.dart';
import '../services/lister_interface_impl.dart';
import 'home_controller.dart';

/// Every song of a [SongFeed], a page at a time as the list scrolls, behind
/// the "See all" screen. The home feed only carries the first few.
///
/// Paging and the genre filter come from [SearchListController]; this only
/// says which list to page through.
class SongBrowseController
    extends SearchListController<ListenMusicDetailsModel> {
  SongBrowseController({SongFeed initialFeed = SongFeed.newReleases})
    : feed = initialFeed.obs;

  /// The list on screen; switching it starts again from page one.
  final Rx<SongFeed> feed;

  ListenInterface _listenInterface() {
    if (!Get.isRegistered<ListenInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ListenInterface>(
        ListenInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ListenInterface>();
  }

  HomeController _homeController() {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    return Get.find<HomeController>();
  }

  void selectFeed(SongFeed value) {
    if (feed.value == value) return;
    feed.value = value;
    search();
  }

  @override
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) {
    return _listenInterface().browseSongs(
      feed: feed.value,
      genreId: genreId,
      page: page,
      limit: limit,
    );
  }

  @override
  String searchableText(ListenMusicDetailsModel song) =>
      '${song.title} ${song.artist}';

  /// Plays [song] with the whole list loaded so far as the queue, so next
  /// and previous move through it.
  Future<void> play(ListenMusicDetailsModel song) => _homeController().playSong(
    song.id,
    queue: [for (final s in results) s.id],
    source: feed.value.label,
  );

  /// Plays the list from the top.
  Future<void> playAll() async {
    if (results.isEmpty) return;
    await play(results.first);
  }
}
