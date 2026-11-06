import 'dart:async';

import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/api_endpoints.dart';
import 'public_settings.dart';

/// Keeps the app's view of `GET /settings/public` current: maintenance,
/// whether new accounts are open, and the announcement banner.
///
/// That route needs no login and stays reachable during maintenance, so this
/// runs from launch and keeps polling, which is also how the app notices that
/// maintenance has ended. A failed check keeps the last answer.
class AppAvailabilityController extends GetxController {
  AppAvailabilityController({
    Future<Map<String, dynamic>> Function()? fetchSettings,
    FlutterSecureStorage? storage,
    this.pollInterval = const Duration(minutes: 1),
  }) : _fetchSettings = fetchSettings ?? _fetchFromApi,
       _storage = storage ?? const FlutterSecureStorage();

  static AppAvailabilityController get instance =>
      Get.find<AppAvailabilityController>();

  static const _dismissedKey = 'dismissed_announcement';

  final Future<Map<String, dynamic>> Function() _fetchSettings;
  final FlutterSecureStorage _storage;
  final Duration pollInterval;

  final settings = const PublicSettings().obs;

  /// The `updatedAt` of the announcement the user last closed.
  final _dismissedVersion = RxnString();

  Timer? _poll;

  static Future<Map<String, dynamic>> _fetchFromApi() async {
    final response = await Get.find<AppPigeon>().get(
      ApiEndpoints.publicSettings,
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_restoreDismissed());
    unawaited(check());
    _poll = Timer.periodic(pollInterval, (_) => check());
  }

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }

  Future<void> _restoreDismissed() async {
    try {
      _dismissedVersion.value = await _storage.read(key: _dismissedKey);
    } catch (error) {
      if (kDebugMode) debugPrint('Could not read dismissed banner: $error');
    }
  }

  /// Fetches the current settings.
  Future<void> check() async {
    try {
      settings.value = PublicSettings.fromJson(await _fetchSettings());
    } catch (error) {
      if (kDebugMode) debugPrint('Availability check failed: $error');
    }
  }

  /// The announcement to show, or null when there is none or it was closed.
  Announcement? get visibleAnnouncement {
    final announcement = settings.value.announcement;
    if (announcement == null) return null;
    return announcement.updatedAt == _dismissedVersion.value
        ? null
        : announcement;
  }

  /// Closes the current announcement, until it next changes.
  Future<void> dismissAnnouncement() async {
    final version = settings.value.announcement?.updatedAt;
    if (version == null) return;

    _dismissedVersion.value = version;
    try {
      await _storage.write(key: _dismissedKey, value: version);
    } catch (error) {
      // It stays closed for this launch, and at worst shows once more.
      if (kDebugMode) debugPrint('Could not save dismissed banner: $error');
    }
  }
}
