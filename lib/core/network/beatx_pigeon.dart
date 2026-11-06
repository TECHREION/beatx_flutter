import 'package:app_pigeon/app_pigeon.dart';
import 'package:flutter/foundation.dart';

/// The value of the `x-platform` header the backend's play analytics read, or
/// null on a platform the backend does not count (desktop and web builds).
String? platformHeaderValue([TargetPlatform? platform]) =>
    switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => null,
    };

/// [AuthorizedPigeon] that sends `x-platform` with every request.
///
/// The package offers no way to set a default header: its Dio is private and
/// its `get` takes no options. Writes pass the header through their options.
/// Reads go through a client of our own first, with the same token, and fall
/// back to the package on a 401 so that its refresh-and-retry still applies.
class BeatxPigeon extends AuthorizedPigeon {
  BeatxPigeon(
    super.refreshTokenManager, {
    required super.baseUrl,
    Dio? readClient,
    this.accessTokenOverride,
    TargetPlatform? platform,
  }) : _readClient =
           readClient ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
             ),
           ),
       _platform = platformHeaderValue(platform);

  final Dio _readClient;
  final String? _platform;

  /// Replaces the stored token lookup in tests.
  @visibleForTesting
  final Future<String?> Function()? accessTokenOverride;

  Map<String, String> get _platformHeader => {
    if (_platform != null) 'x-platform': _platform,
  };

  Future<String?> _accessToken() async {
    final override = accessTokenOverride;
    if (override != null) return override();
    return (await getCurrentAuthRecord())?.toJson()['access_token'] as String?;
  }

  Options _withPlatform(Options? options) => (options ?? Options()).copyWith(
    headers: {...?options?.headers, ..._platformHeader},
  );

  @override
  Future<Response> get(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final token = await _accessToken();
    try {
      return await _readClient.get<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: {
            ..._platformHeader,
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (error) {
      if (token == null || error.response?.statusCode != 401) rethrow;
      return super.get(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    }
  }

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) => super.post(
    path,
    data: data,
    options: _withPlatform(options),
    queryParameters: queryParameters,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  @override
  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) => super.put(
    path,
    data: data,
    options: _withPlatform(options),
    queryParameters: queryParameters,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  @override
  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) => super.patch(
    path,
    data: data,
    options: _withPlatform(options),
    queryParameters: queryParameters,
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  @override
  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) => super.delete(
    path,
    data: data,
    options: _withPlatform(options),
    queryParameters: queryParameters,
    cancelToken: cancelToken,
  );
}
