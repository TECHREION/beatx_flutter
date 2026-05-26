import 'package:beatx_flutter/core/localization/app_language_controller.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

Options? appLanguageOptions() {
  if (!Get.isRegistered<AppLanguageController>()) {
    return null;
  }

  return Options(headers: Get.find<AppLanguageController>().headers);
}
