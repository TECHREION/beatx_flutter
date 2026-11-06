import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/di/external_service_di.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with [status] and [body].
class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);
  final int status;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, String body) =>
    Dio()..httpClientAdapter = _Adapter(status, body);

DioException _unauthorized(String message) {
  final options = RequestOptions(path: '/songs/home');
  return DioException(
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: 401,
      data: {'message': message},
    ),
  );
}

void main() {
  var signOuts = 0;
  late MyRefreshTokenManager manager;

  setUp(() {
    signOuts = 0;
    manager = MyRefreshTokenManager(
      currentAccessToken: () async => 'current-access',
      signOut: () async => signOuts++,
    );
  });

  group('refreshToken', () {
    test('maintenance keeps the existing session', () async {
      final result = await manager.refreshToken(
        refreshToken: 'current-refresh',
        dio: _dio(503, '{"error":"Maintenance","message":"Back soon"}'),
      );

      expect(result.accessToken, 'current-access');
      expect(result.refreshToken, 'current-refresh');
      // Null keeps the email and role saved at login.
      expect(result.data, isNull);
    });

    test('a rejected refresh still ends the session', () {
      expect(
        manager.refreshToken(
          refreshToken: 'expired',
          dio: _dio(401, '{"message":"Invalid token"}'),
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('a successful refresh returns the new tokens', () async {
      final result = await manager.refreshToken(
        refreshToken: 'old',
        dio: _dio(
          200,
          '{"data":{"accessToken":"new-a","refreshToken":"new-r"}}',
        ),
      );

      expect(result.accessToken, 'new-a');
      expect(result.refreshToken, 'new-r');
    });
  });

  group('shouldRefresh', () {
    final handler = ErrorInterceptorHandler();

    for (final message in [
      'This account has been banned',
      'This account is suspended',
      'This account no longer exists',
    ]) {
      test('"$message" signs out without refreshing', () async {
        expect(
          await manager.shouldRefresh(_unauthorized(message), handler),
          false,
        );
        expect(signOuts, 1);
      });
    }

    test('an expired token refreshes and keeps the session', () async {
      expect(
        await manager.shouldRefresh(_unauthorized('Token expired'), handler),
        true,
      );
      expect(signOuts, 0);
    });
  });
}
