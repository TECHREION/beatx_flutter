import 'equalizer_preset.dart';

/// The user's equalizer configuration, as persisted between launches.
class EqualizerSettings {
  const EqualizerSettings({
    this.enabled = false,
    this.preset = EqualizerPreset.normal,
    this.gains = const [],
  });

  /// Bumped when the stored shape changes so an old blob can be discarded
  /// rather than misread.
  static const schemaVersion = 1;

  final bool enabled;
  final EqualizerPreset preset;

  /// One gain per device band. Empty when nothing has been applied yet.
  ///
  /// The length is meaningful: it belongs to the device that wrote it. A
  /// different band count on restore means these gains cannot be trusted.
  final List<double> gains;

  EqualizerSettings copyWith({
    bool? enabled,
    EqualizerPreset? preset,
    List<double>? gains,
  }) =>
      EqualizerSettings(
        enabled: enabled ?? this.enabled,
        preset: preset ?? this.preset,
        gains: gains ?? this.gains,
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'enabled': enabled,
        'preset': preset.name,
        'gains': gains,
      };

  /// Rebuilds settings from stored JSON.
  ///
  /// Returns null for anything unreadable — a future schema, a wrong shape, a
  /// corrupt blob — so the caller can fall back to defaults instead of
  /// restoring half a configuration.
  static EqualizerSettings? fromJson(Object? json) {
    if (json is! Map) return null;
    if (json['schemaVersion'] != schemaVersion) return null;

    final rawGains = json['gains'];
    if (rawGains is! List) return null;

    final gains = <double>[];
    for (final value in rawGains) {
      if (value is! num) return null;
      gains.add(value.toDouble());
    }

    return EqualizerSettings(
      enabled: json['enabled'] == true,
      preset: EqualizerPreset.fromId(json['preset'] as String?),
      gains: List.unmodifiable(gains),
    );
  }

  @override
  String toString() =>
      'EqualizerSettings(enabled: $enabled, preset: ${preset.name}, '
      'gains: $gains)';
}
