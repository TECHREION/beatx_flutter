import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/watch_model.dart';
import '../services/watch_interface.dart';
import '../services/watch_interface_impl.dart';

/// Every video of a [VideoFeed], a page at a time as the list scrolls,
/// behind the Watch screen's "View All". Paging and the genre filter come
/// from [SearchListController].
class VideoBrowseController extends SearchListController<VideoModel> {
  VideoBrowseController({VideoFeed initialFeed = VideoFeed.trending})
    : feed = initialFeed.obs;

  final Rx<VideoFeed> feed;

  VideoInterface _videoInterface() {
    if (!Get.isRegistered<VideoInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<VideoInterface>(VideoInterfaceImpl(Get.find<AuthorizedPigeon>()));
    }
    return Get.find<VideoInterface>();
  }

  void selectFeed(VideoFeed value) {
    if (feed.value == value) return;
    feed.value = value;
    search();
  }

  @override
  FutureRequest<Success<PagedResult<VideoModel>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) {
    return _videoInterface().browseVideos(
      feed: feed.value,
      genreId: genreId,
      page: page,
      limit: limit,
    );
  }

  @override
  String searchableText(VideoModel video) =>
      '${video.title} ${video.ownerId.name}';
}
