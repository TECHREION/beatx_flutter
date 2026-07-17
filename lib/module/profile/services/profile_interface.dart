import 'package:beatx_flutter/core/api_handler/base_repository.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';

import '../model/change_password_model.dart';
import '../model/update_profile_model.dart';

abstract base class ProfileInterface extends BaseRepository {
  FutureRequest<UserProfileModel> getProfile();

  FutureRequest<Success<UpdateProfileResponse>> updateProfile(
    UserUpdateProfile params,
  );
  FutureRequest<Success<ChangePasswordResponse>> changePassword(
    ChangePasswordRequest params,
  );
}
