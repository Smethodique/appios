class EnvConfig {
  static Future<void> load() async {}

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.drimaneelmakhloufi.com/api',
  );

  static const String pusherAppKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: '9cdaa8fc04899249c290',
  );

  static const String pusherCluster = String.fromEnvironment(
    'PUSHER_CLUSTER',
    defaultValue: 'eu',
  );

  static const String pusherAuthEndpoint = String.fromEnvironment(
    'PUSHER_AUTH_ENDPOINT',
    defaultValue: 'https://app.drimaneelmakhloufi.com/api/broadcasting/auth',
  );

  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '6ed7f0a9-9a7e-44b7-8517-59eb770c489f',
  );
}
