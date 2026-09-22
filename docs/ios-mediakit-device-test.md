# iOS media_kit device test — 5 minutes, answers the last open question

Binary + runtime testing showed media_kit's **full (video) ffmpeg build can demux our production HLS** — it read the real duration (3:47.861) with no format error, unlike the audio-only build.

One unknown remains: **libmpv could not open an audio output device on the iOS simulator** (`Could not open/initialize audio device -> no sound`). That may be simulator-only. It cannot be resolved without a physical iPhone.

If audio plays on a real device, media_kit becomes a viable iOS EQ backend with **no backend change required**. If it does not, the progressive rendition is the only remaining path.

## Run it

```bash
flutter pub add media_kit media_kit_libs_video audio_session
# save the Dart file below as lib/main_mk2_probe.dart
flutter run -t lib/main_mk2_probe.dart -d <your-iphone>
```

## What to look for

- `playing=true` and `pos=` advancing  → HLS plays
- **audible sound**                      → audio output works on device
- `FILTER OK <- equalizer`               → the EQ filter is installed
- set `g=12` vs `g=-12` and listen       → real DSP on the HLS stream

If all four hold, report back and the full integration can proceed.

## Revert after testing

```bash
flutter pub remove media_kit media_kit_libs_video
rm lib/main_mk2_probe.dart
```

## Probe source

```dart
// TEMPORARY SPIKE — media_kit with the FULL (video) ffmpeg build.
// Question: does this build demux our production HLS, and expose EQ filters?
import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

const _hls =
    'https://beat-x-dev-s3-bucket.s3.ap-south-1.amazonaws.com/media/6a80b3d2d365357313ed8735/hls/master.m3u8';

void _log(String m) => debugPrint('[MK2] $m');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('mk2')))));

  // Previous run failed to open an audio device; give it a real session first
  // so that cannot be the confound.
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);
  _log('audio session active');

  final player = Player();
  final native = player.platform as NativePlayer;
  player.stream.error.listen((e) => _log('ERROR: $e'));

  try {
    _log('opening production HLS...');
    await player.open(Media(_hls), play: true);
    await Future<void>.delayed(const Duration(seconds: 12));

    _log('playing=${player.state.playing} pos=${player.state.position} '
        'dur=${player.state.duration} buffering=${player.state.buffering}');
    for (final p in [
      'file-format',
      'current-demuxer',
      'audio-codec-name',
      'audio-params/samplerate',
    ]) {
      try {
        _log('$p = "${await native.getProperty(p)}"');
      } catch (e) {
        _log('$p FAILED: $e');
      }
    }

    for (final f in [
      'anequalizer=c0 f=100 w=100 g=12 t=0',
      'superequalizer=1b=10',
      'equalizer=f=100:width_type=h:width=100:g=12',
    ]) {
      try {
        await native.setProperty('af', f);
        _log('FILTER OK  <- ${f.split('=').first} readback="${await native.getProperty('af')}"');
      } catch (e) {
        _log('FILTER FAIL <- ${f.split('=').first}: $e');
      }
    }
    await Future<void>.delayed(const Duration(seconds: 3));
    _log('after filters: playing=${player.state.playing} pos=${player.state.position}');
  } catch (e, s) {
    _log('UNEXPECTED ${e.runtimeType}: $e\n$s');
  }
  _log('DONE');
}
```
