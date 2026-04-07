class RuntimeConfig {
  RuntimeConfig({
    required this.backendApiUrl,
  });

  final String backendApiUrl;

  factory RuntimeConfig.fromEnvironment() {
    const backendApiUrl = String.fromEnvironment(
      'BACKEND_API_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    );

    if (backendApiUrl.isEmpty) {
      throw StateError(
        'Missing BACKEND_API_URL environment variable. Set it via --dart-define or .env file.',
      );
    }

    return RuntimeConfig(
      backendApiUrl: backendApiUrl,
    );
  }
}
