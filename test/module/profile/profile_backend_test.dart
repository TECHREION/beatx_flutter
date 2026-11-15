import 'package:beatx_flutter/module/profile/model/legal_page_model.dart';
import 'package:beatx_flutter/module/profile/model/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone accounts hide the placeholder email and have no password', () {
    final phone = UserProfileModel.fromJson({
      '_id': 'u1',
      'email': '8801712345678@phone.beatx.invalid',
      'provider': 'phone',
    });
    expect(phone.displayEmail, isEmpty);
    expect(phone.hasPassword, isFalse);

    final local = UserProfileModel.fromJson({
      '_id': 'u2',
      'email': 'a@b.com',
      'provider': 'local',
    });
    expect(local.displayEmail, 'a@b.com');
    expect(local.hasPassword, isTrue);

    expect(
      UserProfileModel.fromJson({'provider': 'google'}).hasPassword,
      isFalse,
    );
  });

  test('legal markdown reads as plain text', () {
    final page = LegalPage.fromJson({
      'slug': 'terms',
      'title': 'Terms',
      'body': '# Terms\n\n- **Use** the [app](https://x.y) fairly\n'
          'snake_case stays',
      'updatedAt': '2026-11-01T00:00:00.000Z',
    });
    expect(page.plainText, 'Terms\n\n• Use the app fairly\nsnake_case stays');
    expect(page.updatedAt, isNotNull);
  });
}
