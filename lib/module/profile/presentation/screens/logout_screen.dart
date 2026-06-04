import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/button_status_notifier.dart';
import 'package:flutter/material.dart';

class LogoutDialog extends StatefulWidget {
  const LogoutDialog({super.key, required this.onLogout, this.onCancel});

  final VoidCallback onLogout;
  final VoidCallback? onCancel;

  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  final _logoutButtonStatus = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );
  final _cancelButtonStatus = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  static const LinearGradient _logoutGradient = LinearGradient(
    colors: [Color(0xFFFF0909), Color(0xFFFF0909)],
  );

  static const LinearGradient _cancelGradient = LinearGradient(
    colors: [Color(0xFF050608), Color(0xFF050608)],
  );

  @override
  void dispose() {
    _logoutButtonStatus.dispose();
    _cancelButtonStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF050608),
          borderRadius: BorderRadius.circular(42),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: .08),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(width: 190, height: 150),
                ...List.generate(
                  7,
                  (index) => Positioned(
                    left: [15, 55, 145, 165, 40, 150, 120][index].toDouble(),
                    top: [25, 170, 45, 135, 105, 80, 20][index].toDouble(),
                    child: Container(
                      width: index.isEven ? 10 : 18,
                      height: index.isEven ? 10 : 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF0909),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Logout?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Are you sure you want to Signout?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 34),
            RSaveButton(
              key: const ValueKey('logout-confirm-button'),
              height: 52,
              borderRadius: BorderRadius.circular(40),
              activeGradient: _logoutGradient,
              buttonStatusNotifier: _logoutButtonStatus,
              saveText: 'Yes, Logout',
              doneText: 'Logging Out',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              onSaveTap: () => _logoutButtonStatus.setSuccess(),
              onDone: widget.onLogout,
            ),
            const SizedBox(height: 16),
            RSaveButton(
              key: const ValueKey('logout-cancel-button'),
              height: 52,
              borderRadius: BorderRadius.circular(40),
              activeGradient: _cancelGradient,
              buttonStatusNotifier: _cancelButtonStatus,
              saveText: 'No, Cancel',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              onSaveTap: _cancel,
              onDone: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _cancel() {
    Navigator.pop(context);
    widget.onCancel?.call();
  }
}
