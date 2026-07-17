import 'package:beatx_flutter/module/profile/model/change_password_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes change password request body', () {
    const request = ChangePasswordRequest(
      currentPassword: 'AljuAkon@123',
      newPassword: 'YounusAkon@123',
      confirmPassword: 'YounusAkon@123',
    );

    expect(request.toJson(), {
      'currentPassword': 'AljuAkon@123',
      'newPassword': 'YounusAkon@123',
      'confirmPassword': 'YounusAkon@123',
    });
  });

  test('parses change password response', () {
    final response = ChangePasswordResponse.fromJson({
      'status': true,
      'message': 'Password changed successfully',
      'data': null,
      'timestamp': '2026-07-17T05:45:34.168Z',
      'path': '/api/v1/users/change-password',
      'metadata': {'duration': '195ms'},
    });

    expect(response.status, isTrue);
    expect(response.message, 'Password changed successfully');
    expect(response.data, isNull);
    expect(response.timestamp?.year, 2026);
    expect(response.path, '/api/v1/users/change-password');
    expect(response.metadata.duration, '195ms');
  });
}
