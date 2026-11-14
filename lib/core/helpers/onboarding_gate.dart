/// Whether the listener who just signed in still has to see onboarding.
///
/// `POST /auth/login`, `/auth/verify-email` and `/auth/phone/verify` report
/// `onboardingCompleted` for listener accounts. It is only known at the moment
/// of sign-in, so the auth service records it here and the app manager reads it
/// once, when the signed-in status arrives, to pick onboarding or home.
class OnboardingGate {
  OnboardingGate._();

  static bool _pending = false;

  /// Records the sign-in response. Only an explicit `false` asks for
  /// onboarding — artists and admins do not get the field at all.
  static void recordSignIn(Map<String, dynamic> body) {
    _pending = body['onboardingCompleted'] == false;
  }

  /// True once after a sign-in whose account has not finished onboarding.
  static bool takePending() {
    final pending = _pending;
    _pending = false;
    return pending;
  }

  /// Forgets a recorded sign-in, e.g. on sign-out.
  static void clear() => _pending = false;
}
