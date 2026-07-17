import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/core/network/app_language_options.dart';
import 'package:beatx_flutter/module/profile/model/change_password_model.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';

import '../model/update_profile_model.dart';

final class ProfileInterfaceImpl extends ProfileInterface {
  final AuthorizedPigeon appPigeon;

  ProfileInterfaceImpl(this.appPigeon);

  @override
  FutureRequest<UserProfileModel> getProfile() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(ApiEndpoints.getuserbyId);

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        return UserProfileModel.fromMap(data);
      },
    );
  }

  @override
  FutureRequest<Success<UpdateProfileResponse>> updateProfile(
    UserUpdateProfile params,
  ) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.patch(
          ApiEndpoints.updateProfile,
          data: FormData.fromMap(await params.toFormMap()),
          options: appLanguageOptions(),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        final updateResponse = UpdateProfileResponse.fromJson(body);

        return Success<UpdateProfileResponse>(
          message: updateResponse.message.isEmpty
              ? 'Profile updated'
              : updateResponse.message,
          data: updateResponse,
        );
      },
    );
  }

  @override
  FutureRequest<Success<ChangePasswordResponse>> changePassword(
    ChangePasswordRequest params,
  ) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.patch(
          ApiEndpoints.changePassword,
          data: params.toJson(),
          options: appLanguageOptions(),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        final changePasswordResponse = ChangePasswordResponse.fromJson(body);

        return Success<ChangePasswordResponse>(
          message: changePasswordResponse.message.isEmpty
              ? 'Password changed successfully'
              : changePasswordResponse.message,
          data: changePasswordResponse,
        );
      },
    );
  }
}
