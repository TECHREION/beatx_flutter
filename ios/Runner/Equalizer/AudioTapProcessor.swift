import AVFoundation
import MediaToolbox

/// Installs an `MTAudioProcessingTap` on an `AVPlayerItem` and runs every
/// decoded sample through an `EqualizerEngine`.
///
/// This is the only DSP insertion point `AVPlayer` offers. It requires the
/// asset to expose an audio track, which HLS assets do not — see
/// `docs/ios-equalizer-backend-requirements.md`. `attach` reports whether it
/// succeeded so the app can tell the truth about EQ availability instead of
/// assuming.
final class AudioTapProcessor {

  let engine = EqualizerEngine()

  /// Whether the tap has actually processed audio. This — not the platform —
  /// is what makes the equalizer "supported": it is only true once real
  /// samples have gone through the unit.
  private(set) var isProcessing = false

  /// Frames processed since attach. Used for diagnostics and to prove the DSP
  /// path is live rather than merely constructed.
  private(set) var processedFrames: Int64 = 0

  /// Peak sample magnitude of the most recent output block.
  ///
  /// Exists so the EQ can be proven to alter the signal by measurement rather
  /// than by assertion: with a large gain change the peak must move.
  /// Status of the most recent AudioUnitRender.
  ///
  /// Gates [isProcessing]: a failing render leaves the audio untouched, and
  /// claiming the equalizer is active in that state would be exactly the kind
  /// of silent no-op this design exists to prevent.
  private(set) var lastRenderStatus: OSStatus = noErr

  private weak var item: AVPlayerItem?

  /// Attaches to `item`'s first audio track.
  ///
  /// Returns false when the asset exposes no audio track, which is the normal
  /// and expected outcome for HLS.
  @discardableResult
  func attach(to item: AVPlayerItem) -> Bool {
    guard let track = item.asset.tracks(withMediaType: .audio).first else {
      return false
    }

    var callbacks = MTAudioProcessingTapCallbacks(
      version: kMTAudioProcessingTapCallbacksVersion_0,
      clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque()),
      init: { _, clientInfo, storageOut in
        // Ownership of the +1 retain above moves into the tap's storage and is
        // released in finalize. Getting this wrong leaks the processor.
        storageOut.pointee = clientInfo
      },
      finalize: { tap in
        let storage = MTAudioProcessingTapGetStorage(tap)
        Unmanaged<AudioTapProcessor>.fromOpaque(storage).release()
      },
      prepare: { tap, _, format in
        let processor = Unmanaged<AudioTapProcessor>
          .fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
        do {
          try processor.engine.prepare(format: format.pointee)
        } catch {
          NSLog("[Equalizer] engine prepare failed: \(error)")
        }
      },
      unprepare: { tap in
        let processor = Unmanaged<AudioTapProcessor>
          .fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
        processor.engine.unprepare()
        processor.isProcessing = false
      },
      process: { tap, frames, _, bufferListInOut, framesOut, flagsOut in
        let processor = Unmanaged<AudioTapProcessor>
          .fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()

        let status = MTAudioProcessingTapGetSourceAudio(
          tap, frames, bufferListInOut, flagsOut, nil, framesOut
        )
        guard status == noErr else { return }

        var timestamp = AudioTimeStamp()
        timestamp.mSampleTime = Float64(processor.processedFrames)
        timestamp.mFlags = .sampleTimeValid

        let renderStatus = processor.engine.render(
          bufferList: bufferListInOut,
          frameCount: UInt32(framesOut.pointee),
          timestamp: &timestamp
        )
        processor.lastRenderStatus = renderStatus
        processor.processedFrames += Int64(framesOut.pointee)
        processor.isProcessing = renderStatus == noErr
      }
    )

    var tap: MTAudioProcessingTap?
    let status = MTAudioProcessingTapCreate(
      kCFAllocatorDefault,
      &callbacks,
      kMTAudioProcessingTapCreationFlag_PostEffects,
      &tap
    )
    guard status == noErr, let tap else {
      NSLog("[Equalizer] tap creation failed: \(status)")
      return false
    }

    let parameters = AVMutableAudioMixInputParameters(track: track)
    parameters.audioTapProcessor = tap

    let mix = AVMutableAudioMix()
    mix.inputParameters = [parameters]
    item.audioMix = mix
    self.item = item

    return true
  }

  /// Detaches from the current item. The tap's finalize callback releases the
  /// retain taken in `attach`.
  func detach() {
    item?.audioMix = nil
    item = nil
    isProcessing = false
    processedFrames = 0
  }
}
