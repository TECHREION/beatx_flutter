import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../../../core/api_handler/paged_result.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/base/search_list_controller.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/audiobook_model.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';

/// Every new-release audiobook, a page at a time as the grid scrolls, and
/// filtered by genre on the server. The home feed carries only the first few.
class AudiobookNewReleasesController extends SearchListController<Audiobook> {
  AudioBookInterface _interface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  @override
  FutureRequest<Success<PagedResult<Audiobook>>> fetchPage({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) => _interface().newReleases(genreId: genreId, page: page, limit: limit);

  @override
  String searchableText(Audiobook book) => '${book.title} ${book.author}';
}
