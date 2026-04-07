import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  test('ApiService exposes configurable base URL with local-safe default', () {
    expect(
      ApiService.baseUrl,
      equals(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000/api/v1',
        ),
      ),
    );
  });
}
