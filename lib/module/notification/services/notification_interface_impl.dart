import 'package:app_pigeon/app_pigeon.dart';

import '../../../core/api_handler/success.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/helpers/typedefs.dart';
import '../model/notification_model.dart';
import 'notification_interface.dart';

final class NotificationInterfaceImpl extends NotificationInterface {
  NotificationInterfaceImpl(this.appPigeon);

  final AuthorizedPigeon appPigeon;

  @override
  FutureRequest<Success<NotificationFeed>> notifications({
    int page = 1,
    int limit = 30,
  }) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.get(
          ApiEndpoints.notifications(page: page, limit: limit),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          // `data` is handed over whole rather than coerced to a Map: this
          // route may answer with the array alone, and the feed knows how to
          // read either shape.
          data: NotificationFeed.fromJson(body['data']),
        );
      },
    );
  }

  @override
  FutureRequest<Success<int?>> markRead(String notificationId) async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.patch(
          ApiEndpoints.markNotificationRead(notificationId: notificationId),
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        final data = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : <String, dynamic>{};

        final unread = data['unreadCount'] ?? data['unread'];

        return Success(
          message: body['message']?.toString() ?? 'Success',
          // Null when the backend only acknowledges the call, which tells the
          // controller to decrement its own count instead of trusting a zero.
          data: unread is num ? unread.toInt() : null,
        );
      },
    );
  }

  @override
  FutureRequest<Success<NoData>> markAllRead() async {
    return await asyncTryCatch(
      tryFunc: () async {
        final response = await appPigeon.patch(
          ApiEndpoints.markAllNotificationsRead,
        );

        final body = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};

        return Success(
          message: body['message']?.toString() ?? 'Success',
          data: NoData(),
        );
      },
    );
  }
}
