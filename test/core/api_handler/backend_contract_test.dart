import 'package:beatx_flutter/core/api_handler/base_repository.dart';
import 'package:beatx_flutter/core/api_handler/paged_result.dart';
import 'package:beatx_flutter/core/constants/api_endpoints.dart';
import 'package:beatx_flutter/core/helpers/onboarding_gate.dart';
import 'package:beatx_flutter/core/network/notification_socket.dart';
import 'package:beatx_flutter/module/auth/model/login_request_model.dart';
import 'package:beatx_flutter/module/auth/services/onboarding_service.dart';
import 'package:beatx_flutter/module/notification/model/notification_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Repo extends BaseRepository {}

Response<dynamic> _response(Object? data) => Response(
  requestOptions: RequestOptions(path: '/x'),
  data: data,
);

void main() {
  group('envelope', () {
    test('success message is read from the `status` flag', () {
      final repo = _Repo();
      expect(
        repo.extractSuccessMessage(
          _response({'status': true, 'message': 'Saved', 'data': null}),
        ),
        'Saved',
      );
      expect(
        repo.extractSuccessMessage(
          _response({'status': false, 'message': 'Nope', 'data': null}),
        ),
        isNull,
      );
    });

    test('paged episodes nested under data.data are found', () {
      expect(
        pagedEntries({
          'data': [
            {'_id': 'e1'},
          ],
          'total': 1,
        }),
        hasLength(1),
      );
    });
  });

  group('login body', () {
    test('sends only contract fields', () {
      final body = LoginRequestModel(
        email: ' User@Example.com ',
        password: 'secret123',
        rememberMe: true,
      ).toJson();
      expect(body, {
        'email': 'user@example.com',
        'password': 'secret123',
        'rememberMe': true,
      });
    });

    test('omits rememberMe when off', () {
      expect(
        LoginRequestModel(email: 'a@b.c', password: 'p').toJson().keys,
        isNot(contains('rememberMe')),
      );
    });
  });

  group('onboarding gate', () {
    tearDown(OnboardingGate.clear);

    test('only an explicit false asks for onboarding, once', () {
      OnboardingGate.recordSignIn({'onboardingCompleted': false});
      expect(OnboardingGate.takePending(), isTrue);
      expect(OnboardingGate.takePending(), isFalse);
    });

    test('artists and admins (no field) skip it', () {
      OnboardingGate.recordSignIn({'role': 'artist'});
      expect(OnboardingGate.takePending(), isFalse);
    });
  });

  group('notifications', () {
    test('kind comes from `category`, routing fields are kept', () {
      final item = AppNotification.fromJson({
        '_id': 'n1',
        'category': 'tickets',
        'title': 'Ticket confirmed',
        'targetType': 'ticket',
        'targetId': {'_id': 't9'},
        'metadata': {'bookingRef': 'BXT-0007'},
        'read': false,
      });
      expect(item.type, NotificationType.tickets);
      expect(item.targetType, 'ticket');
      expect(item.targetId, 't9');
      expect(item.metadata['bookingRef'], 'BXT-0007');
      expect(item.copyWith(isRead: true).targetId, 't9');
    });

    test('socket targets the namespace under the API origin', () {
      final socket = NotificationSocket(
        origin: ApiEndpoints.socketUrl,
        path: ApiEndpoints.socketPath,
        accessToken: () async => null,
      );
      expect(socket.namespaceUrl, 'https://fahimstack.tech/notifications');
      expect(ApiEndpoints.socketPath, '/beatx-api/socket.io');
    });
  });

  group('onboarding rows', () {
    test('artist prefers the stage name and artist avatar', () {
      final artist = OnboardingArtist.fromJson({
        '_id': 'a1',
        'name': 'Account Name',
        'stageName': 'Stage',
        'avatar': 'https://x/avatar.webp',
      });
      expect(artist.name, 'Stage');
      expect(artist.avatar, 'https://x/avatar.webp');
    });
  });
}
