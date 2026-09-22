import AVFoundation
import Flutter

/// Flutter bridge for the iOS equalizer.
///
/// ## Why it watches notifications
/// just_audio owns the `AVQueuePlayer` privately, so there is no reference to
/// borrow. `AVPlayerItemNewAccessLogEntry` carries the current `AVPlayerItem`
/// as its object and is public API, which is enough to find the item without
/// forking just_audio or swizzling anything. Attaching the mix mid-playback is
/// verified to work, so arriving slightly after playback starts is fine.
///
/// The observer stays live for the life of the app, so item replacement on
/// track change re-attaches the tap rather than leaving it on a dead item.
final class EqualizerPlugin: NSObject, FlutterPlugin {

  private let processor = AudioTapProcessor()
  private var observedItem: AVPlayerItem?

  /// Whether any player item has been seen yet. Distinguishes "nothing has
  /// played" from "this stream cannot be equalised", so the UI can say which.
  private var hasSeenItem = false

  /// Whether the most recent item exposed an audio track. False for HLS.
  private var lastItemHadAudioTrack = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.beatx/equalizer",
      binaryMessenger: registrar.messenger()
    )
    let instance = EqualizerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.startObservingPlayerItems()
  }

  private func startObservingPlayerItems() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleNewAccessLogEntry(_:)),
      name: .AVPlayerItemNewAccessLogEntry,
      object: nil
    )
  }

  @objc private func handleNewAccessLogEntry(_ note: Notification) {
    guard let item = note.object as? AVPlayerItem else { return }

    // video_player creates its own items; only just_audio's are ours.
    guard String(describing: type(of: item)) == "IndexedPlayerItem" else { return }
    guard item !== observedItem else { return }

    processor.detach()
    observedItem = item
    hasSeenItem = true
    lastItemHadAudioTrack = !item.asset.tracks(withMediaType: .audio).isEmpty

    // Expected to fail for HLS: those assets expose no audio track. The app
    // then reports the equalizer as unsupported for this item rather than
    // presenting controls that cannot affect the sound.
    let attached = processor.attach(to: item)
    #if DEBUG
      NSLog(
        "[Equalizer] item changed; tap attached=\(attached) "
          + "audioTracks=\(item.asset.tracks(withMediaType: .audio).count)"
      )
    #endif
  }

  // MARK: - Method channel

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "isSupported":
        // Truthful by construction: true only once real samples have been
        // processed, never a platform check.
        result(processor.isProcessing)

      case "getConfiguration":
        result([
          "frequencies": EqualizerEngine.frequencies,
          "minDecibels": EqualizerEngine.minDecibels,
          "maxDecibels": EqualizerEngine.maxDecibels,
          "gains": processor.engine.gains,
          "enabled": processor.engine.enabled,
          "processing": processor.isProcessing,
          "processedFrames": processor.processedFrames,
          "hasSeenItem": hasSeenItem,
          "itemHasAudioTrack": lastItemHadAudioTrack,
          "lastRenderStatus": Int(processor.lastRenderStatus),
        ])

      case "setEnabled":
        guard let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool else {
          throw EqualizerError.invalidBandIndex
        }
        processor.engine.setEnabled(enabled)
        result(nil)

      case "setBandGain":
        guard let args = call.arguments as? [String: Any],
              let index = args["bandIndex"] as? Int,
              let gain = args["gainDb"] as? Double
        else {
          throw EqualizerError.invalidBandIndex
        }
        try processor.engine.setGain(gain, at: index)
        result(nil)

      case "setAllGains":
        guard let gains = (call.arguments as? [String: Any])?["gains"] as? [Double] else {
          throw EqualizerError.invalidBandIndex
        }
        // Validate everything before applying any of it, so one bad value
        // cannot leave the EQ half-written.
        for gain in gains where
          !gain.isFinite || gain < EqualizerEngine.minDecibels
            || gain > EqualizerEngine.maxDecibels {
          throw EqualizerError.gainOutOfRange
        }
        guard gains.count == processor.engine.bandCount else {
          throw EqualizerError.invalidBandIndex
        }
        for (index, gain) in gains.enumerated() {
          try processor.engine.setGain(gain, at: index)
        }
        result(nil)

      case "reset":
        for index in 0..<processor.engine.bandCount {
          try processor.engine.setGain(0, at: index)
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as EqualizerError {
      result(FlutterError(code: error.code, message: error.message, details: nil))
    } catch {
      result(
        FlutterError(
          code: "platform_error",
          message: "Unexpected equalizer failure.",
          details: nil
        )
      )
    }
  }
}
