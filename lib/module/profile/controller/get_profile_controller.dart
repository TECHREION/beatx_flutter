import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/profile_model.dart';
import '../services/profile_interface.dart';
import '../services/profile_interface_impl.dart';

/// The signed-in user, behind `GET /users/me`.
///
/// Shared rather than screen-scoped: the profile screen and the edit form
/// show the same user, so a save on one is seen by the other. `AppManager`
/// registers it on sign-in.
class ProfileController extends GetxController {
  /// The shared instance, registered on first use.
  static ProfileController get instance {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
    return Get.find<ProfileController>();
  }

  final profile = Rxn<UserProfileModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so a blank name can be told apart
  /// from one that has not arrived yet.
  final hasLoaded = false.obs;

  String get name => profile.value?.name ?? '';
  String get email => profile.value?.email ?? '';
  String? get avatar => profile.value?.avatar;
  String get initial => profile.value?.initial ?? '?';

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  ProfileInterface _profileInterface() {
    if (!Get.isRegistered<ProfileInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<ProfileInterface>(
        ProfileInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ProfileInterface>();
  }

  Future<void>? _inFlight;

  /// Reloads the profile.
  ///
  /// A second caller joins the fetch already running rather than starting a
  /// rival one — the edit screen asks for the profile at the same moment this
  /// controller's own first fetch is still in flight.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _profileInterface().getProfile();

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      if (success.data != null) profile.value = success.data;
    });

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Adopts the user a save answered with, so every screen showing the
  /// profile moves to it without another fetch.
  void apply(UserProfileModel user) {
    profile.value = user;
    hasLoaded.value = true;
  }
}
