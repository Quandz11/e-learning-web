import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AuthFormState {
  const AuthFormState({this.loading = false, this.error});

  final bool loading;
  final String? error;

  AuthFormState copyWith({bool? loading, String? error}) {
    return AuthFormState(loading: loading ?? this.loading, error: error);
  }
}

class AuthFormController extends StateNotifier<AuthFormState> {
  AuthFormController() : super(const AuthFormState());

  void setLoading(bool loading) {
    state = state.copyWith(loading: loading, error: null);
  }

  void setError(String message) {
    state = state.copyWith(loading: false, error: message);
  }
}

final authFormControllerProvider =
    StateNotifierProvider<AuthFormController, AuthFormState>(
      (_) => AuthFormController(),
    );
