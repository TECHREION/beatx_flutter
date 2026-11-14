import 'package:beatx_flutter/core/api_handler/success.dart';
import 'package:beatx_flutter/core/helpers/typedefs.dart';
import 'package:beatx_flutter/module/notification/controller/notification_controller.dart';
import 'package:beatx_flutter/module/notification/model/notification_model.dart';
import 'package:beatx_flutter/module/notification/services/notification_interface.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _Fake extends NotificationInterface {
  @override
  FutureRequest<Success<NotificationFeed>> notifications({
    int page = 1,
    int limit = 30,
  }) async => Right(
    Success(
      data: NotificationFeed.fromJson({
        'notifications': [
          {'_id': 'old', 'title': 'Old', 'read': false},
        ],
        'total': 1,
      }),
    ),
  );

  @override
  FutureRequest<Success<int>> unreadCount() async => Right(Success(data: 7));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<NotificationInterface>(_Fake());
  });
  tearDown(Get.reset);

  test('badge uses the server-wide unread counter', () async {
    final controller = NotificationController();
    await controller.fetch();
    expect(controller.notifications, hasLength(1));
    expect(controller.unreadCount.value, 7);
  });

  test('a socket push goes on top and takes the pushed counter', () async {
    final controller = NotificationController();
    await controller.fetch();
    controller.onPushed({
      'notification': {'_id': 'new', 'title': 'New', 'category': 'music'},
      'unreadCount': 8,
    });
    expect(controller.notifications.first.id, 'new');
    expect(controller.notifications.first.type, NotificationType.song);
    expect(controller.unreadCount.value, 8);

    // A repeated push does not duplicate the row.
    controller.onPushed({
      'notification': {'_id': 'new', 'title': 'New'},
      'unreadCount': 8,
    });
    expect(controller.notifications, hasLength(2));
  });
}
