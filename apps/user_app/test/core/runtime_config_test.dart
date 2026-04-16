import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/config/runtime_config.dart';

void main() {
	test('reads runtime values from .env when present', () {
		dotenv.loadFromString(
			envString: '''
BACKEND_API_URL=https://staging.example.com/api/v1
SUPPORT_EMAIL=help@example.com
SUPPORT_EMAIL_SUBJECT=Need help
SUPPORT_PHONE=+15551234567
SUPPORT_PHONE_DISPLAY=+1 555-123-4567
RAZORPAY_KEY_ID=rzp_test_123
''',
		);

		expect(RuntimeConfig.backendApiUrl, 'https://staging.example.com/api/v1');
		expect(RuntimeConfig.supportEmail, 'help@example.com');
		expect(RuntimeConfig.supportEmailSubject, 'Need help');
		expect(RuntimeConfig.supportPhone, '+15551234567');
		expect(RuntimeConfig.supportPhoneDisplay, '+1 555-123-4567');
		expect(RuntimeConfig.razorpayKeyId, 'rzp_test_123');
	});

	test('falls back to localhost-safe defaults when .env is absent', () {
		dotenv.loadFromString(envString: '', isOptional: true);

		expect(RuntimeConfig.backendApiUrl, 'http://localhost:3000/api/v1');
		expect(RuntimeConfig.supportEmail, 'support@example.com');
		expect(RuntimeConfig.supportEmailSubject, 'Support Request');
		expect(RuntimeConfig.supportPhone, '+10000000000');
		expect(RuntimeConfig.supportPhoneDisplay, '+1 000-000-0000');
		expect(RuntimeConfig.razorpayKeyId, '');
	});
}
