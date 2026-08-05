import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>((ref) {
      return RegisterController(
        authRepository: ref.read(authRepositoryProvider),
      );
    });

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const RegisterState());

  final AuthRepository _authRepository;

  Future<void> submit({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    required String referralCode,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    final normalizedFullName = fullName.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();
    final normalizedReferralCode = referralCode.trim();

    final fullNameError = _validateFullName(normalizedFullName);
    final emailError = _validateEmail(normalizedEmail);
    final passwordError = _validatePassword(password);
    final confirmPasswordError = _validateConfirmPassword(
      password: password,
      confirmPassword: confirmPassword,
    );
    final phoneError = _validatePhone(normalizedPhone);

    if (fullNameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        phoneError != null) {
      state = RegisterState(
        status: RegisterStatus.failure,
        fullNameError: fullNameError,
        emailError: emailError,
        passwordError: passwordError,
        confirmPasswordError: confirmPasswordError,
        phoneError: phoneError,
      );
      return;
    }

    state = const RegisterState(status: RegisterStatus.submitting);

    try {
      final message = await _authRepository.register(
        RegisterRequest(
          email: normalizedEmail,
          password: password,
          fullName: normalizedFullName,
          phone: normalizedPhone.isEmpty ? null : normalizedPhone,
          referralCode: normalizedReferralCode.isEmpty
              ? null
              : normalizedReferralCode,
        ),
      );

      state = RegisterState(
        status: RegisterStatus.success,
        generalMessage: message,
        submittedEmail: normalizedEmail,
      );
    } on AppFailure catch (failure) {
      final mapped = _mapFailure(failure);
      state = RegisterState(
        status: RegisterStatus.failure,
        fullNameError: mapped.fullNameError,
        emailError: mapped.emailError,
        passwordError: mapped.passwordError,
        phoneError: mapped.phoneError,
        referralCodeError: mapped.referralCodeError,
        generalMessage: mapped.generalMessage,
      );
    }
  }

  void onFullNameChanged() => _clearStateField(clearFullNameError: true);

  void onEmailChanged() => _clearStateField(clearEmailError: true);

  void onPasswordChanged() => _clearStateField(clearPasswordError: true);

  void onConfirmPasswordChanged() =>
      _clearStateField(clearConfirmPasswordError: true);

  void onPhoneChanged() => _clearStateField(clearPhoneError: true);

  void onReferralCodeChanged() =>
      _clearStateField(clearReferralCodeError: true);

  void _clearStateField({
    bool clearFullNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
    bool clearPhoneError = false,
    bool clearReferralCodeError = false,
  }) {
    final hasFieldError =
        (clearFullNameError && state.fullNameError != null) ||
        (clearEmailError && state.emailError != null) ||
        (clearPasswordError && state.passwordError != null) ||
        (clearConfirmPasswordError && state.confirmPasswordError != null) ||
        (clearPhoneError && state.phoneError != null) ||
        (clearReferralCodeError && state.referralCodeError != null);

    if (!hasFieldError && state.generalMessage == null) {
      return;
    }

    state = state.copyWith(
      status: RegisterStatus.idle,
      clearFullNameError: clearFullNameError,
      clearEmailError: clearEmailError,
      clearPasswordError: clearPasswordError,
      clearConfirmPasswordError: clearConfirmPasswordError,
      clearPhoneError: clearPhoneError,
      clearReferralCodeError: clearReferralCodeError,
      clearGeneralMessage: true,
    );
  }

  String? _validateFullName(String value) {
    if (value.isEmpty) {
      return 'Full name is required.';
    }
    return null;
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Email is required.';
    }

    const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required.';
    }
    return null;
  }

  String? _validateConfirmPassword({
    required String password,
    required String confirmPassword,
  }) {
    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }
    if (confirmPassword != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? _validatePhone(String value) {
    if (value.isEmpty) {
      return null;
    }
    final compact = value.replaceAll(RegExp(r'[\s\-\.\(\)\+]'), '');
    if (!RegExp(r'^\d{9,15}$').hasMatch(compact)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  _MappedRegisterFailure _mapFailure(AppFailure failure) {
    final validationErrors = failure.validationErrors ?? const {};
    String? fullNameError;
    String? emailError;
    String? passwordError;
    String? phoneError;
    String? referralCodeError;
    final generalMessages = <String>[];

    for (final entry in validationErrors.entries) {
      final key = entry.key.toLowerCase();
      final message = entry.value
          .where((item) => item.trim().isNotEmpty)
          .join(' ');
      if (message.isEmpty) {
        continue;
      }
      switch (key) {
        case 'fullname':
        case 'full_name':
          fullNameError = message;
          break;
        case 'email':
          emailError = message;
          break;
        case 'password':
          passwordError = message;
          break;
        case 'phone':
          phoneError = message;
          break;
        case 'referralcode':
        case 'referral_code':
          referralCodeError = message;
          break;
        default:
          generalMessages.add(message);
      }
    }

    final generalMessage = generalMessages.isNotEmpty
        ? generalMessages.join(' ')
        : failure.message;

    return _MappedRegisterFailure(
      fullNameError: fullNameError,
      emailError: emailError,
      passwordError: passwordError,
      phoneError: phoneError,
      referralCodeError: referralCodeError,
      generalMessage: generalMessage,
    );
  }
}

class _MappedRegisterFailure {
  const _MappedRegisterFailure({
    this.fullNameError,
    this.emailError,
    this.passwordError,
    this.phoneError,
    this.referralCodeError,
    this.generalMessage,
  });

  final String? fullNameError;
  final String? emailError;
  final String? passwordError;
  final String? phoneError;
  final String? referralCodeError;
  final String? generalMessage;
}
