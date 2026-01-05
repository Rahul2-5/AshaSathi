import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/auth/cubit/signup_state.dart';
import 'package:frontend/services/auth_service.dart';

class SignupCubit extends Cubit<SignupState> {
  final AuthService authService;

  SignupCubit(this.authService) : super(SignupState());

  Future<void> signup(Map<String, dynamic> data) async {
    emit(state.copyWith(isLoading: true, error: null, isSuccess: false));

    try {
      await authService.createUser(data);
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString().replaceAll('Exception:', '').trim(),
        ),
      );
    }
  }
}
