class ResetPasswordModel {
  final String email;
  final String password;
  final String confirmPassword;
  final String otp;

  ResetPasswordModel({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'confirmPassword': confirmPassword,
    'otp': otp,
  };
}
