import 'package:beatx_flutter/module/auth/services/auth_interface.dart';
import 'package:flutter/material.dart';
import 'package:app_pigeon/app_pigeon.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/helpers/onboarding_gate.dart';
import '../../../core/helpers/typedefs.dart';
import '../../../core/network/app_language_options.dart';
import '../model/create_new_password_model.dart';
import '../model/forget_password_model.dart';
import '../model/login_request_model.dart';
import '../model/signup_model.dart';
import '../model/verify_account_param.dart';

final class AuthInterfaceImpl extends AuthInterface {
  final AuthorizedPigeon appPigeon;
  AuthInterfaceImpl(this.appPigeon);

  Stream<AuthStatus> authStream() {
    return appPigeon.authStream;
  }

  @override
  FutureRequest<Success> login(LoginRequestModel params) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.login,
          data: params.toJson(),
        );
        await _saveSession(response, uid: params.email.trim().toLowerCase());
        return Success(
          message: extractSuccessMessage(response) ?? 'Login successful',
        );
      },
    );
  }

  /// Stores the tokens a sign-in response carries.
  ///
  /// Login, email verification and phone verification all answer
  /// `{accessToken, refreshToken, role, onboardingCompleted?, ...}`. Saving
  /// them signs the user in: the auth stream emits and the app manager routes
  /// to onboarding or home.
  Future<void> _saveSession(Response response, {required String uid}) async {
    final raw = extractBodyData(response);
    final body = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final accessToken = (body['accessToken'] ?? '').toString();
    final refreshToken = (body['refreshToken'] ?? '').toString();
    if (accessToken.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Missing access token in sign-in response',
      );
    }

    // Read before the save: saving emits the signed-in status at once.
    OnboardingGate.recordSignIn(body);

    await appPigeon.saveNewAuth(
      saveAuthParams: SaveNewAuthParams(
        uid: uid,
        accessToken: accessToken,
        refreshToken: refreshToken,
        data: {'email': uid, 'role': (body['role'] ?? 'user').toString()},
      ),
    );
  }

  @override
  FutureRequest<Success> signup(SignupModel params) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.signup,
          data: params.toMap(),
        );
        return Success(message: extractSuccessMessage(response));
      },
    );
  }

  @override
  FutureRequest<Success> forgetpassword(ForgetPasswordModel email) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.forgetPassword,
          data: email.toJson(),
          options: appLanguageOptions(),
        );
        debugPrint("Forget password response: ${response.data}");
        return Success(message: extractSuccessMessage(response));
      },
    );
  }

  @override
  FutureRequest<Success> resetPassword(ResetPasswordModel params) async {
    return await asyncTryCatch(
      tryFunc: () async {
        debugPrint("Reset password params: ${params.toJson()}");
        final response = await appPigeon.post(
          ApiEndpoints.createNewPassword,
          data: params.toJson(),
          options: appLanguageOptions(),
        );
        return Success(message: extractSuccessMessage(response));
      },
    );
  }

  @override
  FutureRequest<Success> verifyAccount(VerifyAccountParam params) {
    throw UnimplementedError();
  }

  @override
  FutureRequest<Success> verifyCode(param) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.verifyCode,
          data: param.toJson(),
          options: appLanguageOptions(),
        );
        final body = response.data;
        return Success(message: body['message'] ?? 'OTP verified');
      },
    );
  }

  @override
  FutureRequest<Success> verifyEmail(param) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.verifyEmail,
          data: param.toJson(),
        );
        // A verified email signs the account in: the response carries the
        // same tokens as `/auth/login`.
        await _saveSession(response, uid: param.email.trim().toLowerCase());
        return Success(
          message: extractSuccessMessage(response) ?? 'Email verified',
        );
      },
    );
  }

  @override
  FutureRequest<Success> resendEmailOtp(String email) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.resendEmailOtp,
          data: {'email': email},
        );
        return Success(message: extractSuccessMessage(response));
      },
    );
  }

  @override
  FutureRequest<Success> appleLogin() async {
    throw UnimplementedError();
  }

  @override
  FutureRequest<Success> facebookLogin() async {
    throw UnimplementedError();
  }

  @override
  FutureRequest<Success> googleLogin() async {
    throw UnimplementedError();
  }

  @override
  FutureRequest<Success> logout() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.logout,
          options: appLanguageOptions(),
        );
        debugPrint('LOGOUT RESPONSE => ${response.data}');
        OnboardingGate.clear();
        await appPigeon.logOut();
        return Success(message: extractSuccessMessage(response));
      },
    );
  }
}
