import 'package:beatx_flutter/core/common/widget/reactive_button/save_button.dart';
import 'package:beatx_flutter/core/notifiers/button_status_notifier.dart';
import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  final currentPasswordController =
      TextEditingController();
  final newPasswordController =
      TextEditingController();
  final confirmPasswordController =
      TextEditingController();
  final _saveButtonStatus = ProcessStatusNotifier(
    initialStatus: EnabledStatus(),
  );

  static const LinearGradient buttonGradient =
      LinearGradient(
    colors: [
      Color(0xFF9BFF4D),
      Color(0xFF40DDEB),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _saveButtonStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050608),
      body: Stack(
        children: [
          /// Purple Glow
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
                    Colors.deepPurple.withOpacity(.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// Cyan Glow
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.cyan.withOpacity(.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  /// Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.06),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  /// Current Password
                  const _LabelText(
                    title: "Current Password",
                  ),

                  const SizedBox(height: 10),

                  _passwordField(
                    controller:
                        currentPasswordController,
                    obscureText: obscureCurrent,
                    onToggle: () {
                      setState(() {
                        obscureCurrent =
                            !obscureCurrent;
                      });
                    },
                  ),

                  const SizedBox(height: 22),

                  /// New Password
                  const _LabelText(
                    title: "New Password",
                  ),

                  const SizedBox(height: 10),

                  _passwordField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    onToggle: () {
                      setState(() {
                        obscureNew = !obscureNew;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  /// Password Rules
                  const _PasswordRule(
                    text: "8 characters",
                  ),

                  const SizedBox(height: 8),

                  const _PasswordRule(
                    text:
                        "contain number, and upper-case letter",
                  ),

                  const SizedBox(height: 22),

                  /// Confirm Password
                  const _LabelText(
                    title: "Confirm Password",
                  ),

                  const SizedBox(height: 10),

                  _passwordField(
                    controller:
                        confirmPasswordController,
                    obscureText: obscureConfirm,
                    onToggle: () {
                      setState(() {
                        obscureConfirm =
                            !obscureConfirm;
                      });
                    },
                  ),

                  const SizedBox(height: 36),

                  RSaveButton(
                    key: const ValueKey('change-password-save-button'),
                    height: 58,
                    borderRadius: BorderRadius.circular(30),
                    activeGradient: buttonGradient,
                    buttonStatusNotifier: _saveButtonStatus,
                    saveText: 'Save Changes',
                    doneText: 'Saved',
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    onSaveTap: _savePassword,
                    onDone: _showSavedMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.white70,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white54,
            ),
          ),
          hintText: "••••••••",
          hintStyle: const TextStyle(
            color: Colors.white54,
          ),
        ),
      ),
    );
  }

  void _savePassword() {
    _saveButtonStatus.setSuccess();
  }

  void _showSavedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated')),
    );
    _saveButtonStatus.setEnabled();
  }
}

class _LabelText extends StatelessWidget {
  final String title;

  const _LabelText({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _PasswordRule extends StatelessWidget {
  final String text;

  const _PasswordRule({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check,
          size: 18,
          color: Color(0xFF00F5A0),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF00F5A0),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
