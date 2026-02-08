import 'package:flutter_bloc/flutter_bloc.dart';
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
  void setToken(String token) {
    emit(
      state.copyWith(
        token: token,
        isLoading: false,
        error: null,
      ),
    );
  }

  // 🚪 Logout (optional but recommended)
  void logout() {
    emit(LoginState());
  }
}
