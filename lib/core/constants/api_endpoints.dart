// ignore_for_file: unused_element, unused_field

import 'package:flutter/foundation.dart';

base class ApiEndpoints {
  static const String socketUrl = _LocalHostWifi.socketUrl;
  static const String baseUrl = _LocalHostWifi.baseUrl;

  /// ### post
  static const String login = _Auth.login;
  static const String logout = _Auth.logout;
  static const String socialLogin = _Auth.socialLogin;
  static const String signup = _Auth.signup;
  static const String emailVerification = _Auth.emailVerification;
  static const String verifyCode = _Auth.verifyCode;
  static const String verifyEmail = _Auth.emailVerification;
  static const String resendEmailOtp = _Auth.resendEmailOtp;
  static const String forgetPassword = _Auth.forgetPassword;
  static const String createNewPassword = _Auth.resetPassword;
  static const String refreshToken = _Auth.refreshToken;

  // ---------------------- USER -----------------------------
  /// ### get
  static String getuserbyId = _User.getuserbyId;
  static String updateProfile = _User.updateProfile;
  static String changePassword = _User.changePassword;
  static String userPreferences = _User.preferences;

  //---------------------- Audiobook -----------------------------
  static const String audiobookhome = _Audiobook.audiobookhome;
  static String audiobookDetails({required String audiobookId}) =>
      _Audiobook._audiobookDetails(audiobookId);
  
  //----------------------- watch -----------------------------
  static const String videoHome = _Video.videoHome;
  static String videoDetails({required String videoId}) =>
      _Video._videoDetails(videoId);
  static String videoStreamUrl({required String videoId}) =>
      _Video._videoStreamUrl(videoId);
  static String relatedVideos({required String videoId}) =>
      _Video._relatedVideos(videoId);
  static String likeUnlike({required String videoId}) =>
      _Video._likeUnlike(videoId);

  //---------------------- home/listen -----------------------------
  static const String listenHome = _Listen.listenHome;
  static String listenDetails({required String listenId}) =>
      _Listen._listenDetails(listenId);
  static String listenStreamUrl({required String listenId}) =>
      _Listen._listenStreamUrl(listenId);
}

//arrow360degree@gmail.com

// class _RemoteServer {
//   static const String socketUrl =
//       'https://backend-mattiaiarriccio.onrender.com';

//   static const String baseUrl =
//       'https://backend-mattiaiarriccio.onrender.com/api/v1';
// }

class _LocalHostWifi {
  static const String socketUrl = 'http://13.200.168.40:3000/';
  static const String baseUrl = 'http://13.200.168.40:3000/api/v1';
}

class _Auth {
  @protected
  static const String _authRoute = '${ApiEndpoints.baseUrl}/auth';
  static const String login = '$_authRoute/login';
  static const String logout = '$_authRoute/logout';
  static const String socialLogin = '$_authRoute/social-login';
  static const String signup = '$_authRoute/register';
  static const String emailVerification = '$_authRoute/verify-email';
  static const String forgetPassword = '$_authRoute/password-reset/request';
  static const String refreshToken = '$_authRoute/refresh-token';
  static const String verifyCode = '$_authRoute/password-reset/verify';
  static const String resetPassword = '$_authRoute/password-reset/reset';
  static const String resendEmailOtp = '$_authRoute/resend-verification';
}

//------------------------------ User -----------------------------
class _User {
  static const String _userRoute = '${ApiEndpoints.baseUrl}/users';
  static String getuserbyId = '$_userRoute/me';
  static String updateProfile = '$_userRoute/profile';
  static String changePassword = '$_userRoute/change-password';
  static String preferences = '$_userRoute/me/preferences';
}

//------------------------------ Audiobook -----------------------------
class _Audiobook {
  static const String _audiobookRoute = '${ApiEndpoints.baseUrl}/audiobooks';
  static const String audiobookhome = '$_audiobookRoute/home';
  static String _audiobookDetails(String audiobookId) =>
      '$_audiobookRoute/$audiobookId';
}

// ---------------------- watch -----------------------------
class _Video {
  static const String videoRoute = '${ApiEndpoints.baseUrl}/videos';
  static const String videoHome = '$videoRoute/home';
  static String _videoDetails(String videoId) =>
      '$videoRoute/$videoId';
  static String _videoStreamUrl(String videoId) =>
      '${_videoDetails(videoId)}/stream';
  static String _relatedVideos(String videoId) =>
      '${_videoDetails(videoId)}/related';
  static String _likeUnlike(String videoId) =>
      '${_videoDetails(videoId)}/like';
}

// ---------------------- Listen/Home -----------------------------
class _Listen {
  static const String listen = '${ApiEndpoints.baseUrl}/songs';
  static const String listenHome = '$listen/home';
  static String _listenDetails(String listenId) =>
      '$listen/$listenId';
  static String _listenStreamUrl(String listenId) =>
      '${_listenDetails(listenId)}/stream';
}

// ---------------------- Notification -----------------------------
class _Notification {}

class _Checklist {}

//---------------------- Safety Tips -----------------------------
class _SafetyTips {}

//-----------------------chat----------------
class _Chat {}

// ---------------------- Products -----------------------------
class _Product {}

class _Search {}

class _Filter {}

//---------------------- Category -----------------------------
class _Category {}

//---------------------- Cart -----------------------------
class _Cart {}

//---------------------- Shop -----------------------------
class _Shop {}

//---------------------- Order -----------------------------
class _Order {}

//---------------------- Review -----------------------------
class _Review {}

//---------------------- WishList -----------------------------
class _WishList {}

//----------------------Message -----------------------------
class _Messaging {}

class _Supplier {}

class _Service {}

class _Banner {}
