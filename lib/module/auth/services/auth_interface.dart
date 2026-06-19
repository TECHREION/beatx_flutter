import 'package:dartz/dartz.dart';
import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/failure.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/create_new_password_model.dart';
import '../model/forget_password_model.dart';
import '../model/login_request_model.dart';
import '../model/signup_model.dart';
import '../model/verify_account_param.dart';
import '../model/verify_otp_param.dart';

abstract base class AuthInterface extends BaseRepository {
  FutureRequest<Success> login(LoginRequestModel params);

  FutureRequest<Success> signup(SignupModel params);

  FutureRequest<Success> forgetpassword(ForgetPasswordModel email);

  FutureRequest<Success> verifyAccount(VerifyAccountParam params);

  FutureRequest<Success> verifyCode(VerifyOtpParam param);

  FutureRequest<Success> verifyEmail(VerifyOtpParam param);

  FutureRequest<Success> resendEmailOtp(String email);

  FutureRequest<Success> resetPassword(ResetPasswordModel params);

  // FutureRequest<Success> changePassword(ChangePasswordModel param);

  Future<Either<DataCRUDFailure, Success>> logout();

  FutureRequest<Success> googleLogin();

  FutureRequest<Success> facebookLogin();

  FutureRequest<Success> appleLogin();
}
