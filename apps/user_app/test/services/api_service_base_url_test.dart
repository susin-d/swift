import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_app/services/api_service.dart';

void main() {
  test('ApiService exposes configurable base URL from .env', () {
    dotenv.loadFromString(
      envString: 'BACKEND_API_URL=https://api.example.com/api/v1',
    );

    expect(
      ApiService.baseUrl,
      equals('https://api.example.com/api/v1'),
    );
  });
}
