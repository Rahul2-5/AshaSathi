import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/services/auth_service.dart';

// ==================== SIGNUP STATE ====================
class SignupState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  SignupState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  SignupState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return SignupState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ==================== SIGNUP SERVICE PROVIDER ====================
final signupServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ==================== SIGNUP NOTIFIER ====================
class SignupNotifier extends StateNotifier<SignupState> {
  final AuthService authService;

  SignupNotifier(this.authService) : super(SignupState());

  Future<void> signup(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await authService.createUser(data);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  void reset() {
    state = SignupState();
  }
}

// ==================== SIGNUP PROVIDER ====================
final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>((ref) {
  final authService = ref.watch(signupServiceProvider);
  return SignupNotifier(authService);
});
