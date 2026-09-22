import 'package:beatx_flutter/core/player/equalizer/equalizer_service_ios.dart';
import 'package:beatx_flutter/core/player/equalizer/models/equalizer_exception.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stand-in for the native side, so the bridge's contract can be exercised
/// without an iPhone: what it sends, what it refuses to send, and how it maps
/// native failures back into typed errors.
class _FakeNative {
  _FakeNative({
    this.processing = true,
    this.hasSeenItem = true,
    this.itemHasAudioTrack = true,
  });

  bool processing;
  bool hasSeenItem;
  bool itemHasAudioTrack;
  List<double> frequencies =
      const [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  List<double> gains = List<double>.filled(10, 0);
  bool enabled = false;

  final calls = <MethodCall>[];
  String? throwCode;

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    if (throwCode != null) {
      throw PlatformException(code: throwCode!, message: 'native said no');
    }
    switch (call.method) {
      case 'getConfiguration':
        return <String, dynamic>{
          'frequencies': frequencies,
          'minDecibels': -12.0,
          'maxDecibels': 12.0,
          'gains': gains,
          'enabled': enabled,
          'processing': processing,
          'hasSeenItem': hasSeenItem,
          'itemHasAudioTrack': itemHasAudioTrack,
        };
      case 'setEnabled':
        enabled = (call.arguments as Map)['enabled'] as bool;
        return null;
      case 'setBandGain':
        final args = call.arguments as Map;
        gains[args['bandIndex'] as int] = args['gainDb'] as double;
        return null;
      case 'setAllGains':
        gains = ((call.arguments as Map)['gains'] as List).cast<double>();
        return null;
      default:
        return null;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.beatx/equalizer');
  late _FakeNative native;
  late IosEqualizerService service;

  void install(_FakeNative fake) {
    native = fake;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, fake.handle);
    service = IosEqualizerService(channel: channel);
  }

  setUp(() => install(_FakeNative()));

  tearDown(() {
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('configuration', () {
    test('reads the native 10-band configuration', () async {
      await service.initialize();
      expect(service.isSupported, isTrue);
      expect(service.isReady, isTrue);
      expect(service.bands, hasLength(10));
      expect(service.getBandFrequencies(),
          [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]);
      expect(service.minDb, -12);
      expect(service.maxDb, 12);
    });

    test('band labels follow the reported frequencies', () async {
      await service.initialize();
      expect(service.bands.first.label, '31');
      expect(service.bands[5].label, '1K');
      expect(service.bands.last.label, '16K');
    });
  });

  group('availability is measured, not assumed', () {
    test('not ready when the tap is not processing', () async {
      install(_FakeNative(processing: false));
      await service.initialize();
      expect(service.isReady, isFalse);
    });

    test('reports needsPlayback before anything has played', () async {
      install(_FakeNative(processing: false, hasSeenItem: false));
      await service.initialize();
      expect(service.unavailableReason, EqualizerUnavailableReason.needsPlayback);
    });

    test('reports incompatibleStream for an asset with no audio track', () async {
      // This is the HLS case: an item was seen, but it exposes no track.
      install(_FakeNative(
        processing: false,
        hasSeenItem: true,
        itemHasAudioTrack: false,
      ));
      await service.initialize();
      expect(
        service.unavailableReason,
        EqualizerUnavailableReason.incompatibleStream,
      );
    });

    test('reports none once actually processing', () async {
      await service.initialize();
      expect(service.unavailableReason, EqualizerUnavailableReason.none);
    });
  });

  group('validation happens before the channel hop', () {
    setUp(() async => service.initialize());

    test('rejects an out-of-range band index without calling native', () async {
      native.calls.clear();
      await expectLater(
        service.setBandGain(99, 0),
        throwsA(isA<EqualizerException>().having(
            (e) => e.kind, 'kind', EqualizerErrorKind.invalidBandIndex)),
      );
      expect(native.calls, isEmpty);
    });

    test('rejects an out-of-range gain without calling native', () async {
      native.calls.clear();
      await expectLater(
        service.setBandGain(0, 99),
        throwsA(isA<EqualizerException>().having(
            (e) => e.kind, 'kind', EqualizerErrorKind.gainOutOfRange)),
      );
      expect(native.calls, isEmpty);
    });

    test('rejects a wrong-length gain vector', () async {
      await expectLater(
        service.setAllBandGains(List<double>.filled(5, 0)),
        throwsA(isA<EqualizerException>().having(
            (e) => e.kind, 'kind', EqualizerErrorKind.bandCountMismatch)),
      );
    });

    test('refuses to act when not ready', () async {
      install(_FakeNative(processing: false));
      await service.initialize();
      await expectLater(
        service.setBandGain(0, 3),
        throwsA(isA<EqualizerException>()
            .having((e) => e.kind, 'kind', EqualizerErrorKind.notReady)),
      );
    });
  });

  group('native round trips', () {
    setUp(() async => service.initialize());

    test('sends a band gain and reflects it locally', () async {
      await service.setBandGain(3, 6.5);
      expect(native.gains[3], 6.5);
      expect(service.getBandGains()[3], 6.5);
    });

    test('sends all gains at once', () async {
      final gains = List<double>.generate(10, (i) => i - 5.0);
      await service.setAllBandGains(gains);
      expect(native.gains, gains);
    });

    test('reset sends a flat vector', () async {
      await service.setBandGain(0, 9);
      await service.reset();
      expect(native.gains, everyElement(0.0));
    });

    test('setEnabled round-trips', () async {
      await service.setEnabled(true);
      expect(native.enabled, isTrue);
      expect(service.isEnabled, isTrue);
    });
  });

  group('native failures map to typed errors', () {
    setUp(() async => service.initialize());

    test('maps gain_out_of_range', () async {
      native.throwCode = 'gain_out_of_range';
      await expectLater(
        service.setEnabled(true),
        throwsA(isA<EqualizerException>().having(
            (e) => e.kind, 'kind', EqualizerErrorKind.gainOutOfRange)),
      );
    });

    test('maps effect_unavailable', () async {
      native.throwCode = 'effect_unavailable';
      await expectLater(
        service.setEnabled(true),
        throwsA(isA<EqualizerException>().having(
            (e) => e.kind, 'kind', EqualizerErrorKind.effectUnavailable)),
      );
    });

    test('maps an unknown code to platformError rather than swallowing it',
        () async {
      native.throwCode = 'something_new';
      await expectLater(
        service.setEnabled(true),
        throwsA(isA<EqualizerException>()
            .having((e) => e.kind, 'kind', EqualizerErrorKind.platformError)),
      );
    });

    test('a missing plugin is reported as unsupported', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await expectLater(
        service.setEnabled(true),
        throwsA(isA<EqualizerException>()
            .having((e) => e.kind, 'kind', EqualizerErrorKind.notSupported)),
      );
    });
  });
}
