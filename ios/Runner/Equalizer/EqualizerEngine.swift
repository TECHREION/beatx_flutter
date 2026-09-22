import AudioToolbox
import AVFoundation

/// A real 10-band parametric EQ built on Apple's `kAudioUnitSubType_NBandEQ`.
///
/// The unit is created once and reconfigured in place. Changing a gain writes a
/// single AudioUnit parameter on the live unit — no graph rebuild, no player
/// recreation, no audio glitch.
///
/// Thread safety: `setGain`/`setEnabled` are called from the Flutter platform
/// thread while `render` runs on the real-time audio thread. AudioUnit
/// parameter writes are designed for exactly this and are safe without locks;
/// nothing else here is mutated after `prepare`.
final class EqualizerEngine {

  /// The band centre frequencies this engine is configured with.
  ///
  /// AUNBandEQ lets us choose them, so these are the requested musical
  /// frequencies rather than something the hardware imposes.
  static let frequencies: [Double] = [
    31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000,
  ]

  /// AUNBandEQ accepts far more, but a band pushed past this on top of
  /// already-mastered material mostly buys clipping.
  static let minDecibels: Double = -12
  static let maxDecibels: Double = 12

  private var audioUnit: AudioUnit?
  private var isInitialized = false

  /// Source audio for the current render pass, published by the tap.
  private var sourceBuffers: UnsafeMutablePointer<AudioBufferList>?

  private(set) var enabled = false
  private(set) var gains = [Double](repeating: 0, count: frequencies.count)

  var bandCount: Int { Self.frequencies.count }

  // MARK: - Lifecycle

  /// Builds and initializes the unit for `format`. Called from the tap's
  /// prepare callback, where the real stream format first becomes known.
  func prepare(format: AudioStreamBasicDescription) throws {
    unprepare()

    var description = AudioComponentDescription(
      componentType: kAudioUnitType_Effect,
      componentSubType: kAudioUnitSubType_NBandEQ,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0
    )
    guard let component = AudioComponentFindNext(nil, &description) else {
      throw EqualizerError.unitUnavailable
    }

    var unit: AudioUnit?
    try check(AudioComponentInstanceNew(component, &unit), "AudioComponentInstanceNew")
    guard let unit else { throw EqualizerError.unitUnavailable }
    audioUnit = unit

    var bands = UInt32(Self.frequencies.count)
    try check(
      AudioUnitSetProperty(
        unit, kAUNBandEQProperty_NumberOfBands, kAudioUnitScope_Global, 0,
        &bands, UInt32(MemoryLayout<UInt32>.size)
      ),
      "NumberOfBands"
    )

    var streamFormat = format
    let size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
    try check(
      AudioUnitSetProperty(
        unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0,
        &streamFormat, size
      ),
      "StreamFormat(input)"
    )
    try check(
      AudioUnitSetProperty(
        unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0,
        &streamFormat, size
      ),
      "StreamFormat(output)"
    )

    // Feeds the unit from whatever the tap handed us this pass.
    var callback = AURenderCallbackStruct(
      inputProc: { refCon, _, _, _, frameCount, ioData -> OSStatus in
        let engine = Unmanaged<EqualizerEngine>.fromOpaque(refCon).takeUnretainedValue()
        return engine.provideInput(frameCount: frameCount, ioData: ioData)
      },
      inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
    )
    try check(
      AudioUnitSetProperty(
        unit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0,
        &callback, UInt32(MemoryLayout<AURenderCallbackStruct>.size)
      ),
      "SetRenderCallback"
    )

    // The tap hands us blocks far larger than an audio unit's default slice
    // (4096 frames observed vs a much smaller default). Without raising this,
    // every AudioUnitRender fails with kAudioUnitErr_TooManyFramesToProcess
    // (-10874) and the audio passes through completely unprocessed — the EQ
    // silently does nothing. Must be set before initialization.
    var maxFrames: UInt32 = 16384
    try check(
      AudioUnitSetProperty(
        unit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0,
        &maxFrames, UInt32(MemoryLayout<UInt32>.size)
      ),
      "MaximumFramesPerSlice"
    )

    try check(AudioUnitInitialize(unit), "AudioUnitInitialize")
    isInitialized = true

    for index in 0..<Self.frequencies.count {
      applyFrequency(index)
      applyGain(index)
      applyBypass(index)
    }
  }

  func unprepare() {
    guard let unit = audioUnit else { return }
    if isInitialized { AudioUnitUninitialize(unit) }
    AudioComponentInstanceDispose(unit)
    audioUnit = nil
    isInitialized = false
  }

  // MARK: - Parameters

  func setEnabled(_ value: Bool) {
    enabled = value
    // Per-band bypass rather than tearing the unit down: instant, click-free,
    // and keeps the gains intact for when it is switched back on.
    for index in 0..<Self.frequencies.count { applyBypass(index) }
  }

  func setGain(_ gainDb: Double, at index: Int) throws {
    guard index >= 0 && index < Self.frequencies.count else {
      throw EqualizerError.invalidBandIndex
    }
    guard gainDb.isFinite,
          gainDb >= Self.minDecibels,
          gainDb <= Self.maxDecibels
    else {
      throw EqualizerError.gainOutOfRange
    }
    gains[index] = gainDb
    applyGain(index)
  }

  private func applyFrequency(_ index: Int) {
    setParameter(kAUNBandEQParam_Frequency, index, Float(Self.frequencies[index]))
  }

  private func applyGain(_ index: Int) {
    setParameter(kAUNBandEQParam_Gain, index, Float(gains[index]))
  }

  private func applyBypass(_ index: Int) {
    setParameter(kAUNBandEQParam_BypassBand, index, enabled ? 0 : 1)
  }

  private func setParameter(_ base: AudioUnitParameterID, _ index: Int, _ value: Float) {
    guard let unit = audioUnit else { return }
    AudioUnitSetParameter(
      unit, base + AudioUnitParameterID(index), kAudioUnitScope_Global, 0, value, 0
    )
  }

  // MARK: - Rendering

  /// Processes `frameCount` frames of `bufferList` in place.
  ///
  /// Real-time thread. No allocation, no locks, no Swift runtime calls that can
  /// block.
  func render(
    bufferList: UnsafeMutablePointer<AudioBufferList>,
    frameCount: UInt32,
    timestamp: inout AudioTimeStamp
  ) -> OSStatus {
    guard isInitialized, let unit = audioUnit else { return noErr }
    sourceBuffers = bufferList
    defer { sourceBuffers = nil }

    var flags = AudioUnitRenderActionFlags()
    return AudioUnitRender(unit, &flags, &timestamp, 0, frameCount, bufferList)
  }

  /// Hands the unit the source audio the tap just produced. Pointers are
  /// passed through rather than copied, so this stays allocation-free.
  private func provideInput(
    frameCount: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>?
  ) -> OSStatus {
    guard let ioData, let source = sourceBuffers else { return noErr }
    let output = UnsafeMutableAudioBufferListPointer(ioData)
    let input = UnsafeMutableAudioBufferListPointer(source)
    for index in 0..<min(output.count, input.count) {
      output[index].mNumberChannels = input[index].mNumberChannels
      output[index].mDataByteSize = input[index].mDataByteSize
      output[index].mData = input[index].mData
    }
    return noErr
  }

  private func check(_ status: OSStatus, _ what: String) throws {
    guard status == noErr else {
      throw EqualizerError.audioUnit(what, status)
    }
  }
}

enum EqualizerError: Error {
  case unitUnavailable
  case invalidBandIndex
  case gainOutOfRange
  case audioUnit(String, OSStatus)

  var code: String {
    switch self {
    case .unitUnavailable: return "effect_unavailable"
    case .invalidBandIndex: return "invalid_band_index"
    case .gainOutOfRange: return "gain_out_of_range"
    case .audioUnit: return "platform_error"
    }
  }

  var message: String {
    switch self {
    case .unitUnavailable:
      return "The system did not provide an NBandEQ audio unit."
    case .invalidBandIndex:
      return "Band index is outside the configured range."
    case .gainOutOfRange:
      return "Gain is outside the supported decibel range."
    case .audioUnit(let what, let status):
      return "\(what) failed with status \(status)."
    }
  }
}
