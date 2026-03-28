import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/config/runtime_config.dart';

void main() {
  test('RuntimeConfig reads compile-time dart defines', () {
    const expectedUrl = String.fromEnvironment('SUPABASE_URL');
    const expectedAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (expectedUrl.isEmpty || expectedAnonKey.isEmpty) {
      expect(
        () => RuntimeConfig.fromEnvironment(),
        throwsA(isA<StateError>()),
      );
      return;
    }

    final config = RuntimeConfig.fromEnvironment();

    expect(config.supabaseUrl, expectedUrl);
    expect(config.supabaseAnonKey, expectedAnonKey);
  });
}
