import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/localization/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class AppLanguageController extends GetxController {
  static const String _storageKey = 'preferred_language';

  /// What `PATCH /users/settings` accepts for `language`.
  static const Set<String> _backendLanguages = {
    'en', 'bn', 'ar', 'es', 'fr', 'de', 'zh',
  };

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final RxString languageCode = AppTranslations.fallbackLocaleCode.obs;

  Locale get locale => Locale(languageCode.value);
  bool get isItalian => languageCode.value == 'it';
  String get acceptLanguage => isItalian ? 'it-IT' : 'en-GB';
  Map<String, String> get headers => <String, String>{
    'Accept-Language': acceptLanguage,
    'X-App-Language': languageCode.value,
  };

  Future<void> load() async {
    final storedCode = await _storage.read(key: _storageKey);
    await _applyLanguage(_normalize(storedCode), persist: false);
  }

  Future<bool> changeLanguage(String code, {bool syncBackend = true}) async {
    final nextCode = _normalize(code);
    await _applyLanguage(nextCode);

    // A language the backend has no value for (Italian) is kept on the device
    // only; sending it would be refused and read as a failed change.
    if (!syncBackend ||
        !_backendLanguages.contains(nextCode) ||
        !Get.isRegistered<AppPigeon>()) {
      return true;
    }

    try {
      await Get.find<AppPigeon>().patch(
        ApiEndpoints.userSettings,
        data: <String, dynamic>{'language': nextCode},
        options: Options(headers: headers),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncFromBackendValue(String? code) async {
    if (code == null || code.trim().isEmpty) {
      return;
    }
    await _applyLanguage(_normalize(code));
  }

  Future<void> _applyLanguage(String code, {bool persist = true}) async {
    languageCode.value = code;
    Get.updateLocale(Locale(code));
    if (persist) {
      await _storage.write(key: _storageKey, value: code);
    }
  }

  String _normalize(String? value) {
    final normalized = (value ?? '').trim().toLowerCase().replaceAll('_', '-');
    if (normalized.startsWith('it')) {
      return 'it';
    }
    return 'en';
  }
}
