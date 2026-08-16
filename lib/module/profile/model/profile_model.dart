/// The signed-in user, as `GET /users/me` reports them — and as
/// `PATCH /users/profile` answers with, which is the same object.
class UserProfileModel {
  const UserProfileModel({
    this.id = '',
    this.name = '',
    this.email = '',
    this.role = 'user',
    this.provider = '',
    this.isVerified = false,
    this.coinBalance = 0,
    this.avatar,
    this.avatarKey,
    this.favoriteGenres = const [],
    this.favoriteArtists = const [],
    this.favoriteSongs = const [],
    this.likedVideos = const [],
    this.settings = const ProfileSettings(),
    this.createdAt,
    this.updatedAt,
    this.version = 0,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  /// How the account was created — `local`, or the social provider.
  final String provider;
  final bool isVerified;
  final int coinBalance;

  /// Where the avatar is served from, and the key it is stored under. Both
  /// are absent until the user uploads one.
  final String? avatar;
  final String? avatarKey;

  final List<String> favoriteGenres;
  final List<String> favoriteArtists;
  final List<String> favoriteSongs;
  final List<String> likedVideos;

  final ProfileSettings settings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int version;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      provider: (json['provider'] ?? '').toString(),
      isVerified: json['isVerified'] == true,
      coinBalance: _asInt(json['coinBalance']),
      avatar: json['avatar']?.toString(),
      avatarKey: json['avatarKey']?.toString(),
      favoriteGenres: _asIds(json['favoriteGenres']),
      favoriteArtists: _asIds(json['favoriteArtists']),
      favoriteSongs: _asIds(json['favoriteSongs']),
      likedVideos: _asIds(json['likedVideos']),
      settings: ProfileSettings.fromJson(
        json['settings'] is Map
            ? Map<String, dynamic>.from(json['settings'] as Map)
            : const {},
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      version: _asInt(json['__v']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'role': role,
    'provider': provider,
    'isVerified': isVerified,
    'coinBalance': coinBalance,
    'avatar': avatar,
    'avatarKey': avatarKey,
    'favoriteGenres': favoriteGenres,
    'favoriteArtists': favoriteArtists,
    'favoriteSongs': favoriteSongs,
    'likedVideos': likedVideos,
    'settings': settings.toJson(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': version,
  };

  /// The letter standing in for a missing avatar.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Whether the user has an avatar to show.
  bool get hasAvatar => (avatar ?? '').isNotEmpty;

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// The favourite and liked arrays are ids. They come back as plain strings,
  /// but tolerate the backend populating them into objects later.
  static List<String> _asIds(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) {
          if (item is Map) return (item['_id'] ?? item['id'] ?? '').toString();
          return item?.toString() ?? '';
        })
        .where((id) => id.isNotEmpty)
        .toList();
  }
}

/// The user's app settings, as carried on the profile and as
/// `GET /users/settings` reports them — `PATCH /users/settings` takes the same
/// shape back, whole, and answers with it.
class ProfileSettings {
  const ProfileSettings({
    this.language = 'en',
    this.theme = 'dark',
    this.enablePasscode = false,
    this.allowSms = false,
    this.allowEmailNotification = true,
    this.trackSearchHistory = true,
    this.sendUsageData = false,
    this.wifiOnlyMode = false,
  });

  final String language;
  final String theme;
  final bool enablePasscode;
  final bool allowSms;
  final bool allowEmailNotification;
  final bool trackSearchHistory;
  final bool sendUsageData;
  final bool wifiOnlyMode;

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      language: (json['language'] ?? 'en').toString(),
      theme: (json['theme'] ?? 'dark').toString(),
      enablePasscode: json['enablePasscode'] == true,
      allowSms: json['allowSms'] == true,
      allowEmailNotification: json['allowEmailNotification'] == true,
      trackSearchHistory: json['trackSearchHistory'] == true,
      sendUsageData: json['sendUsageData'] == true,
      wifiOnlyMode: json['wifiOnlyMode'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'theme': theme,
    'enablePasscode': enablePasscode,
    'allowSms': allowSms,
    'allowEmailNotification': allowEmailNotification,
    'trackSearchHistory': trackSearchHistory,
    'sendUsageData': sendUsageData,
    'wifiOnlyMode': wifiOnlyMode,
  };

  ProfileSettings copyWith({
    String? language,
    String? theme,
    bool? enablePasscode,
    bool? allowSms,
    bool? allowEmailNotification,
    bool? trackSearchHistory,
    bool? sendUsageData,
    bool? wifiOnlyMode,
  }) {
    return ProfileSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      enablePasscode: enablePasscode ?? this.enablePasscode,
      allowSms: allowSms ?? this.allowSms,
      allowEmailNotification:
          allowEmailNotification ?? this.allowEmailNotification,
      trackSearchHistory: trackSearchHistory ?? this.trackSearchHistory,
      sendUsageData: sendUsageData ?? this.sendUsageData,
      wifiOnlyMode: wifiOnlyMode ?? this.wifiOnlyMode,
    );
  }

  /// The language code as the settings rows spell it out.
  String get languageLabel => switch (language.trim().toLowerCase()) {
    'it' || 'it-it' => 'Italian',
    'en' || 'en-gb' || 'en-us' => 'English',
    final code when code.isEmpty => 'English',
    final code => code.toUpperCase(),
  };

  /// The theme as the settings rows spell it out.
  String get themeLabel => switch (theme.trim().toLowerCase()) {
    'light' => 'Light',
    'system' => 'System',
    'dark' => 'Dark',
    final value when value.isEmpty => 'Dark',
    final value => value[0].toUpperCase() + value.substring(1),
  };
}
