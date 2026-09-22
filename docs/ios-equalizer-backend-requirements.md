# Backend requirement: progressive audio rendition (unblocks the iOS equalizer)

## Why

The iOS equalizer cannot be built against HLS. This is a hard platform limit, and it has been measured on our own production stream rather than inferred.

On iOS, the only place DSP can be inserted into an `AVPlayer` chain is an `MTAudioProcessingTap` attached via `AVAudioMix`. An audio mix must reference an **audio track** on the asset. HLS assets expose none.

Probe run against our live content on iOS, identical code, two URLs:

| | HLS master (`.m3u8`) | Progressive (`.wav`) |
|---|---|---|
| Track load status | 2 (loaded) | 2 (loaded) |
| **Audio tracks exposed** | **0** | 1 |
| Audio mix attachable | **no** | yes |
| Tap `prepare` fired | **no** | yes |
| Tap process callbacks | **0** | 128 |
| Frames processed | 0 | 524,288 |
| Peak amplitude | 0.0000 | 1.0149 |
| Reported format | n/a | 48 kHz stereo |

**The iOS equalizer is now implemented and measured working.** On a real
progressive asset, with the tap attached and `AudioUnitRender` returning
`noErr`, the same passage of the same track measured:

| setting | peak amplitude |
|---|---|
| EQ off | 1.0102 |
| all 10 bands +12 dB | **4.6001** |
| all 10 bands −12 dB | **0.5043** |

Ten bands at exactly 31/62/125/250/500/1k/2k/4k/8k/16 kHz, range ±12 dB. The
same build on the production HLS URL reports `tap attached=false,
audioTracks=0, processing=false` and the UI says the track cannot be equalised.

So the client is finished and self-activating: it has nothing to attach to
while HLS is the only rendition, and it will start working on its own the first
time a progressive URL is played — no app update, no feature flag.

**Android is unaffected.** It uses `android.media.audiofx.Equalizer`, which binds to the decoder's output audio session, after decoding. Transport format is irrelevant there, and Android keeps using HLS unchanged.

## What is needed

One additional, non-segmented rendition per audio item, alongside the existing HLS output. The transcode pipeline already produces AAC; this is a second output from the same job, not a new pipeline.

### Format

| Field | Requirement |
|---|---|
| Container | MP4/M4A (preferred) or MP3 |
| Codec | AAC-LC (already produced for HLS) or MP3 |
| Bitrate | 128–192 kbps CBR or VBR |
| Sample rate | Match the source (44.1 or 48 kHz) |
| Channels | Stereo |
| **`faststart`** | **Required for MP4/M4A** — `moov` atom must be at the front (`ffmpeg -movflags +faststart`), otherwise playback cannot begin until the whole file downloads |

### Delivery

| Requirement | Detail |
|---|---|
| HTTP **range requests** | Must support `Range:` / return `206 Partial Content`. Seeking and buffering depend on it. S3 already does this. |
| `Content-Type` | `audio/mp4` (M4A) or `audio/mpeg` (MP3) — must **not** be `application/octet-stream` |
| `Content-Length` | Must be present |
| Redirects | Fine; the player follows them |
| Signed URLs | Acceptable, but see TTL below |

### API surface

The existing `/stream` response shape already anticipates this — it returns a `streamType` discriminator that the client currently parses and ignores:

```json
{
  "streamUrl": "...",
  "durationMs": 227840,
  "streamType": "hls" | "progressive"
}
```

Preferred approach — let the client ask:

```
GET /api/v1/songs/:id/stream?format=progressive
GET /api/v1/songs/:id/stream?format=hls        (default, unchanged)
```

Response must set `streamType` to match what `streamUrl` actually points at. The client will start honouring this field.

If a query parameter is not desirable, an additional field on the same response works too:

```json
{
  "streamUrl": "<hls master>",
  "streamType": "hls",
  "progressiveUrl": "<m4a>"        // new
}
```

Either shape is fine. What matters is that the client can obtain a progressive URL for a given item, and can tell which kind it received.

### Scope

Needed for all three audio content types, which share the same transcode fields (`audioKey`, `hlsMasterUrl`, `transcodeStatus`):

- songs — `/songs/:id/stream`
- podcast episodes — `/podcasts/episodes/:id/stream`
- audiobook chapters — `/audiobook/:id/stream/:chapterId`

Video (`/videos/:id/stream`) is **out of scope** — it uses a separate player and has no equalizer.

### Backfill

Existing items whose `transcodeStatus` is `ready` only have HLS. They need the progressive rendition generated retroactively, or the client will fall back to HLS and the equalizer will report itself unavailable for those tracks (handled gracefully — no crash, no fake controls).

## Constraints worth knowing

- **Signed-URL TTL**: if progressive URLs are signed, the TTL must exceed the longest track plus pause time, or playback breaks mid-track when resuming from background. A minimum of 6 hours is suggested; unsigned (as the HLS content is today) is simpler.
- **No adaptive bitrate.** Progressive has one quality level, so a weak connection buffers rather than dropping quality. This is the accepted trade-off for iOS EQ and does not affect Android.
- **Storage**: roughly +3–4 MB per 4-minute track at 128 kbps, on top of the existing HLS renditions.

## How to verify a rendition is correct

```bash
# 1. Type, length, and range support
curl -sI "<progressive-url>" | grep -iE 'content-type|content-length|accept-ranges'
#    expect: audio/mp4 (or audio/mpeg), a length, and accept-ranges: bytes

# 2. Range requests actually work
curl -s -o /dev/null -w '%{http_code}\n' -r 0-1024 "<progressive-url>"
#    expect: 206

# 3. faststart (MP4/M4A only) — moov must precede mdat
curl -s -r 0-4096 "<progressive-url>" | xxd | grep -m2 -E 'moov|mdat'
```

Once a URL passes those three, the iOS equalizer will attach to it. The client-side probe that produced the table above can be re-run against the real URL to confirm end to end before release.

---

# Appendix: alternatives evaluated and rejected (with evidence)

Before asking for a backend change, every client-side option was tested against the
real production stream. None of these are theoretical objections.

## A. AVAudioEngine + AVAudioUnitEQ — rejected

`AVAudioUnitEQ` only exists inside `AVAudioEngine`, which is a separate, non-composable
stack from `AVPlayer`. `AVAudioEngine` cannot play HLS, and there is no public API to
route `AVPlayer` output into it. Source-verified in `just_audio_darwin`
(`UriAudioSource.m` → `AVURLAsset` → `IndexedPlayerItem` → `AVQueuePlayer`): for a
remote `.m3u8`, AVFoundation performs segment fetch and AAC decode internally and
exposes neither a track nor PCM.

## B. MTAudioProcessingTap on the AVPlayerItem — rejected for HLS

Measured on-device-class test (iOS simulator, iOS 26.5), identical code, two URLs:

| | production HLS | progressive control |
|---|---|---|
| audio tracks exposed | **0** | 1 |
| audio mix attachable | no | yes |
| tap `prepare` fired | no | yes |
| process callbacks | **0** | **137** |
| peak amplitude | 0.0000 | 1.0149 |

`AVMutableAudioMixInputParameters(track:)` cannot even be constructed for HLS.
Separately confirmed that attaching the mix *mid-playback* works (tap fired 50 ms
later, 137 callbacks), so no fork of `just_audio` would be required — only a
progressive rendition.

## C. media_kit / libmpv as the iOS audio backend — rejected (binary-verified)

Tested twice: once with `media_kit_libs_audio`, once with the full
`media_kit_libs_video` build (mpv 2.0.0, ffmpeg 60.x), against the real
production HLS URL.

**The full build CAN demux our HLS.** It read the correct duration
(`0:03:47.861342`) with zero format-recognition errors, unlike the audio-only
build. An earlier conclusion that media_kit could not parse the stream was wrong
and applied only to the stripped audio build.

**But libmpv on iOS has no audio output driver at all.** This is the blocker, and
it is verifiable from the shipped binary rather than from runtime behaviour:

- `otool -L` on `Mpv.framework/Mpv` (arm64) links only Ass, Avcodec, Avfilter,
  Avformat, Avutil, Swresample, Swscale, Uchardet, libiconv, libSystem, libz.
  **No AudioToolbox, CoreAudio, AudioUnit, AVFAudio or AVFoundation.**
- `nm -u -arch arm64` shows **zero** CoreAudio/AudioToolbox/AudioUnit/AVAudio
  symbols among its 426 undefined symbols.
- The only `ao_*.c` string present is `ao_lavc.c`, which is libavcodec *encoding*
  output, not a playback device.
- Avcodec/Avformat do link AudioToolbox — that is hardware AAC *decoding*, not
  output.

An audio output driver on iOS must link one of those frameworks. None is linked,
so `Could not open/initialize audio device -> no sound` is the expected result on
**any** iOS target. A physical-device test is not required to rule this out.

Also relevant had it worked: only the `equalizer` filter is compiled into
`Avfilter` (`anequalizer`, `superequalizer`, `bass`, `volume` are all absent),
and media_kit provides no AVAudioSession, background-audio, remote-command or
Now Playing integration, all of which this app currently relies on.

## D. Custom HLS client + AudioToolbox + AVAudioEngine — viable but disproportionate

Parsing the playlist, fetching `.ts` segments, demuxing ADTS, decoding AAC via
`AudioConverter`, and feeding `AVAudioEngine` would give full DSP control using only
Apple APIs. It also means owning adaptive bitrate, seeking, buffering, stall recovery
and interruption handling — weeks of work and a large native surface, to replace a
player that already works. Recommended only if the progressive rendition is refused.

## Conclusion

A progressive rendition is the smallest change that yields real, audible EQ on iOS
while preserving background playback, lock-screen controls and the existing player.

---

# Appendix: transcode command

Generated from the same AAC the HLS ladder already uses:

```bash
ffmpeg -i <source> \
  -vn \
  -c:a aac -b:a 192k -ar 44100 -ac 2 \
  -movflags +faststart \
  <id>.m4a
```

`-movflags +faststart` is not optional: without it the `moov` atom sits at the end of
the file and iOS cannot begin playback until the entire file has downloaded.
