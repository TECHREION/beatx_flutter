/// What a notification is about.
///
/// Drives the icon and tint on the row. Anything the backend sends that is not
/// listed here lands on [NotificationType.general] rather than being dropped,
/// so a category added server-side still shows up in the list.
enum NotificationType {
  podcast,
  audiobook,
  song,
  video,
  subscription,
  system,
  general;

  static NotificationType fromId(String? id) {
    final normalized = id?.trim().toLowerCase();
    return switch (normalized) {
      'podcast' || 'episode' => NotificationType.podcast,
      'audiobook' || 'book' => NotificationType.audiobook,
      'song' || 'track' || 'music' || 'release' => NotificationType.song,
      'video' || 'watch' => NotificationType.video,
      'subscription' || 'billing' || 'payment' => NotificationType.subscription,
      'system' || 'account' || 'security' => NotificationType.system,
      _ => NotificationType.general,
    };
  }
}

/// One entry in the notification feed.
///
/// Every field but [id] is optional, because a feed is the one place where a
/// half-filled entry is better than a dropped one: a notification with no body
/// still tells the user something happened.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.message = '',
    this.type = NotificationType.general,
    this.imageUrl,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? imageUrl;
  final bool isRead;

  /// When the backend says this was raised, in local time. Null when it sent
  /// nothing parseable — the row then shows no timestamp rather than a
  /// fabricated one.
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    final read = json['isRead'] ?? json['read'] ?? json['seen'];

    return AppNotification(
      id: id?.toString() ?? '',
      // Different backends name this differently and the row needs something
      // to print, so fall back through the usual spellings.
      title: (json['title'] ?? json['heading'] ?? '').toString(),
      message: (json['message'] ?? json['body'] ?? json['description'] ?? '')
          .toString(),
      type: NotificationType.fromId(json['type']?.toString()),
      imageUrl: _asUrl(json['image'] ?? json['imageUrl'] ?? json['thumbnail']),
      isRead: read is bool ? read : read?.toString() == 'true',
      createdAt: _asDate(
        json['createdAt'] ?? json['created_at'] ?? json['date'],
      ),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    imageUrl: imageUrl,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  /// How long ago this arrived, as the row prints it.
  String get relativeTime {
    final at = createdAt;
    if (at == null) return '';

    final elapsed = DateTime.now().difference(at);
    // A clock skewed slightly ahead of the server would otherwise render a
    // negative age; "Just now" is the honest reading of it.
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
    if (elapsed.inDays < 365) return '${(elapsed.inDays / 7).floor()}w ago';
    return '${(elapsed.inDays / 365).floor()}y ago';
  }

  static String? _asUrl(Object? value) {
    final url = value?.toString().trim();
    return url == null || url.isEmpty ? null : url;
  }

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

/// One page of `GET /notifications`, plus the unread counter the badge needs.
class NotificationFeed {
  const NotificationFeed({
    this.notifications = const [],
    this.unreadCount = 0,
    this.total = 0,
    this.page = 1,
    this.limit = 30,
  });

  final List<AppNotification> notifications;

  /// Unread across the whole feed, not just this page — which is why it is
  /// read from the envelope rather than counted off [notifications].
  final int unreadCount;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => notifications.length < total;

  /// Reads a feed out of the envelope's `data`.
  ///
  /// Tolerates both shapes the list routes use here: a bare array, or an
  /// object wrapping one under `data`, `notifications` or `items`. Entries
  /// without an id are dropped, since nothing can be marked read without one.
  factory NotificationFeed.fromJson(Object? data) {
    final json = data is Map ? Map<String, dynamic>.from(data) : null;
    final raw = data is List
        ? data
        : (json?['data'] ?? json?['notifications'] ?? json?['items']);
    final entries = raw is List ? raw : const [];

    final notifications = entries
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);

    return NotificationFeed(
      notifications: notifications,
      unreadCount: _asInt(
        json?['unreadCount'] ?? json?['unread'],
        // Absent a server counter, what is on this page is the best answer
        // available, and it is never worse than showing nothing.
        fallback: notifications.where((item) => !item.isRead).length,
      ),
      total: _asInt(json?['total'], fallback: notifications.length),
      page: _asInt(json?['page'], fallback: 1),
      limit: _asInt(json?['limit'], fallback: 30),
    );
  }

  static int _asInt(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
