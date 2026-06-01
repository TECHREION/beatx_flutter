import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool trackHistory = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          const _ProfileGlowBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _BackButton(context),
                      const SizedBox(width: 12),
                      const Text(
                        'Settings',
                        style: TextStyle(color: Colors.white, fontSize: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _row(
                          'Language',
                          trailing: const Text(
                            'English',
                            style: TextStyle(color: Colors.white),
                          ),
                          icon: Icons.keyboard_arrow_down,
                        ),
                        _switchRow(
                          title: 'Track Search History',
                          value: trackHistory,
                          onChanged: (value) {
                            setState(() => trackHistory = value);
                          },
                        ),
                        _arrowRow('Clear Cache'),
                        _arrowRow('Delete Data'),
                        _arrowRow(
                          'Delete Account',
                          titleColor: Colors.red,
                          arrowColor: Colors.red,
                        ),
                      ],
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

  Widget _row(String title, {required Widget trailing, IconData? icon}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          trailing,
          if (icon != null) Icon(icon, color: Colors.white),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: const Color(0xFF9BFF4D),
        onChanged: onChanged,
      ),
    );
  }

  Widget _arrowRow(
    String title, {
    Color titleColor = Colors.white,
    Color arrowColor = Colors.white,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: Icon(Icons.chevron_right, color: arrowColor),
    );
  }
}

class _ProfileGlowBackground extends StatelessWidget {
  const _ProfileGlowBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 80,
          left: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurple.withValues(alpha: .2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyan.withValues(alpha: .15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton(this.parentContext);

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: .06),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(parentContext),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
