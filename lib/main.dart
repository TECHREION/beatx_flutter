import 'package:beatx_flutter/app/splash_view.dart';
import 'package:beatx_flutter/core/di/external_service_di.dart';
import 'package:beatx_flutter/core/di/internal_service_di.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  externalServiceDI();
  internalServiceDI();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BeatX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0C),
      ),
      home: SplashView(),
    );
  }
}
