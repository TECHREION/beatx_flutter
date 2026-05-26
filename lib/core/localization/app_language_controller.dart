import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/localization/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
class AppLanguageController extends GetxController {
  static const String _storageKey = 'preferred_language';

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

    if (!syncBackend || !Get.isRegistered<AppPigeon>()) {
      return true;
    }

    try {
      await Get.find<AppPigeon>().patch(
        ApiEndpoints.userPreferences,
        data: <String, dynamic>{'preferredLanguage': nextCode},
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
