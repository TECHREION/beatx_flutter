import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/helpers/handle_fold.dart';
import 'package:beatx_flutter/core/notifiers/button_status_notifier.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface_impl.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../model/update_profile_model.dart';
import 'get_profile_controller.dart';

class EditProfileController extends GetxController {
  final ProcessStatusNotifier processNotifier = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  final ImagePicker _picker;

  EditProfileController({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final profile = UserUpdateProfile.empty().obs;

  final isLoadingProfile = true.obs;

  /// The failure behind a picture that could not be picked, or empty.
  final pickerError = ''.obs;

  ProfileInterface _getOrCreateProfileInterface() {
    if (!Get.isRegistered<ProfileInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ProfileInterface>(
        ProfileInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ProfileInterface>();
  }

  /// Fills the form from the shared profile, fetching it when nothing has
  /// asked for it yet this run.
  Future<void> fetchProfile() async {
    isLoadingProfile.value = true;

    final shared = ProfileController.instance;
    if (!shared.hasLoaded.value) await shared.fetch();

    final user = shared.profile.value;
    if (user != null) profile.value = UserUpdateProfile.fromProfile(user);

    isLoadingProfile.value = false;
  }

  /// Picks a new avatar. It is held on the form until the save goes out.
  Future<void> pickProfileImage(ImageSource source) async {
    pickerError.value = '';

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return;

      profile.value = profile.value.copyWith(
        imageBytes: await image.readAsBytes(),
        imageName: image.name.isEmpty ? 'avatar.jpg' : image.name,
      );

      // A picture is a change worth saving, so the button comes back to life
      // even when nothing else on the form was touched.
      processNotifier.setEnabled();
    } on PlatformException catch (error) {
      // Camera or photo access turned down, most often.
      pickerError.value = error.message ?? 'Could not open that picture.';
    }
  }

  Future<void> updateProfile({
    required String fullName,
    SnackbarNotifier? snackbarNotifier,
  }) {
    profile.value = profile.value.copyWith(fullName: fullName);

    processNotifier.setLoading();

    return _getOrCreateProfileInterface().updateProfile(profile.value).then((
      result,
    ) {
      handleFold(
        either: result,
        processStatusNotifier: processNotifier,
        errorSnackbarNotifier: snackbarNotifier,
        onSuccess: (user) {
          // The picked bytes have been uploaded — dropping them leaves the
          // form on the avatar url the backend just answered with.
          profile.value = UserUpdateProfile.fromProfile(user);
          ProfileController.instance.apply(user);
        },
      );
    });
  }

  @override
  void onClose() {
    processNotifier.dispose();
    super.onClose();
  }
}
