import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/helpers/handle_fold.dart';
import 'package:beatx_flutter/core/notifiers/button_status_notifier.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface_impl.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileController extends GetxController {
  final ProcessStatusNotifier processNotifier = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  final ImagePicker _picker;

  EditProfileController({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final profile = const ProfileModel(
    fullName: '',
    email: '',
    phoneNumber: '',
  ).obs;

  final isLoadingProfile = true.obs;

  ProfileInterface _getOrCreateProfileInterface() {
    if (!Get.isRegistered<ProfileInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ProfileInterface>(
        ProfileInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ProfileInterface>();
  }

  Future<void> fetchProfile() async {
    isLoadingProfile.value = true;
    final result = await _getOrCreateProfileInterface().getProfile();
    result.fold(
      (_) {},
      (userProfile) {
        profile.value = userProfile.toProfileModel();
      },
    );
    isLoadingProfile.value = false;
  }

  Future<void> pickProfileImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) return;

    final imageBytes = await image.readAsBytes();
    profile.value = profile.value.copyWith(
      imageBytes: imageBytes,
      imageName: image.name.isEmpty ? 'profile.jpg' : image.name,
    );
    processNotifier.setEnabled();
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phoneNumber,
    SnackbarNotifier? snackbarNotifier,
  }) {
    profile.value = profile.value.copyWith(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
    );

    processNotifier.setLoading();

    return _getOrCreateProfileInterface().updateProfile(profile.value).then((
      result,
    ) {
      handleFold(
        either: result,
        processStatusNotifier: processNotifier,
        errorSnackbarNotifier: snackbarNotifier,
      );
    });
  }

  @override
  void onClose() {
    processNotifier.dispose();
    super.onClose();
  }
}
