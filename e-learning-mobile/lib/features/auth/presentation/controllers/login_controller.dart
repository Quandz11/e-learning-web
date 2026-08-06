import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/login_request.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/login_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
      return LoginController(
        authRepository: ref.read(authRepositoryProvider),
        sessionController: ref.read(sessionControllerProvider.notifier),
      );
    });

class LoginController extends StateNotifier<LoginState> {
  LoginController({
    required AuthRepository authRepository,
    required SessionController sessionController,
  }) : _authRepository = authRepository,
       _sessionController = sessionController,
       super(const LoginState());

  final AuthRepository _authRepository;
  final SessionController _sessionController;

  Future<void> submit({
    required String email,
    required String password,
    String? redirectPath,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    final normalizedEmail = email.trim();
    final emailError = _validateEmail(normalizedEmail);
    final passwordError = _validatePassword(password);

    if (emailError != null || passwordError != null) {
      state = LoginState(
        status: LoginStatus.failure,
        emailError: emailError,
        passwordError: passwordError,
      );
      return;
    }

    state = const LoginState(status: LoginStatus.submitting);

    try {
      final result = await _authRepository.login(
        LoginRequest(email: normalizedEmail, password: password),
      );

      if (result.requiresTwoFactor) {
        final preAuthAccessToken = result.preAuthAccessToken?.trim() ?? '';
        if (preAuthAccessToken.isEmpty) {
          state = const LoginState(
            status: LoginStatus.failure,
            generalMessage: 'Phản hồi đăng nhập chưa đầy đủ. Vui lòng thử lại.',
          );
          return;
        }
        state = LoginState(
          status: LoginStatus.twoFactorRequired,
          pendingChallenge: AuthOtpChallenge.loginTwoFactor(
            email: normalizedEmail,
            preAuthAccessToken: preAuthAccessToken,
            displayMessage:
                result.message ?? 'Nhập mã xác thực từ ứng dụng của bạn.',
            redirectPath: redirectPath,
          ),
          generalMessage:
              result.message ?? 'Bạn cần xác thực hai lớp để tiếp tục.',
        );
        return;
      }

      final session = result.session;
      if (session == null) {
        state = const LoginState(
          status: LoginStatus.failure,
          generalMessage: 'Phản hồi đăng nhập chưa đầy đủ.',
        );
        return;
      }

      _sessionController.syncSession(session);
      state = const LoginState(status: LoginStatus.success);
    } on AppFailure catch (failure) {
      final mapped = _mapFailure(failure);
      state = LoginState(
        status: LoginStatus.failure,
        emailError: mapped.emailError,
        passwordError: mapped.passwordError,
        generalMessage: mapped.generalMessage,
      );
    }
  }

  void onEmailChanged() {
    if (state.emailError == null && state.generalMessage == null) {
      return;
    }
    state = state.copyWith(
      status: LoginStatus.idle,
      clearEmailError: true,
      clearGeneralMessage: true,
      clearPendingChallenge: true,
    );
  }

  void onPasswordChanged() {
    if (state.passwordError == null && state.generalMessage == null) {
      return;
    }
    state = state.copyWith(
      status: LoginStatus.idle,
      clearPasswordError: true,
      clearGeneralMessage: true,
      clearPendingChallenge: true,
    );
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Vui lòng nhập email.';
    }

    const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    final isValid = RegExp(emailPattern).hasMatch(email);
    if (!isValid) {
      return 'Email không hợp lệ.';
    }

    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu.';
    }
    return null;
  }

  _MappedFailure _mapFailure(AppFailure failure) {
    final validationErrors = failure.validationErrors ?? const {};
    String? emailError;
    String? passwordError;
    final generalMessages = <String>[];

    for (final entry in validationErrors.entries) {
      final key = entry.key.toLowerCase();
      final message = entry.value
          .where((item) => item.trim().isNotEmpty)
          .join(' ');
      if (message.isEmpty) {
        continue;
      }
      if (key == 'email') {
        emailError = message;
      } else if (key == 'password') {
        passwordError = message;
      } else {
        generalMessages.add(message);
      }
    }

    final generalMessage = generalMessages.isNotEmpty
        ? generalMessages.join(' ')
        : failure.message;

    return _MappedFailure(
      emailError: emailError,
      passwordError: passwordError,
      generalMessage: generalMessage,
    );
  }
}

class _MappedFailure {
  const _MappedFailure({
    this.emailError,
    this.passwordError,
    this.generalMessage,
  });

  final String? emailError;
  final String? passwordError;
  final String? generalMessage;
}
