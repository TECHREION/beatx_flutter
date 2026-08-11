
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
        );

        debugPrint("login response [${response.statusCode}]: ${response.data}");

        // final body = response.data is Map
        //     ? Map<String, dynamic>.from(response.data as Map)
        //     : <String, dynamic>{};

        // final data = body['data'] is Map
        //     ? Map<String, dynamic>.from(body['data'] as Map)
        //     : <String, dynamic>{};

        // final accessToken = (data['accessToken'] ?? '').toString();
        // final refreshToken = (data['refreshToken'] ?? '').toString();

        // // Backend returns no user object — decode from JWT
        // // final claims = _jwtClaims(accessToken);
        // // final uid = (claims['sub'] ?? '').toString();
        // // final email = (claims['email'] ?? params.email).toString();
        // // final role = (claims['role'] ?? 'user').toString();

        // await appPigeon.saveNewAuth(
        //   saveAuthParams: SaveNewAuthParams(
        //     uid: uid,
        //     accessToken: accessToken,
        //     refreshToken: refreshToken,
        //     data: {
        //       'userId': uid,
        //       'email': email,
        //       'role': role,
        //       'name': '',
        //       'preferredLanguage': params.preferredLanguage,
        //     },
        //   ),
        // );

        // if (Get.isRegistered<AppLanguageController>()) {
        //   await Get.find<AppLanguageController>().syncFromBackendValue(
        //     params.preferredLanguage,
        //   );
        // }
        final body = extractBodyData(response);
        debugPrint(body.toString());

        final accessToken = (body["accessToken"] ?? '').toString();
        final refreshToken = (body["refreshToken"] ?? '').toString();
        final role = (body['role'] ?? 'user').toString();

        // Backend returns no user object — use the email the user logged in with
        await appPigeon.saveNewAuth(
          saveAuthParams: SaveNewAuthParams(
            uid: params.email,
            accessToken: accessToken,
            refreshToken: refreshToken,
            data: {
              "email": params.email,
              "role": role,
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
          data: params.toMap(),
        );

        // debugPrint("Signup response: ${response.data}");

        // final body = response.data is Map
        //     ? Map<String, dynamic>.from(response.data as Map)
        //     : <String, dynamic>{};

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

        // debugPrint("verifyEmail response: ${response.data}");

        // final body = response.data is Map
        //     ? Map<String, dynamic>.from(response.data as Map)
        //     : <String, dynamic>{};

        // final data = body['data'] is Map
        //     ? Map<String, dynamic>.from(body['data'] as Map)
        //     : <String, dynamic>{};

        // final accessToken = (data['accessToken'] ?? '').toString();
        // final refreshToken = (data['refreshToken'] ?? '').toString();

        // if (accessToken.isNotEmpty) {
        //   final claims = _jwtClaims(accessToken);
        //   final uid = (claims['sub'] ?? '').toString();
        //   final email = (claims['email'] ?? param.email).toString();
        //   final role = (claims['role'] ?? 'user').toString();

        //   await appPigeon.saveNewAuth(
        //     saveAuthParams: SaveNewAuthParams(
        //       uid: uid,
        //       accessToken: accessToken,
        //       refreshToken: refreshToken,
        //       data: {
        //         'userId': uid,
        //         'email': email,
        //         'role': role,
        //         'name': '',
        //         'preferredLanguage': 'en',
        //       },
        //     ),
        //   );
        // }

        return Success(message: extractSuccessMessage(response));
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
        // final body = response.data is Map
        //     ? Map<String, dynamic>.from(response.data as Map)
        //     : <String, dynamic>{};
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
        await appPigeon.logOut();
        return Success(message: extractSuccessMessage(response));
      },
    );
  }
}
