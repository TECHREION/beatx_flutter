import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';
import '../constants/api_endpoints.dart';

void externalServiceDI() {
  // Initialize other external services here
  final appPigeon = AuthorizedPigeon(
    MyRefreshTokenManager(),
    baseUrl: ApiEndpoints.baseUrl,
  );
  Get.put<AuthorizedPigeon>(appPigeon);
  Get.put<AppPigeon>(appPigeon);
}

class MyRefreshTokenManager implements RefreshTokenManagerInterface {
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
    final res = await dio.post(url, data: {'refreshToken': refreshToken});

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
    if (err.requestOptions.path.contains('/auth/refresh-token')) {
      return false;
    }

    final message = _extractMessage(err.response?.data).toLowerCase();

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
