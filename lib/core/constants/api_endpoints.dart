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

  /// `GET` reads the settings, `PATCH` writes them back.
  static String userSettings = _User.settings;

  //=======================genre/artist========================
  static const String genre = _Genre.getallgenre;
  static const String genreSearch = _Genre.genreSearch;

  //---------------------- Audiobook -----------------------------
  static const String audiobookhome = _Audiobook.audiobookhome;
  static String audiobookDetails({required String audiobookId}) =>
      _Audiobook._audiobookDetails(audiobookId);
  static String audiobookStreamUrl({required String audiobookId, required String chapterId}) =>
      _Audiobook._audiobookStreamUrl(audiobookId, chapterId);
  static String likaudiobook({required String audiobookId}) =>_Audiobook._likeAudibook(audiobookId);
  static const String getLikedAudiobooks= _Audiobook.getLikedAudiobooks;
  static const String searchAudiobook = _Audiobook.searchAudiobook;
  
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
  static const String searchVideo = _Video.searchVideo;
  static String videoProgress({required String videoId}) => _Video._videoProgress(videoId);

  //---------------------- home/listen -----------------------------
  static const String listenHome = _Listen.listenHome;
  static String listenDetails({required String listenId}) =>
      _Listen._listenDetails(listenId);
  static String listenStreamUrl({required String listenId}) =>
      _Listen._listenStreamUrl(listenId);
  static String likesong({required String songId}) =>_Listen._likesong(songId);
  static const String getLikesong = _Listen.getLikesong;
  static String recentlyPlayed({required String userId}) =>
      _Listen._recentlyPlayed(userId);
  static const String onRepeatedSong = _Listen._onRepeatedSong;
  static const String searchSong = _Listen._searchSong;
  static const String dailyDiscover = _Listen.dailyDiscover;

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
  static String searchPodcast({
    required String query,
    required String genreId,
    required int page,
    required int limit,
  }) => _Podcast._searchPodcast(query, genreId, page, limit);
  static String likpodcast({required String podcastid}) =>_Podcast._likesong(podcastid);
  static const String getLikepodcast = _Podcast.getLikesong;

  //---------------------- Notification -----------------------------
  /// ### get
  static String notifications({int page = 1, int limit = 30}) =>
      _Notification._list(page, limit);

  /// ### patch
  static String markNotificationRead({required String notificationId}) =>
      _Notification._markRead(notificationId);
  static const String markAllNotificationsRead = _Notification.markAllRead;
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
  static const String refreshToken = '$_authRoute/refresh';
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
  static String settings = '$_userRoute/settings';
}
// /=======================genre/artist========================
class _Genre {
  static const String _genreRoute = '${ApiEndpoints.baseUrl}/genre';
  static const String getallgenre = '$_genreRoute/';
  static const String genreSearch = '$_genreRoute/search';
}

//------------------------------ Audiobook -----------------------------
class _Audiobook {
  static const String _audiobookRoute = '${ApiEndpoints.baseUrl}/audiobooks';
  static const String audiobookhome = '$_audiobookRoute/home';
  static String _audiobookDetails(String audiobookId) =>
      '$_audiobookRoute/$audiobookId';
  static String _audiobookStreamUrl(String audiobookId, String chapterId) =>
      '$_audiobookRoute/$audiobookId/stream/$chapterId';
  static String _likeAudibook(String audiobookId) =>
      '$_audiobookRoute/$audiobookId/like';
  static const String getLikedAudiobooks = '$_audiobookRoute/liked';
  static const String searchAudiobook = '$_audiobookRoute/search';
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
  static const String searchVideo = '$videoRoute/search';
  static String _videoProgress(String videoId) => '$videoRoute/$videoId/progress';
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
  static const String _searchSong = '$listen/search';
  static String _recentlyPlayed(String userId) => '$listen/recently-played';
  static const String _onRepeatedSong = '$listen/on-repeat';
  static const String searchSong = '$listen/search';
  static const String dailyDiscover = '$listen/daily-discovery';
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

  /// One page of `/podcasts/search`.
  ///
  /// The filter here is `category`, not the `genre` the song, video and
  /// audiobook routes take — this route rejects `genre` outright, and podcast
  /// category ids are their own set rather than the ids `/genre` hands out.
  /// An unset filter or name is left off rather than sent blank, which the
  /// route treats as matching nothing.
  static String _searchPodcast(
    String query,
    String categoryId,
    int page,
    int limit,
  ) {
    return Uri.parse('$podcastRoute/search').replace(
      queryParameters: <String, String>{
        if (query.isNotEmpty) 'q': query,
        if (categoryId.isNotEmpty) 'category': categoryId,
        'page': '$page',
        'limit': '$limit',
      },
    ).toString();
  }
  static String _likesong(String podcastid) =>
      '$podcastRoute/$podcastid/like';
  static const String getLikesong = '$podcastRoute/liked';
}

// ---------------------- Notification -----------------------------
class _Notification {
  static const String notificationRoute = '${ApiEndpoints.baseUrl}/notifications';

  static String _list(int page, int limit) =>
      Uri.parse(notificationRoute).replace(
        queryParameters: <String, String>{'page': '$page', 'limit': '$limit'},
      ).toString();

  static String _markRead(String notificationId) =>
      '$notificationRoute/$notificationId/read';
  static const String markAllRead = '$notificationRoute/read-all';
}

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
