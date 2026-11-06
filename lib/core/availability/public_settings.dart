/// A message the admins want shown to everyone.
class Announcement {
  const Announcement({required this.text, required this.updatedAt});

  final String text;

  /// Identifies this version of the message: a dismissed announcement shows
  /// again once this changes.
  final String updatedAt;
}

/// What `GET /settings/public` reports. The defaults describe a healthy
/// server, so nothing is hidden before the first answer arrives or if it never
/// does; the API still enforces both switches.
class PublicSettings {
  const PublicSettings({
    this.maintenanceMode = false,
    this.allowNewRegistrations = true,
    this.announcement,
  });

  final bool maintenanceMode;
  final bool allowNewRegistrations;
  final Announcement? announcement;

  factory PublicSettings.fromJson(Map<String, dynamic> json) {
    final announcement = json['announcement'];
    final text = announcement is Map
        ? (announcement['text'] ?? '').toString().trim()
        : '';

    return PublicSettings(
      maintenanceMode: json['maintenanceMode'] == true,
      allowNewRegistrations: json['allowNewRegistrations'] != false,
      announcement: text.isEmpty
          ? null
          : Announcement(
              text: text,
              updatedAt: ((announcement as Map)['updatedAt'] ?? '').toString(),
            ),
    );
  }
}
