import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/two_factor_login_request.dart';
import 'package:e_learning_mobile/features/auth/data/models/verify_otp_request.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/auth_otp_challenge_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/verify_otp_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final verifyOtpControllerProvider =
    StateNotifierProvider.autoDispose<VerifyOtpController, VerifyOtpState>((
      ref,
    ) {
      return VerifyOtpController(
        authRepository: ref.read(authRepositoryProvider),
        sessionController: ref.read(sessionControllerProvider.notifier),
        challengeController: ref.read(
          authOtpChallengeControllerProvider.notifier,
        ),
      );
    });

class VerifyOtpController extends StateNotifier<VerifyOtpState> {
  VerifyOtpController({
    required AuthRepository authRepository,
    required SessionController sessionController,
    required AuthOtpChallengeController challengeController,
  }) : _authRepository = authRepository,
       _sessionController = sessionController,
       _challengeController = challengeController,
       super(const VerifyOtpState());

  final AuthRepository _authRepository;
  final SessionController _sessionController;
  final AuthOtpChallengeController _challengeController;

  Future<void> submit({
    required AuthOtpChallenge challenge,
    required String otp,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    final normalizedOtp = otp.trim();
    final otpError = _validateOtp(normalizedOtp);
    if (!challenge.isValid) {
      state = const VerifyOtpState(
        status: VerifyOtpStatus.failure,
        generalMessage:
            'Your verification session is no longer available. Please sign in again.',
      );
      return;
    }

    if (otpError != null) {
      state = VerifyOtpState(
        status: VerifyOtpStatus.failure,
        otpError: otpError,
      );
      return;
    }

    state = const VerifyOtpState(status: VerifyOtpStatus.submitting);

    try {
      final result = switch (challenge.type) {
        AuthOtpChallengeType.registration => await _authRepository.verifyOtp(
          VerifyOtpRequest(email: challenge.email, otp: normalizedOtp),
        ),
        AuthOtpChallengeType.loginTwoFactor =>
          await _authRepository.verifyLoginTwoFactor(
            request: TwoFactorLoginRequest(code: normalizedOtp),
            preAuthAccessToken: challenge.preAuthAccessToken!,
          ),
      };

      final session = result.session;
      if (session == null) {
        state = const VerifyOtpState(
          status: VerifyOtpStatus.failure,
          generalMessage:
              'The verification response was incomplete. Please try again.',
        );
        return;
      }

      _sessionController.syncSession(session);
      _challengeController.clear();
      state = VerifyOtpState(
        status: VerifyOtpStatus.success,
        generalMessage: result.message,
      );
    } on AppFailure catch (failure) {
      final mapped = _mapFailure(failure);
      state = VerifyOtpState(
        status: VerifyOtpStatus.failure,
        otpError: mapped.otpError,
        generalMessage: mapped.generalMessage,
      );
    }
  }

  void onOtpChanged() {
    if (state.otpError == null && state.generalMessage == null) {
      return;
    }
    state = state.copyWith(
      status: VerifyOtpStatus.idle,
      clearOtpError: true,
      clearGeneralMessage: true,
    );
  }

  String? _validateOtp(String otp) {
    if (otp.isEmpty) {
      return 'Enter the 6-digit code.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      return 'Enter a valid 6-digit code.';
    }
    return null;
  }

  _MappedOtpFailure _mapFailure(AppFailure failure) {
    final validationErrors = failure.validationErrors ?? const {};
    String? otpError;
    final generalMessages = <String>[];

    for (final entry in validationErrors.entries) {
      final key = entry.key.toLowerCase();
      final message = entry.value
          .where((item) => item.trim().isNotEmpty)
          .join(' ');
      if (message.isEmpty) {
        continue;
      }
      if (key == 'otp' || key == 'code') {
        otpError = message;
      } else {
        generalMessages.add(message);
      }
    }

    return _MappedOtpFailure(
      otpError: otpError,
      generalMessage: generalMessages.isNotEmpty
          ? generalMessages.join(' ')
          : failure.message,
    );
  }
}

class _MappedOtpFailure {
  const _MappedOtpFailure({this.otpError, this.generalMessage});

  final String? otpError;
  final String? generalMessage;
}
