import 'package:admin_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ApiClient uses live production base URL', () {
    expect(
      ApiClient.instance.dio.options.baseUrl,
      equals('https://swift-campus.vercel.app/api/v1'),
    );
  });
}
