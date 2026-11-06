import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../constants/api_endpoints.dart';
import '../network/beatx_pigeon.dart';

void externalServiceDI() {
  // Initialize other external services here
  final appPigeon = BeatxPigeon(
    MyRefreshTokenManager(),
    baseUrl: ApiEndpoints.baseUrl,
  );
  Get.put<AuthorizedPigeon>(appPigeon);
  Get.put<AppPigeon>(appPigeon);
}

class MyRefreshTokenManager implements RefreshTokenManagerInterface {
  MyRefreshTokenManager({
    Future<String?> Function()? currentAccessToken,
    Future<void> Function()? signOut,
  }) : _currentAccessToken = currentAccessToken ?? _storedAccessToken,
       _signOut = signOut ?? _signOutCurrentUser;

  final Future<String?> Function() _currentAccessToken;
  final Future<void> Function() _signOut;

  static Future<String?> _storedAccessToken() async {
    final auth = await Get.find<AuthorizedPigeon>().getCurrentAuthRecord();
    return auth?.toJson()['access_token'] as String?;
  }

  static Future<void> _signOutCurrentUser() =>
      Get.find<AuthorizedPigeon>().logOut();

  @override
  final String url = ApiEndpoints.refreshToken;

  String _extractMessage(dynamic body) {
    if (body is Map) {
      final message = body['message'];
      if (message != null) return message.toString();
    }
    return '';
  }

  @override
  Future<RefreshTokenResponse> refreshToken({
    required String refreshToken,
    required Dio dio,
  }) async {
    final Response<dynamic> res;
    try {
      res = await dio.post(url, data: {'refreshToken': refreshToken});
    } on DioException catch (error) {
      // The package clears the session whenever this throws, but during
      // maintenance the refresh route answers 503 and the session is still
      // good. Handing the current tokens back keeps the user signed in; the
      // request that triggered this simply fails until maintenance ends.
      final current = await _currentAccessToken();
      if (error.response?.statusCode == 503 &&
          current != null &&
          current.isNotEmpty) {
        return RefreshTokenResponse(
          accessToken: current,
          refreshToken: refreshToken,
        );
      }
      rethrow;
    }
    debugPrint('refresh response [${res.statusCode}]: ${res.data}');

    if (res.data is! Map || res.data['data'] is! Map) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Invalid refresh response format',
      );
    }

    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    final accessToken = (data['accessToken'] ?? '').toString();
    final nextRefreshToken = (data['refreshToken'] ?? refreshToken).toString();

    if (accessToken.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Missing refreshed access token',
      );
    }

    return RefreshTokenResponse(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
      // Left null on purpose: the storage keeps the record's existing data
      // when this is null, and the refresh payload does not carry the
      // email/role that was saved at login.
      data: data,
    );
  }

  @override
  Future<bool> shouldRefresh(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) return false;

    // Never refresh for refresh endpoint failures themselves.
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return false;
    }

    final message = _extractMessage(err.response?.data).toLowerCase();

    // The account itself is gone or blocked: a new token cannot help, and the
    // API asks clients to sign the user out.
    if (message.contains('has been banned') ||
        message.contains('is suspended') ||
        message.contains('no longer exists')) {
      await _signOut();
      return false;
    }

    // Permission/business 401 should not trigger refresh retry loops.
    if (message.contains('not authorized') ||
        message.contains('not allowed') ||
        message.contains('access denied') ||
        message.contains('forbidden')) {
      return false;
    }

    // Token/auth related 401 should refresh.
    if (message.contains('invalid token') ||
        message.contains('token not found') ||
        message.contains('token expired') ||
        message.contains('jwt')) {
      return true;
    }

    // Fallback: for unknown 401 payloads, try refreshing once.
    return true;
  }
}
