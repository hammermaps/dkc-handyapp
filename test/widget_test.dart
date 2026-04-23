// DKC HandyApp – Unit Tests
// Run with: flutter test
// Note: Generated files (*.g.dart, *.freezed.dart) must be created first via:
//   flutter pub run build_runner build --delete-conflicting-outputs

import 'package:dkc_handyapp/core/api/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException hierarchy', () {
    test('UnauthorizedException has code 401', () {
      const e = UnauthorizedException();
      expect(e.code, 401);
      expect(e.message, isNotEmpty);
    });

    test('ForbiddenException has code 403', () {
      const e = ForbiddenException();
      expect(e.code, 403);
    });

    test('NotFoundException has code 404', () {
      const e = NotFoundException();
      expect(e.code, 404);
    });

    test('RateLimitException has code 429 and exposes retryAfterSeconds', () {
      const e = RateLimitException(retryAfterSeconds: 30);
      expect(e.code, 429);
      expect(e.retryAfterSeconds, 30);
      expect(e.toString(), contains('30'));
    });

    test('ServerException carries custom message', () {
      const e = ServerException(code: 503, message: 'Service Unavailable');
      expect(e.code, 503);
      expect(e.message, 'Service Unavailable');
    });

    test('NetworkException defaults to offline message', () {
      const e = NetworkException();
      expect(e.message, isNotEmpty);
    });
  });
}
