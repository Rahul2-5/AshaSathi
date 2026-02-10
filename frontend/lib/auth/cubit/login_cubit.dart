import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_state.dart';
import '../../services/auth_service.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService authService;

  LoginCubit(this.authService) : super(LoginState());

  // 🔐 Normal login
  Future<void> login({
  required String email,
  required String password,
}) async {
  emit(state.copyWith(isLoading: true, error: null));

  try {
    final token = await authService.login({
      "email": email.trim(),
      "password": password.trim(),
    });

    // 💾 Save token to shared_preferences
    await _saveToken(token);
    emit(state.copyWith(isLoading: false, token: token));
  } catch (e) {
    final message =
        e.toString().replaceAll('Exception:', '').trim();

    if (message.toLowerCase().contains("email not found")) {
      try {
        await authService.createUser({
          "email": email.trim(),
          "password": password.trim(),
          "username": email.split('@')[0],
        });

        final token = await authService.login({
          "email": email.trim(),
          "password": password.trim(),
        });

        // 💾 Save token to shared_preferences
        await _saveToken(token);
        emit(state.copyWith(isLoading: false, token: token));
        return;
      } catch (_) {
        emit(state.copyWith(
          isLoading: false,
          error: "Account creation failed",
        ));
        return;
      }
    }

    emit(state.copyWith(isLoading: false, error: message));
  }
}


  // 🔑 Google / GitHub login
  Future<void> setToken(String token) async {
    // 💾 Save token to shared_preferences
    await _saveToken(token);
    emit(
      state.copyWith(
        token: token,
        isLoading: false,
        error: null,
      ),
    );
  }

  // 🚪 Logout
  Future<void> logout() async {
    // 🗑️ Clear token from shared_preferences
    await _clearToken();
    emit(LoginState());
  }

  // 💾 Save token to persistent storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // 📂 Load token from persistent storage
  Future<String?> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // 🗑️ Clear token from persistent storage
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ⚡ Initialize - Load saved token on app startup
  Future<void> initializeAuth() async {
    final savedToken = await loadSavedToken();
    if (savedToken != null) {
      emit(state.copyWith(token: savedToken));
    }
  }
}
