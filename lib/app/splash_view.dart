import 'package:beatx_flutter/module/onbording/common/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B0B0C),
      ),
      child: const Scaffold(
        backgroundColor: Color(0xFF0B0B0C),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(height: 72, width: 180),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Color(0xFF40DDEB),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
