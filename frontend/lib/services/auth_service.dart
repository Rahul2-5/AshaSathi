import 'dart:convert';
import 'package:frontend/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthService {
  final String baseUrl = AppConfig.authBaseUrl;

  // ------------------ EMAIL LOGIN ------------------
  // ✅ MUST RETURN TOKEN (String)
Future<String> login(Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/login');

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(data),
  );

  // ✅ SUCCESS
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    return body['token'];
  }

  // ✅ ERROR HANDLING
  final error = response.body.trim();

  if (response.statusCode == 401) {
    if (error == "INVALID_PASSWORD") {
      throw Exception("Invalid password");
    }

    if (error == "EMAIL_NOT_FOUND") {
      throw Exception("Email not found. Create a new account");
    }
  }

  throw Exception("Login failed. Try again");
}



  // ------------------ SIGNUP ------------------
  Future<void> createUser(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/signup');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Signup failed. Try again");
    }
  }

  // ------------------ GOOGLE LOGIN ------------------
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<String> loginWithGoogle() async {
    final user = await _googleSignIn.signIn();
    if (user == null) throw Exception("Google login cancelled");

    final uri = Uri.parse("$baseUrl/google").replace(
      queryParameters: {
        "email": user.email,
        "username": user.displayName ?? "Google User",
      },
    );

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['token']; // ✅ RETURN TOKEN
    } else {
      throw Exception("Google login failed");
    }
  }

  // ------------------ GITHUB LOGIN ------------------
  Future<void> loginWithGithub() async {
    const clientId = "YOUR_GITHUB_CLIENT_ID";
    final redirectUri = "${AppConfig.authBaseUrl}/github/callback";

    final url =
        "https://github.com/login/oauth/authorize"
        "?client_id=$clientId"
        "&redirect_uri=$redirectUri"
        "&scope=read:user user:email";

    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch GitHub login");
    }
  }

  // ------------------ LOGOUT ------------------
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
