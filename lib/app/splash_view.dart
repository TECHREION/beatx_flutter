// import 'package:beatx_flutter/module/onbording/common/app_logo.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class SplashView extends StatelessWidget {
//   const SplashView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.light.copyWith(
//         statusBarColor: Colors.transparent,
//         systemNavigationBarColor: const Color(0xFF0B0B0C),
//       ),
//       child: const Scaffold(
//         backgroundColor: Color(0xFF0B0B0C),
//         body: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AppLogo(height: 72, width: 180),
//               SizedBox(height: 32),
//               CircularProgressIndicator(
//                 color: Color(0xFF40DDEB),
//                 strokeWidth: 2.5,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:async';
import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../module/app_ground.dart';
import '../module/auth/presentation/screens/login_screen.dart';
import '../module/onbording/common/app_logo.dart';
import 'app_manager.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 1000000), _navigateNext);
  }

  void _navigateNext() {
    final appManager = Get.find<AppManager>();

    if (appManager.currentAuthStatus is Authenticated) {
      // User is logged in → go to AppGround
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AppGround()),
      );
    } else {
      // User not logged in → go to Login screen
      Navigator.push(context, 
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFF0B0B0C), body: Center(child: AppLogo()));
  }
}