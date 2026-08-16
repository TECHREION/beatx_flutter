import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/listem_miusic_detalis_model.dart';
import '../services/linter_interface_impl.dart';
import '../services/listen_interface.dart';
import 'home_controller.dart';

/// Song search, behind `GET /songs/search`.
class SongSearchController
    extends SearchListController<ListenMusicDetailsModel> {
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

  @override
  FutureRequest<Success<PagedResult<ListenMusicDetailsModel>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) {
    return _listenInterface().searchSong(
      query: query,
      genreId: genreId,
      page: page,
      limit: limit,
    );
  }

  @override
  String searchableText(ListenMusicDetailsModel song) =>
      '${song.title} ${song.artist} ${song.album ?? ''}';

  /// Plays [song] and opens the player, through the same path the home screen
  /// uses.
  Future<void> play(ListenMusicDetailsModel song) =>
      _homeController().playSong(song.id);
}
