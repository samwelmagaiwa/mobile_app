import 'dart:async';
import 'dart:io';

import 'package:boda_mapato/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService.isSessionInvalid', () {
    test('a 401 from the server means the session is over', () {
      expect(AuthService.isSessionInvalid(AuthHttpException(401, 'Unauthenticated.')),
          isTrue);
    });

    test('server errors and other statuses do not end the session', () {
      for (final int code in <int>[400, 403, 404, 422, 429, 500, 502, 503, 504]) {
        expect(AuthService.isSessionInvalid(AuthHttpException(code, 'x')), isFalse,
            reason: 'HTTP $code must not sign the user out');
      }
    });

    test('a timeout or no connection does not end the session', () {
      expect(AuthService.isSessionInvalid(TimeoutException('slow')), isFalse);
      expect(AuthService.isSessionInvalid(const SocketException('no route')), isFalse);
      expect(AuthService.isSessionInvalid(Exception('Failed to get user data: x')),
          isFalse);
    });
  });

  test('AuthHttpException prints like the plain Exception it replaces', () {
    expect(AuthHttpException(401, 'Unauthenticated.').toString(),
        'Exception: Unauthenticated.');
  });
}
