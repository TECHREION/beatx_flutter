import 'package:flutter/material.dart';

/// The app's one back button: a frosted circle with a rounded arrow, the same
/// size and look as the header's search and notification buttons.
///
/// Every screen uses it, so "back" looks and sits the same everywhere. With
/// no [onPressed] it goes back the way the system back gesture does
/// ([Navigator.maybePop]), so a screen that intercepts back still gets to.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.color});

  final VoidCallback? onPressed;

  /// The arrow's color; white unless a screen's palette needs otherwise.
  final Color? color;

  static const double size = 42;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed ?? () => Navigator.maybePop(context),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: color ?? Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
