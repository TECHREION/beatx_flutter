import 'package:beatx_flutter/module/auth/model/signup_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends only what the register route accepts', () {
    final body = SignupModel(
      username: ' Akon ',
      email: ' a@b.co ',
      phoneNumber: '',
      password: 'password1',
      confirmPassword: 'password1',
    ).toMap();

    expect(body, {
      'name': 'Akon',
      'email': 'a@b.co',
      'password': 'password1',
      'role': 'user',
    });
  });
}
