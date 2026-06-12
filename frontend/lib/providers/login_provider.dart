import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginState {
  final bool isLoading;
  final String? error;
  final String? token;

  LoginState({
    this.isLoading = false,
    this.error,
    this.token,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    String? token,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
    );
  }

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService authService;

  LoginNotifier(this.authService) : super(LoginState());

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await authService.login({
        'email': email.trim(),
        'password': password.trim(),
      });

      await _saveToken(token);
      state = state.copyWith(isLoading: false, token: token);
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> setToken(String token) async {
    await _saveToken(token);
    state = state.copyWith(
      token: token,
      isLoading: false,
      error: null,
    );
  }

  Future<void> logout() async {
    await authService.logout();
    await _clearToken();
    state = LoginState();
  }

  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true;
      }

      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! num) {
        return true;
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  Future<String?> getValidToken() async {
    final currentToken = state.token;
    if (currentToken != null && currentToken.isNotEmpty) {
      if (!_isJwtExpired(currentToken)) {
        return currentToken;
      }

      await logout();
      return null;
    }

    final savedToken = await loadSavedToken();
    if (savedToken == null || savedToken.isEmpty) {
      return null;
    }

    if (_isJwtExpired(savedToken)) {
      await _clearToken();
      state = LoginState();
      return null;
    }

    state = state.copyWith(token: savedToken);
    return savedToken;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> initializeAuth() async {
    final savedToken = await loadSavedToken();
    if (savedToken != null && savedToken.isNotEmpty && !_isJwtExpired(savedToken)) {
      state = state.copyWith(token: savedToken);
      return;
    }

    if (savedToken != null) {
      await _clearToken();
    }
  }
}

final loginProvider = StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LoginNotifier(authService);
});
