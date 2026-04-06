import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  test('ApiService exposes configurable base URL with production default', () {
    expect(
      ApiService.baseUrl,
      equals(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://swift-campus.vercel.app/api/v1',
        ),
      ),
    );
  });
}
