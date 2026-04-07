import 'package:admin_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiClient uses environment-configurable base URL with local default', () {
    expect(
      ApiClient.instance.dio.options.baseUrl,
      equals('http://localhost:3000/api/v1'),
    );
  });
}
