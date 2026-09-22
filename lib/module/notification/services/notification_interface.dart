import '../../../core/api_handler/base_repository.dart';
import '../../../core/api_handler/success.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/notification_model.dart';

abstract base class NotificationInterface extends BaseRepository {
  /// One page of the signed-in user's notifications, newest first.
  FutureRequest<Success<NotificationFeed>> notifications({
    int page = 1,
    int limit = 30,
  });

  /// Marks one notification read. Answers the unread count left afterwards
  /// when the backend reports it.
  FutureRequest<Success<int?>> markRead(String notificationId);

  /// Marks the whole feed read.
  FutureRequest<Success<NoData>> markAllRead();
}
