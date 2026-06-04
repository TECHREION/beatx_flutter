import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/core/network/app_language_options.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';
import 'package:beatx_flutter/module/profile/services/profile_interface.dart';

final class ProfileInterfaceImpl extends ProfileInterface {
  final AuthorizedPigeon appPigeon;

  ProfileInterfaceImpl(this.appPigeon);

  @override
  FutureRequest<Success> updateProfile(ProfileModel params) {
    return asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.patch(
          ApiEndpoints.updateProfile,
          data: FormData.fromMap(await params.toFormMap()),
          options: appLanguageOptions(),
        );

        return Success(
          message: extractSuccessMessage(response) ?? 'Profile updated',
        );
      },
    );
  }
}
