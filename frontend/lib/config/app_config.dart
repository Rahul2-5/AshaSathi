class AppConfig {
  // Override in build/run using:
  // --dart-define=API_BASE_URL=http://10.0.2.2:8080
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ashasathi-backend-44448212683b.herokuapp.com',
  );

  static String get authBaseUrl => '$apiBaseUrl/api/auth';
  static String get patientsBaseUrl => '$apiBaseUrl/api/patients';
  static String get tasksBaseUrl => '$apiBaseUrl/api/tasks';

  // Optional override to stabilize Google Sign-In across Android/Web.
  // Example:
  // --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
