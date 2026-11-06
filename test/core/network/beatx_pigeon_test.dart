import 'package:app_pigeon/app_pigeon.dart';
import 'package:beatx_flutter/core/network/beatx_pigeon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      '{"status":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Manager extends BasicRefreshTokenManager {
  _Manager() : super('https://example.com/refresh');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('the header value follows the platform', () {
    expect(platformHeaderValue(TargetPlatform.iOS), 'ios');
    expect(platformHeaderValue(TargetPlatform.android), 'android');
    expect(platformHeaderValue(TargetPlatform.macOS), isNull);
  });

  BeatxPigeon pigeon(_RecordingAdapter adapter, String? token) => BeatxPigeon(
    _Manager(),
    baseUrl: 'https://example.com',
    platform: TargetPlatform.android,
    readClient: Dio()..httpClientAdapter = adapter,
    accessTokenOverride: () async => token,
  );

  test('a signed-in read sends the platform and the token', () async {
    final adapter = _RecordingAdapter();
    await pigeon(adapter, 'abc').get('https://example.com/songs/1/stream');

    expect(adapter.last?.headers['x-platform'], 'android');
    expect(adapter.last?.headers['Authorization'], 'Bearer abc');
  });

  test('a signed-out read sends no Authorization header', () async {
    final adapter = _RecordingAdapter();
    await pigeon(adapter, null).get('https://example.com/settings/public');

    expect(adapter.last?.headers['x-platform'], 'android');
    expect(adapter.last?.headers.containsKey('Authorization'), isFalse);
  });
}
