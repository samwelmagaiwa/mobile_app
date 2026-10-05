import 'package:boda_mapato/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService.tokenFromRefreshResponse', () {
    test('reads the token the server nests under data', () {
      expect(
        AuthService.tokenFromRefreshResponse(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{'token': '12|abc'},
        }),
        '12|abc',
      );
    });

    test('still accepts a top-level token', () {
      expect(
        AuthService.tokenFromRefreshResponse(<String, dynamic>{'token': 'xyz'}),
        'xyz',
      );
    });

    test('returns null when there is no usable token', () {
      expect(AuthService.tokenFromRefreshResponse(<String, dynamic>{}), isNull);
      expect(
        AuthService.tokenFromRefreshResponse(<String, dynamic>{
          'data': <String, dynamic>{'token': ''},
        }),
        isNull,
      );
      expect(
        AuthService.tokenFromRefreshResponse(<String, dynamic>{
          'data': <String, dynamic>{'token': 42},
        }),
        isNull,
      );
    });
  });
}
