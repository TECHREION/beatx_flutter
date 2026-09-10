import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/search_category_model.dart';
import '../services/podcast_interface.dart';
import '../services/podcast_interface_impl.dart';
import 'podcast_controller.dart';

/// Podcast search, behind `GET /podcasts/search`.
///
/// The filter chips are podcast categories rather than genres — that route
/// filters on `category`, and those ids are their own set.
class PodcastSearchController extends SearchListController<CategoryPodcast> {
  PodcastInterface _podcastInterface() {
    if (!Get.isRegistered<PodcastInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<PodcastInterface>(
        PodcastInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<PodcastInterface>();
  }

  PodcastController _podcastController() {
    if (!Get.isRegistered<PodcastController>()) {
      Get.put(PodcastController());
    }
    return Get.find<PodcastController>();
  }

  /// The categories the chips offer, taken from what the podcast home
  /// already loaded rather than fetched again.
  List<({String id, String label})> get categories => [
    for (final category in _podcastController().categories)
      if (category.genreId.isNotEmpty)
        (id: category.genreId, label: category.name),
  ];

  @override
  FutureRequest<Success<PagedResult<CategoryPodcast>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) {
    return _podcastInterface().searchPodcast(
      query: query,
      genreId: genreId,
      page: page,
      limit: limit,
    );
  }

  @override
  String searchableText(CategoryPodcast podcast) =>
      '${podcast.title} ${podcast.category.name}';
}
