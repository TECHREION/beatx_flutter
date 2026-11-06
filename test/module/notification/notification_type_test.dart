import 'package:beatx_flutter/module/notification/model/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every category GET /notifications can send', () {
    expect(NotificationType.fromId('music'), NotificationType.song);
    expect(NotificationType.fromId('tickets'), NotificationType.tickets);
    expect(NotificationType.fromId('rewards'), NotificationType.rewards);
    expect(NotificationType.fromId('social'), NotificationType.social);
    expect(NotificationType.fromId('system'), NotificationType.system);
  });

  test('an unknown category still shows, as general', () {
    expect(NotificationType.fromId('future'), NotificationType.general);
  });
}
