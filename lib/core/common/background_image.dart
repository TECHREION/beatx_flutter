import 'package:flutter/material.dart';

class AuthBackgroundImage extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const AuthBackgroundImage({
    super.key,
    required this.child,
    this.imagePath = "assets/image/ab.png",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
          child,
        ],
      ),
    );
  }
}

class OnboardingBackgroundImage extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const OnboardingBackgroundImage({
    super.key,
    required this.child,
    this.imagePath = "assets/image/Onboarding.png",
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),
          child,
        ],
      ),
    );
  }
}

class AppBackgroundImage extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const AppBackgroundImage({
    super.key,
    required this.child,
    this.imagePath = "assets/image/hb.png",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        // Optional: Add dark overlay to make UI more readable
        // decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
        child: child,
      ),
    );
  }
}

class ProfileBackgroundImage extends StatelessWidget {
  final Widget child;
  final String imagePath;

  const ProfileBackgroundImage({
    super.key,
    required this.child,
    this.imagePath = "assets/image/pb.png",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        // Optional: Add dark overlay to make UI more readable
        // decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
        child: child,
      ),
    );
  }
}
