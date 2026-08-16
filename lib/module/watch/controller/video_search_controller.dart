import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/watch_model.dart';
import '../services/watch_interface.dart';
import '../services/watch_interface_impl.dart';

/// Video search, behind `GET /videos/search`.
class VideoSearchController extends SearchListController<VideoModel> {
  VideoInterface _videoInterface() {
    if (!Get.isRegistered<VideoInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<VideoInterface>(VideoInterfaceImpl(Get.find<AuthorizedPigeon>()));
    }
    return Get.find<VideoInterface>();
  }

  @override
  FutureRequest<Success<PagedResult<VideoModel>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) {
    return _videoInterface().searchVideo(
      query: query,
      genreId: genreId,
      page: page,
      limit: limit,
    );
  }

  @override
  String searchableText(VideoModel video) =>
      '${video.title} ${video.ownerId.name}';
}
