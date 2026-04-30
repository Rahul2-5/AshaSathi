import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:frontend/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final String baseUrl = AppConfig.authBaseUrl;

  late final GoogleSignIn _googleSignIn = _buildGoogleSignIn();

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

  GoogleSignIn _buildGoogleSignIn() {
    final webClientId = AppConfig.googleWebClientId.trim();
    if (webClientId.isEmpty) {
      return GoogleSignIn(scopes: ['email', 'profile']);
    }

    return GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: webClientId,
      serverClientId: webClientId,
    );
  }

  Future<String> loginWithGoogle() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        throw Exception('Google login cancelled');
      }

      final auth = await user.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
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
          'Google Sign-In configuration error. Verify Android package name, SHA-1/SHA-256, and OAuth client ID. Details: $details',
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
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
