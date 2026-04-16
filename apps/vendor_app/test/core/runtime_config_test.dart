import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor_app/core/config/runtime_config.dart';

void main() {
  test('reads API base URL and demo credentials from .env', () {
    dotenv.loadFromString(
      envString: '''
API_BASE_URL=https://vendor.example.com/api/v1
DEMO_VENDOR_EMAIL=vendor@example.com
DEMO_VENDOR_PASSWORD=secret
''',
    );

    expect(RuntimeConfig.apiBaseUrl, 'https://vendor.example.com/api/v1');
    expect(RuntimeConfig.demoVendorEmail, 'vendor@example.com');
    expect(RuntimeConfig.demoVendorPassword, 'secret');
  });

  test('falls back to localhost-safe defaults when .env is absent', () {
    dotenv.loadFromString(envString: '', isOptional: true);

    expect(RuntimeConfig.apiBaseUrl, 'http://localhost:3000/api/v1');
    expect(RuntimeConfig.demoVendorEmail, '');
    expect(RuntimeConfig.demoVendorPassword, '');
  });
}