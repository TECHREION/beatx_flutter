import 'package:beatx_flutter/core/api_handler/base_repository.dart';
import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';

import '../model/change_password_model.dart';
import '../model/update_profile_model.dart';

abstract base class ProfileInterface extends BaseRepository {
  FutureRequest<Success<UserProfileModel>> getProfile();

  /// Saves the name and, when one was picked, the avatar. Answers with the
  /// updated user.
  FutureRequest<Success<UserProfileModel>> updateProfile(
    UserUpdateProfile params,
  );

  FutureRequest<Success<ChangePasswordResponse>> changePassword(
    ChangePasswordRequest params,
  );

  /// The user's settings, behind `GET /users/settings`.
  FutureRequest<Success<ProfileSettings>> getSettings();

  /// Writes the settings back whole — the endpoint takes every field, not
  /// just the changed one — and answers with what it saved.
  FutureRequest<Success<ProfileSettings>> updateSettings(
    ProfileSettings settings,
  );
}
