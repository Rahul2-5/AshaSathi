import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final String baseUrl = AppConfig.authBaseUrl;

  String? _cachedGoogleClientId;
  GoogleSignIn? _googleSignIn;

  Future<String> login(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['token'] as String;
    }

    final error = response.body.trim();

    if (response.statusCode == 401) {
      if (error == 'INVALID_PASSWORD') {
        throw Exception('Invalid password');
      }

      if (error == 'EMAIL_NOT_FOUND') {
        throw Exception('Email not found. Create a new account');
      }
    }

    throw Exception('Login failed. Try again');
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Signup failed. Try again');
    }
  }

  Uri get _googleLoginUri =>
      Uri.parse('${AppConfig.googleAuthBaseUrl}/api/auth/google');

  Uri get _googleClientIdUri =>
      Uri.parse('${AppConfig.googleAuthBaseUrl}/api/auth/google/client-id');

  Future<String?> _fetchGoogleClientId() async {
    if (_cachedGoogleClientId != null) {
      return _cachedGoogleClientId!.trim().isEmpty
          ? null
          : _cachedGoogleClientId!.trim();
    }

    final fallbackClientId = AppConfig.googleWebClientId.trim();
    if (fallbackClientId.isNotEmpty) {
      _cachedGoogleClientId = fallbackClientId;
      return fallbackClientId;
    }

    try {
      final response = await http.get(_googleClientIdUri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final clientId = decoded is Map<String, dynamic>
            ? (decoded['clientId']?.toString().trim() ?? '')
            : '';
        _cachedGoogleClientId = clientId;
        return clientId.isEmpty ? null : clientId;
      }
    } catch (_) {}

    _cachedGoogleClientId = '';
    return null;
  }

  GoogleSignIn _buildGoogleSignIn({String? clientId}) {
    final trimmedClientId = clientId?.trim() ?? '';
    if (trimmedClientId.isEmpty) {
      return GoogleSignIn(scopes: ['email', 'profile']);
    }

    if (kIsWeb) {
      return GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: trimmedClientId,
        serverClientId: trimmedClientId,
      );
    }

    return GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: trimmedClientId,
    );
  }

  Future<GoogleSignIn> _googleSignInInstance() async {
    final clientId = await _fetchGoogleClientId();
    final current = _googleSignIn;
    if (current != null && _cachedGoogleClientId == clientId) {
      return current;
    }

    final signIn = _buildGoogleSignIn(clientId: clientId);
    _googleSignIn = signIn;
    return signIn;
  }

  Future<String> loginWithGoogle() async {
    try {
      final googleSignIn = await _googleSignInInstance();
      final user = await googleSignIn.signIn();
      if (user == null) {
        throw Exception('Google login cancelled');
      }

      final auth = await user.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        final backendClientId = await _fetchGoogleClientId();
        final backendHint = backendClientId == null
            ? ' Heroku is missing GOOGLE_CLIENT_ID for the Google OAuth backend.'
            : '';
        throw Exception(
          'Google did not return an ID token or access token.$backendHint\n'
          'Most likely missing Android Google Sign-In setup:\n'
          '- `frontend/android/app/google-services.json` is empty or not the real file.\n'
          '- The Android `applicationId` should be `com.ashasathi.frontend` and must match the OAuth client.\n'
          '- The OAuth client package name / SHA-1 / SHA-256 in Google Cloud does not match this build.\n'
          'The Android client ID from Google Cloud is not the same as the web/server client ID used for `serverClientId` and backend token validation.\n'
          'If you are running web, provide `GOOGLE_WEB_CLIENT_ID` or set `GOOGLE_AUTH_BASE_URL` to the Heroku backend.'
        );
      }

      final payload = <String, dynamic>{
        if (idToken != null && idToken.isNotEmpty) 'idToken': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'accessToken': accessToken,
      };

      final response = await http.post(
        _googleLoginUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['token'] as String;
      }

      final backendError = response.body.trim().isEmpty
          ? 'HTTP ${response.statusCode}'
          : response.body.trim();
      throw Exception('Google login failed on backend: $backendError');
    } on PlatformException catch (e) {
      final code = e.code;
      final details =
          e.message ?? e.details?.toString() ?? 'Unknown platform error';

      if (code == 'sign_in_failed' || code == '10') {
        throw Exception(
          'Google Sign-In configuration error. Common fixes:\n'
          '- Ensure android/app/google-services.json is present and valid for this app id.\n'
          "- Register an OAuth client for this app's package name and SHA-1/SHA-256 in Google Cloud Console.\n"
          "- Provide the web client ID via --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id.apps.googleusercontent.com when running the app or set AppConfig accordingly.\n"
          'Details: $details',
        );
      }

      throw Exception('Google Sign-In platform error ($code): $details');
    } catch (e) {
      throw Exception('Google login exception: $e');
    }
  }

  Future<void> loginWithGithub() async {
    const clientId = AppConfig.githubClientId;
    if (clientId.isEmpty) {
      throw Exception('GitHub login is not configured');
    }

    final redirectUri = Uri.encodeComponent('${AppConfig.authBaseUrl}/github/callback');
    final url =
        'https://github.com/login/oauth/authorize'
        '?client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&scope=read:user%20user:email';

    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch GitHub login');
    }
  }

  Future<void> logout() async {
    try {
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
    } catch (_) {}
  }
}
