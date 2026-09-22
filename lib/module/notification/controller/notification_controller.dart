import 'package:app_pigeon/app_pigeon.dart';
import 'package:get/get.dart';

import '../model/notification_model.dart';
import '../services/notification_interface.dart';
import '../services/notification_interface_impl.dart';

/// The notification feed, behind `GET /notifications`.
///
/// Shared rather than screen-scoped, because the bell in every tab header
/// shows the unread count without the notification screen ever being opened.
class NotificationController extends GetxController {
  /// The shared instance, registered on first use.
  static NotificationController get instance {
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }
    return Get.find<NotificationController>();
  }

  static const _pageSize = 30;

  final notifications = <AppNotification>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;

  /// Unread across the whole feed, as the badge shows it.
  final unreadCount = 0.obs;

  /// False until a fetch has come back, so the badge can be held back rather
  /// than shown as a zero that only means "not asked yet".
  final hasLoaded = false.obs;

  /// Notifications with a mark-read in flight, kept out of the way of a
  /// second tap.
  final marking = <String>{}.obs;

  int _page = 1;
  int _total = 0;

  bool get hasMore => notifications.length < _total;

  /// The badge string for the bell, or null when there is nothing to show.
  /// Caps at `9+` because the badge is a 17px circle.
  String? get badge {
    if (!hasLoaded.value || unreadCount.value <= 0) return null;
    return unreadCount.value > 9 ? '9+' : '${unreadCount.value}';
  }

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  NotificationInterface _interface() {
    if (!Get.isRegistered<NotificationInterface>() &&
        Get.isRegistered<AuthorizedPigeon>()) {
      Get.put<NotificationInterface>(
        NotificationInterfaceImpl(Get.find<AuthorizedPigeon>()),
      );
    }
    return Get.find<NotificationInterface>();
  }

  Future<void>? _inFlight;

  /// Reloads the first page.
  ///
  /// A second caller joins the fetch already running rather than being turned
  /// away — the screen asks on open at the same moment this controller's own
  /// first fetch is still in flight, and a dropped call would leave the screen
  /// waiting on a future that never ran.
  Future<void> fetch() =>
      _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<void> _fetch() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await _interface().notifications(page: 1, limit: _pageSize);

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final feed = success.data ?? const NotificationFeed();
      notifications.assignAll(feed.notifications);
      unreadCount.value = feed.unreadCount;
      _total = feed.total;
      _page = 1;
    });

    hasLoaded.value = true;
    isLoading.value = false;
  }

  /// Appends the next page. Does nothing when one is already loading or the
  /// feed is exhausted.
  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;

    isLoadingMore.value = true;
    final next = _page + 1;

    final result = await _interface().notifications(
      page: next,
      limit: _pageSize,
    );

    result.fold((failure) => errorMessage.value = failure.uiMessage, (success) {
      final feed = success.data ?? const NotificationFeed();
      // An id already on the list means the page shifted under us — a new
      // notification arriving between the two calls pushes everything down
      // — so merge rather than blindly appending a duplicate.
      final known = notifications.map((item) => item.id).toSet();
      notifications.addAll(
        feed.notifications.where((item) => !known.contains(item.id)),
      );
      unreadCount.value = feed.unreadCount;
      _total = feed.total;
      _page = next;
    });

    isLoadingMore.value = false;
  }

  /// Marks one notification read.
  ///
  /// The row flips immediately and is put back if the call fails: waiting on
  /// the network to acknowledge a tap makes the list feel broken, and being
  /// wrong for a moment is cheaper than being slow every time.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead || marking.contains(notification.id)) return;

    final index = notifications.indexWhere(
      (item) => item.id == notification.id,
    );
    if (index < 0) return;

    marking.add(notification.id);
    errorMessage.value = '';

    notifications[index] = notifications[index].copyWith(isRead: true);
    final previousUnread = unreadCount.value;
    unreadCount.value = (previousUnread - 1).clamp(0, previousUnread);

    final result = await _interface().markRead(notification.id);

    result.fold(
      (failure) {
        errorMessage.value = failure.uiMessage;
        final current = notifications.indexWhere(
          (item) => item.id == notification.id,
        );
        if (current >= 0) {
          notifications[current] = notifications[current].copyWith(
            isRead: false,
          );
        }
        unreadCount.value = previousUnread;
      },
      // A server-reported count wins over the local decrement, which is only
      // an estimate of what the rest of the feed looks like.
      (success) {
        final reported = success.data;
        if (reported != null) unreadCount.value = reported;
      },
    );

    marking.remove(notification.id);
  }

  /// Marks every notification read.
  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;

    final previous = notifications.toList(growable: false);
    final previousUnread = unreadCount.value;

    notifications.assignAll([
      for (final item in previous) item.copyWith(isRead: true),
    ]);
    unreadCount.value = 0;

    final result = await _interface().markAllRead();

    result.fold((failure) {
      errorMessage.value = failure.uiMessage;
      notifications.assignAll(previous);
      unreadCount.value = previousUnread;
    }, (_) {});
  }
}
