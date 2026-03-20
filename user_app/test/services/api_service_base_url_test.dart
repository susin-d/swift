import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  test('ApiService uses live production base URL', () {
    expect(
      ApiService.baseUrl,
      equals('https://swift-campus.vercel.app/api/v1'),
    );
  });
}
