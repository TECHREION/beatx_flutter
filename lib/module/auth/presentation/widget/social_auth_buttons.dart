import 'package:flutter/material.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    this.onAppleTap,
    this.onGoogleTap,
    this.onFacebookTap,
  });

  final VoidCallback? onAppleTap;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: _SocialIconButton(
            label: 'Continue with Apple',
            assetPath: 'assets/icon/apple.png',
            onTap: onAppleTap,
          ),
        ),
        Flexible(
          child: _SocialIconButton(
            label: 'Continue with Google',
            assetPath: 'assets/icon/google.png',
            onTap: onGoogleTap,
          ),
        ),
        Flexible(
          child: _SocialIconButton(
            label: 'Continue with Facebook',
            assetPath: 'assets/icon/facebook.png',
            onTap: onFacebookTap,
          ),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({
    required this.label,
    required this.assetPath,
    this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap ?? () {},
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF151516),
              border: Border.all(color: const Color(0xFF2D2D30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                assetPath,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
