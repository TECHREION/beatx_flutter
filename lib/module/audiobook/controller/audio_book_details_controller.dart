import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/audio_book_details_model.dart';
import '../services/audio_book_interface.dart';
import '../services/audio_book_interface_impl.dart';

class AudioBookDetailsController extends GetxController {
  final details = Rxn<AudiobookDetailsData>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  String? _loadedAudiobookId;

  AudioBookInterface _audioBookInterface() {
    if (!Get.isRegistered<AudioBookInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<AudioBookInterface>(
        AudioBookInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<AudioBookInterface>();
  }

  Future<void> loadDetails(String audiobookId) async {
    if (audiobookId.isEmpty || _loadedAudiobookId == audiobookId) return;

    _loadedAudiobookId = audiobookId;
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _audioBookInterface().audiobookDetails(audiobookId);
    result.fold(
      (failure) => errorMessage.value = failure.uiMessage,
      (success) => details.value = success.data,
    );
    isLoading.value = false;
  }
}
