import 'package:beatx_flutter/module/auth/services/auth_interface.dart';
import 'package:flutter/material.dart';
import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart' hide FormData;
import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/helpers/typedefs.dart';
import '../../../core/localization/app_language_controller.dart';
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
          options: appLanguageOptions(),
        );

        debugPrint("login response: ${response.data}");

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        final loginResponse = LoginResponse.fromMap(body);
        if (Get.isRegistered<AppLanguageController>()) {
          await Get.find<AppLanguageController>().syncFromBackendValue(
            loginResponse.preferredLanguage,
          );
        }

        await appPigeon.saveNewAuth(
          saveAuthParams: SaveNewAuthParams(
            uid: loginResponse.userId,
            accessToken: loginResponse.accessToken,
            refreshToken: loginResponse.refreshToken,
            data: {
              "userId": loginResponse.userId,
              "name": loginResponse.name,
              "email": loginResponse.email,
              "role": loginResponse.role,
              "preferredLanguage": loginResponse.preferredLanguage,
            },
          ),
        );

        return Success(message: body['message'] ?? 'Login successful');
      },
    );
  }

  @override
  FutureRequest<Success> signup(SignupModel params) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.post(
          ApiEndpoints.signup,
          data: FormData.fromMap(params.toMap()),
          options: appLanguageOptions(),
        );

        debugPrint("Signup response: ${response.data}");

        final body = response.data;
        final signupResponse = SignupResponse.fromMap(
          body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
        );

        final signupUser = signupResponse.data?.user;
        final accessToken = signupResponse.data?.accessToken ?? '';
        if (signupUser != null && accessToken.isNotEmpty) {
          if (Get.isRegistered<AppLanguageController>()) {
            await Get.find<AppLanguageController>().syncFromBackendValue(
              signupUser.preferredLanguage,
            );
          }
          await appPigeon.saveNewAuth(
            saveAuthParams: SaveNewAuthParams(
              uid: signupUser.id,
              accessToken: accessToken,
              refreshToken: '',
              data: {
                "userId": signupUser.id,
                "name": signupUser.fullName.isNotEmpty
                    ? signupUser.fullName
                    : signupUser.firstName,
                "email": signupUser.email,
                "role": signupUser.role,
                "preferredLanguage": signupUser.preferredLanguage,
              },
            ),
          );
        }

        // success returned from server
        return Success(
          message: signupResponse.message.isNotEmpty
              ? signupResponse.message
              : 'Signup successful',
        );
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
        await appPigeon.logOut();
        return Success(message: extractSuccessMessage(response));
      },
    );
  }
}
