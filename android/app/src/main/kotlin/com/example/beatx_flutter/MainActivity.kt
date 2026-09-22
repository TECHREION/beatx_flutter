package com.example.beatx_flutter

import com.ryanheise.audioservice.AudioServiceActivity

/**
 * audio_service requires the host activity to be an [AudioServiceActivity]
 * (a FlutterFragmentActivity subclass) so the playback service can bind to it.
 * Reverting this to FlutterActivity silently breaks background playback and
 * the media notification.
 */
class MainActivity : AudioServiceActivity()
