import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api_handler/failure.dart';
import '../../controller/get_profile_controller.dart';
import '../../services/profile_interface.dart';
import '../../services/profile_interface_impl.dart';

/// Confirms and performs `DELETE /users/me`.
///
/// Password accounts confirm with their password (a wrong one is 403 and
/// keeps the user signed in). Phone and social accounts have no password and
/// confirm by typing DELETE, which is sent as `{confirm: "DELETE"}`.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => const DeleteAccountDialog(),
  );

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _input = TextEditingController();
  late final bool _usesPassword = ProfileController.instance.hasPassword;
  bool _busy = false;
  bool _obscure = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_busy) return false;
    final text = _input.text;
    return _usesPassword ? text.isNotEmpty : text.trim() == 'DELETE';
  }

  ProfileInterface _interface() {
    if (!Get.isRegistered<ProfileInterface>()) {
      Get.put<ProfileInterface>(
        ProfileInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<ProfileInterface>();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _error = '';
    });

    final result = await _interface().deleteAccount(
      password: _usesPassword ? _input.text : null,
    );
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          _busy = false;
          _error = failure.failure == Failure.forbidden
              ? 'Incorrect password.'
              : failure.uiMessage;
        });
      },
      (_) async {
        Navigator.of(context).pop();
        // The account is gone: clear the session; the app returns to sign-in.
        await Get.find<AuthorizedPigeon>().logOut();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Delete account?',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account, library and downloads. '
            'It cannot be undone.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            obscureText: _usesPassword && _obscure,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: _usesPassword ? 'Your password' : 'Type DELETE',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _usesPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_error, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: _canSubmit ? _submit : null,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.redAccent,
                  ),
                )
              : Text(
                  'Delete',
                  style: TextStyle(
                    color: _canSubmit ? Colors.redAccent : Colors.white24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}
