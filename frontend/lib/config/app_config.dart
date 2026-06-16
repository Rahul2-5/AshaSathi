class AppConfig {
  static const String productionApiBaseUrl =
      'https://ashasathi-backend-44448212683b.herokuapp.com';

  // Defaults to the production Heroku backend so a plain `flutter run` and any
  // built APK work out of the box. Override for local backend testing using:
  // --dart-define=API_BASE_URL=http://10.0.2.2:8080   (Android emulator)
  // --dart-define=API_BASE_URL=http://192.168.x.x:8080 (physical device)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionApiBaseUrl,
  );

  static String get authBaseUrl => '$apiBaseUrl/api/auth';
  static String get googleAuthBaseUrl =>
      String.fromEnvironment(
        'GOOGLE_AUTH_BASE_URL',
        defaultValue: productionApiBaseUrl,
      );
  static String get patientsBaseUrl => '$apiBaseUrl/api/patients';
  static String get tasksBaseUrl => '$apiBaseUrl/api/tasks';

  // Optional override to stabilize Google Sign-In across Android/Web.
  // Example:
  // --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '343345849482-6tepsl4rnfr2st7jlea7qh79q2j56no3.apps.googleusercontent.com',
  );

  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
    defaultValue: '',
  );
}
