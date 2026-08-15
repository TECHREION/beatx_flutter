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
  static String audiobookStreamUrl({required String audiobookId, required String chapterId}) =>
      _Audiobook._audiobookStreamUrl(audiobookId, chapterId);
  
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
  static String likesong({required String songId}) =>_Listen._likesong(songId);
  static const String getLikesong = _Listen.getLikesong;

  //---------------------- podcast -----------------------------
  static const String podcastHome = _Podcast.podcastHome;
  static String podcastDetails({required String podcastId}) =>
      _Podcast._podcastDetails(podcastId);
  static String podcastEpisodes({required String podcastId}) =>
      _Podcast._podcastEpisodes(podcastId);
  static String episodeDetails({required String episodeId}) =>
      _Podcast._episodeDetails(episodeId);
  static String getStreamUrl({required String episodeId}) =>
      _Podcast._getStreamUrl(episodeId);
  static String saveProgress({required String episodeId}) =>
      _Podcast._saveProgress(episodeId);
  static String searchCategory({required String categoryId}) =>
      _Podcast._searchCategory(categoryId);
      
  static String likpodcast({required String podcastid}) =>_Podcast._likesong(podcastid);
  static const String getLikepodcast = _Podcast.getLikesong;
}


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
  static const String forgetPassword = '$_authRoute/forgot-password';
  static const String refreshToken = '$_authRoute/refresh-token';
  static const String verifyCode = '$_authRoute/verify-otp';
  static const String resetPassword = '$_authRoute/reset-password';
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
  static String _audiobookStreamUrl(String audiobookId, String chapterId) =>
      '$_audiobookRoute/$audiobookId/stream/$chapterId';
}

// ---------------------- watch -----------------------------
class _Video {
  static const String videoRoute = '${ApiEndpoints.baseUrl}/videos';
  static const String videoHome = '$videoRoute/home';
  static String _videoDetails(String videoId) =>
      '$videoRoute/$videoId';
  static String _videoStreamUrl(String videoId) =>
      '$videoRoute/$videoId/stream';
  static String _relatedVideos(String videoId) =>
      '$videoRoute/$videoId/related';
  static String _likeUnlike(String videoId) =>
      '$videoRoute/$videoId/like';
}

// ---------------------- Listen/Home -----------------------------
class _Listen {
  static const String listen = '${ApiEndpoints.baseUrl}/songs';
  static const String listenHome = '$listen/home';
  static String _listenDetails(String listenId) =>
      '$listen/$listenId';
  static String _listenStreamUrl(String listenId) =>
      '$listen/$listenId/stream';
  static String _likesong(String songId) =>
      '$listen/$songId/like';
  static const String getLikesong = '$listen/liked';
}

// ---------------------- podcast -----------------------------
class _Podcast {
  static const String podcastRoute = '${ApiEndpoints.baseUrl}/podcasts';
  static const String podcastHome = '$podcastRoute/home';
  static String _podcastDetails(String podcastId) =>
      '$podcastRoute/$podcastId';
  static String _episodeDetails(String episodeId) =>
      '$podcastRoute/episodes/$episodeId';
  static String _getStreamUrl(String episodeId) =>
      '$podcastRoute/episodes/$episodeId/stream';
  static String _podcastEpisodes(String podcastId) =>
      '$podcastRoute/$podcastId/episodes';
  static String _saveProgress(String episodeId) =>
      '$podcastRoute/episodes/$episodeId/progress';
  static String _searchCategory(String categoryId) =>
      '$podcastRoute/search?category=${Uri.encodeQueryComponent(categoryId)}';
  static String _likesong(String podcastid) =>
      '$podcastRoute/$podcastid/like';
  static const String getLikesong = '$podcastRoute/liked';
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
