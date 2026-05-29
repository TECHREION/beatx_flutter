import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0B0B0C),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0B0C),
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 44, 16, 70),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 336),
                    child: const _SignupCard(),
                  ),
                ),
              ),
              const Positioned(right: 14, bottom: 8, child: _HelpButton()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0E),
        borderRadius: BorderRadius.circular(48),
        border: Border.all(color: const Color(0xFF77727F), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BeatxLogo(),
          const SizedBox(height: 5),
          const _WelcomeText(),
          const SizedBox(height: 26),
          const Text(
            'Create Your Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          const _LabeledField(
            label: 'Full Name',
            hint: 'Name',
            icon: CupertinoIcons.person_crop_square,
          ),
          const SizedBox(height: 17),
          const _LabeledField(
            label: 'EMAIL ADDRESS',
            hint: 'name@email.com',
            icon: CupertinoIcons.envelope,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 17),
          const _LabeledField(
            label: 'PASSWORD',
            hint: '........',
            icon: CupertinoIcons.lock,
            obscureText: true,
          ),
          const SizedBox(height: 24),
          const _SignupButton(),
          const SizedBox(height: 24),
          const _ConnectDivider(),
          const SizedBox(height: 19),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SocialButton.apple(),
              _SocialButton.google(),
              _SocialButton.facebook(),
            ],
          ),
          const SizedBox(height: 19),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFCFCBD1),
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text.rich(
              TextSpan(
                text: 'Already Have an Account? ',
                style: const TextStyle(
                  color: Color(0xFFCFCBD1),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
                children: [
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      color: const Color(0xFFD27BFF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeatxLogo extends StatelessWidget {
  const _BeatxLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: const [
                Positioned(left: -10, top: 12, child: _SpeedLines()),
                Text(
                  'BEAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A70FF),
                    Color(0xFF8E31FF),
                    Color(0xFFFF1DAE),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'X',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 51,
                  height: .88,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedLines extends StatelessWidget {
  const _SpeedLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        6,
        (index) => Container(
          width: 32.0 - (index.isOdd ? 9 : 0),
          height: 2,
          margin: const EdgeInsets.only(bottom: 2),
          color: Colors.white.withValues(alpha: .78),
        ),
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Welcome to BEAT',
        children: [
          TextSpan(
            text: 'X',
            style: TextStyle(
              color: const Color(0xFFC125FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      style: const TextStyle(
        color: Color(0xFFAAA7AD),
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAA7AD),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        TextField(
          keyboardType: keyboardType,
          obscureText: obscureText,
          obscuringCharacter: '*',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFBDB8BF),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFBDB8BF), size: 23),
            prefixIconConstraints: const BoxConstraints(minWidth: 47),
            filled: true,
            fillColor: const Color(0xFF1D1D1E),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32),
              borderSide: const BorderSide(color: Color(0xFF8CFF4E)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignupButton extends StatelessWidget {
  const _SignupButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFA8FF43), Color(0xFF73EECF), Color(0xFF3EDAF3)],
          ),
        ),
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF112020),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectDivider extends StatelessWidget {
  const _ConnectDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFF202022), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            'OR CONNECT WITH',
            style: TextStyle(
              color: Color(0xFFB3AEB6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFF202022), thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton.apple()
    : text = 'apple',
      icon = null,
      color = const Color(0xFFE5E5E5);

  const _SocialButton.google() : text = 'G', icon = null, color = null;

  const _SocialButton.facebook()
    : text = 'f',
      icon = null,
      color = const Color(0xFFFFFFFF);

  final String text;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (text == 'apple') {
      return const SizedBox(width: 54, height: 50, child: _AppleLogo());
    }

    if (icon != null) {
      return Icon(icon, color: color, size: 50);
    }

    final isFacebook = text == 'f';
    return Container(
      width: isFacebook ? 50 : 54,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFacebook ? const Color(0xFF1877F2) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: isFacebook
          ? Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 46,
                height: .95,
                fontWeight: FontWeight.w800,
                fontFamily: 'Arial',
                letterSpacing: 0,
              ),
            )
          : const _GoogleG(),
    );
  }
}

class _AppleLogo extends StatelessWidget {
  const _AppleLogo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AppleLogoPainter());
  }
}

class _AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7E7E7)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final body = Path()
      ..moveTo(w * .53, h * .18)
      ..cubicTo(w * .46, h * .10, w * .33, h * .12, w * .25, h * .24)
      ..cubicTo(w * .08, h * .47, w * .18, h * .82, w * .36, h * .90)
      ..cubicTo(w * .43, h * .94, w * .48, h * .88, w * .54, h * .88)
      ..cubicTo(w * .61, h * .88, w * .66, h * .94, w * .73, h * .88)
      ..cubicTo(w * .82, h * .80, w * .89, h * .68, w * .90, h * .55)
      ..cubicTo(w * .81, h * .51, w * .76, h * .45, w * .76, h * .36)
      ..cubicTo(w * .76, h * .28, w * .80, h * .22, w * .86, h * .17)
      ..cubicTo(w * .76, h * .08, w * .62, h * .09, w * .53, h * .18)
      ..close();

    final leaf = Path()
      ..moveTo(w * .55, h * .17)
      ..cubicTo(w * .58, h * .05, w * .66, h * -.02, w * .76, h * .00)
      ..cubicTo(w * .75, h * .12, w * .67, h * .20, w * .55, h * .17)
      ..close();

    canvas.drawPath(body, paint);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ).createShader(bounds);
      },
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 54,
          height: .95,
          fontWeight: FontWeight.w800,
          fontFamily: 'Arial',
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1D),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF28282B)),
      ),
      child: const Icon(
        CupertinoIcons.question_circle,
        color: Color(0xFFB9B6BC),
        size: 21,
      ),
    );
  }
}
