import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/notifiers/snackbar_notifier.dart';
import 'package:get/get.dart';

import '../model/profile_model.dart';
import '../services/profile_interface.dart';
import '../services/profile_interface_impl.dart';

/// The user's settings, behind `GET /users/settings` and
/// `PATCH /users/settings`.
///
/// Shared rather than screen-scoped: General Settings, Privacy and Settings
/// each show a slice of the same eight fields, so a switch flipped on one is
/// seen by the others.
class SettingsController extends GetxController {
  /// The shared instance, registered on first use.
  static SettingsController get instance {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }
    return Get.find<SettingsController>();
  }

  final settings = const ProfileSettings().obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  /// False until a fetch has come back, so the defaults above can be told
  /// apart from settings the backend actually holds. The screens keep their
  /// switches inert until then — flipping one before the real values land
  /// would save the defaults over them.
  final hasLoaded = false.obs;

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

  /// Reloads the settings.
  ///
  /// A second caller joins the fetch already running rather than starting a
  /// rival one — all three settings screens ask on open, and the first two can
  /// overlap when one is pushed straight from the other.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _profileInterface().getSettings();

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      if (success.data != null) settings.value = success.data!;
    });

    hasLoaded.value = true;
    isLoading.value = false;
  }

  // ------------------------------- writes --------------------------------

  Future<void> setEnablePasscode(bool value, {SnackbarNotifier? notifier}) =>
      _apply(enablePasscode: value, notifier: notifier);

  Future<void> setAllowSms(bool value, {SnackbarNotifier? notifier}) =>
      _apply(allowSms: value, notifier: notifier);

  Future<void> setAllowEmailNotification(
    bool value, {
    SnackbarNotifier? notifier,
  }) => _apply(allowEmailNotification: value, notifier: notifier);

  Future<void> setTrackSearchHistory(bool value, {SnackbarNotifier? notifier}) =>
      _apply(trackSearchHistory: value, notifier: notifier);

  Future<void> setSendUsageData(bool value, {SnackbarNotifier? notifier}) =>
      _apply(sendUsageData: value, notifier: notifier);

  Future<void> setWifiOnlyMode(bool value, {SnackbarNotifier? notifier}) =>
      _apply(wifiOnlyMode: value, notifier: notifier);

  Future<void> setLanguage(String value, {SnackbarNotifier? notifier}) =>
      _apply(language: value, notifier: notifier);

  Future<void> setTheme(String value, {SnackbarNotifier? notifier}) =>
      _apply(theme: value, notifier: notifier);

  /// Writes queued behind one another. The endpoint takes the settings whole,
  /// so two saves in flight at once would each carry a stale copy of what the
  /// other changed.
  Future<void> _queue = Future<void>.value();

  /// Changes waiting their turn, so a save landing mid-queue does not adopt
  /// the answer over a switch the user has already flipped since.
  int _queued = 0;

  /// Moves the switch first and saves behind it, putting it back if the save
  /// is turned down. Nothing is sent before the first fetch lands.
  Future<void> _apply({
    String? language,
    String? theme,
    bool? enablePasscode,
    bool? allowSms,
    bool? allowEmailNotification,
    bool? trackSearchHistory,
    bool? sendUsageData,
    bool? wifiOnlyMode,
    SnackbarNotifier? notifier,
  }) {
    if (!hasLoaded.value) return Future<void>.value();

    final before = settings.value;

    settings.value = before.copyWith(
      language: language,
      theme: theme,
      enablePasscode: enablePasscode,
      allowSms: allowSms,
      allowEmailNotification: allowEmailNotification,
      trackSearchHistory: trackSearchHistory,
      sendUsageData: sendUsageData,
      wifiOnlyMode: wifiOnlyMode,
    );

    // Puts back only the fields this change touched, so a save turned down
    // does not also undo a switch flipped while it was in the air.
    ProfileSettings undo(ProfileSettings current) => current.copyWith(
      language: language == null ? null : before.language,
      theme: theme == null ? null : before.theme,
      enablePasscode: enablePasscode == null ? null : before.enablePasscode,
      allowSms: allowSms == null ? null : before.allowSms,
      allowEmailNotification: allowEmailNotification == null
          ? null
          : before.allowEmailNotification,
      trackSearchHistory: trackSearchHistory == null
          ? null
          : before.trackSearchHistory,
      sendUsageData: sendUsageData == null ? null : before.sendUsageData,
      wifiOnlyMode: wifiOnlyMode == null ? null : before.wifiOnlyMode,
    );

    _queued++;
    isSaving.value = true;

    final write = _queue.then((_) => _save(undo, notifier));
    // The queue must survive a failed save, or every later change is dropped.
    _queue = write.catchError((_) {});
    return write;
  }

  Future<void> _save(
    ProfileSettings Function(ProfileSettings) undo,
    SnackbarNotifier? notifier,
  ) async {
    errorMessage.value = '';

    // Sent whole and read at this moment, so a change queued behind this one
    // rides along rather than waiting for its own turn on the wire.
    final result = await _profileInterface().updateSettings(settings.value);

    _queued--;

    result.fold(
      (failure) {
        settings.value = undo(settings.value);
        errorMessage.value = failure.uiMessage;
        notifier?.notifyError(message: failure.uiMessage);
      },
      (success) {
        // Adopted only once the queue is clear — taking the answer while a
        // change is still waiting would overwrite a switch already flipped.
        if (success.data != null && _queued == 0) settings.value = success.data!;
      },
    );

    if (_queued == 0) isSaving.value = false;
  }
}
