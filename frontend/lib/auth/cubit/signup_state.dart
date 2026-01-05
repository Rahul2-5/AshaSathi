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
