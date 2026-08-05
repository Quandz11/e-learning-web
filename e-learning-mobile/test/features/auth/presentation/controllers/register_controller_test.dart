import 'dart:async';

import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/core/session/session_repository.dart';
import 'package:e_learning_mobile/core/session/session_state.dart';
import 'package:e_learning_mobile/core/config/app_config.dart';
import 'package:e_learning_mobile/features/auth/data/models/register_request.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_controller.dart';
import 'package:e_learning_mobile/features/auth/presentation/controllers/register_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/in_memory_session_storage.dart';

void main() {
  group('RegisterController', () {
    test('initial state', () {
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async => throw UnimplementedError(),
        ),
      );

      expect(controller.state.status, RegisterStatus.idle);
    });

    test('empty full name validation', () async {
      final controller = _buildController();
      await controller.submit(
        fullName: '',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );
      expect(controller.state.fullNameError, 'Full name is required.');
    });

    test('empty email validation', () async {
      final controller = _buildController();
      await controller.submit(
        fullName: 'User',
        email: '',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );
      expect(controller.state.emailError, 'Email is required.');
    });

    test('invalid email validation', () async {
      final controller = _buildController();
      await controller.submit(
        fullName: 'User',
        email: 'bad',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );
      expect(controller.state.emailError, 'Enter a valid email address.');
    });

    test('empty password validation', () async {
      final controller = _buildController();
      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: '',
        confirmPassword: '',
        phone: '',
        referralCode: '',
      );
      expect(controller.state.passwordError, 'Password is required.');
    });

    test('confirm-password mismatch', () async {
      final controller = _buildController();
      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'other',
        phone: '',
        referralCode: '',
      );
      expect(controller.state.confirmPasswordError, 'Passwords do not match.');
    });

    test('optional phone omitted', () async {
      final repository = FakeAuthRepository(
        onRegister: (_) async =>
            'Registration successful. Please verify your email.',
      );
      final controller = RegisterController(authRepository: repository);

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(repository.registerRequests.single.phone, isNull);
    });

    test('optional referral omitted', () async {
      final repository = FakeAuthRepository(
        onRegister: (_) async =>
            'Registration successful. Please verify your email.',
      );
      final controller = RegisterController(authRepository: repository);

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(repository.registerRequests.single.referralCode, isNull);
    });

    test('empty optional values convert to null', () async {
      final repository = FakeAuthRepository(
        onRegister: (_) async =>
            'Registration successful. Please verify your email.',
      );
      final controller = RegisterController(authRepository: repository);

      await controller.submit(
        fullName: ' User ',
        email: ' user@example.com ',
        password: 'secret',
        confirmPassword: 'secret',
        phone: ' ',
        referralCode: ' ',
      );

      final request = repository.registerRequests.single;
      expect(request.phone, isNull);
      expect(request.referralCode, isNull);
      expect(request.fullName, 'User');
      expect(request.email, 'user@example.com');
    });

    test('valid registration calls repository once', () async {
      final repository = FakeAuthRepository(
        onRegister: (_) async =>
            'Registration successful. Please verify your email.',
      );
      final controller = RegisterController(authRepository: repository);

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(repository.registerCallCount, 1);
    });

    test('correct request model is sent', () async {
      final repository = FakeAuthRepository(
        onRegister: (_) async =>
            'Registration successful. Please verify your email.',
      );
      final controller = RegisterController(authRepository: repository);

      await controller.submit(
        fullName: ' User Name ',
        email: ' user@example.com ',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '0123456789',
        referralCode: ' REF123 ',
      );

      expect(
        repository.registerRequests.single,
        isA<RegisterRequest>()
            .having((request) => request.fullName, 'fullName', 'User Name')
            .having((request) => request.email, 'email', 'user@example.com')
            .having((request) => request.password, 'password', 'secret')
            .having((request) => request.phone, 'phone', '0123456789')
            .having(
              (request) => request.referralCode,
              'referralCode',
              'REF123',
            ),
      );
    });

    test('submitting state', () async {
      final completer = Completer<String>();
      final repository = FakeAuthRepository(
        onRegister: (_) => completer.future,
      );
      final controller = RegisterController(authRepository: repository);

      unawaited(
        controller.submit(
          fullName: 'User',
          email: 'user@example.com',
          password: 'secret',
          confirmPassword: 'secret',
          phone: '',
          referralCode: '',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.status, RegisterStatus.submitting);
      completer.complete('Registration successful. Please verify your email.');
      await Future<void>.delayed(Duration.zero);
    });

    test('success state', () async {
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async =>
              'Registration successful. Please verify your email.',
        ),
      );

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(controller.state.status, RegisterStatus.success);
      expect(controller.state.submittedEmail, 'user@example.com');
    });

    test('failure state', () async {
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async => throw const AppFailure(
            type: AppFailureType.business,
            message: 'Registration failed.',
          ),
        ),
      );

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(controller.state.status, RegisterStatus.failure);
      expect(controller.state.generalMessage, 'Registration failed.');
    });

    test('backend field errors', () async {
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async => throw const AppFailure(
            type: AppFailureType.validation,
            message: 'Validation failed.',
            validationErrors: {
              'fullName': ['Full name is invalid.'],
              'email': ['Email is invalid.'],
              'phone': ['Phone number format is invalid.'],
            },
          ),
        ),
      );

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '0123456789',
        referralCode: '',
      );

      expect(controller.state.fullNameError, 'Full name is invalid.');
      expect(controller.state.emailError, 'Email is invalid.');
      expect(controller.state.phoneError, 'Phone number format is invalid.');
    });

    test('duplicate-email error', () async {
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async => throw const AppFailure(
            type: AppFailureType.business,
            backendCode: 'AUTH_REGISTER_INVALID',
            message: 'Email is already registered.',
          ),
        ),
      );

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(controller.state.generalMessage, 'Email is already registered.');
    });

    test('duplicate-submit prevention', () async {
      final completer = Completer<String>();
      final repository = FakeAuthRepository(
        onRegister: (_) => completer.future,
      );
      final controller = RegisterController(authRepository: repository);

      unawaited(
        controller.submit(
          fullName: 'User',
          email: 'user@example.com',
          password: 'secret',
          confirmPassword: 'secret',
          phone: '',
          referralCode: '',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      unawaited(
        controller.submit(
          fullName: 'User',
          email: 'user@example.com',
          password: 'secret',
          confirmPassword: 'secret',
          phone: '',
          referralCode: '',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(repository.registerCallCount, 1);
      completer.complete('Registration successful. Please verify your email.');
      await Future<void>.delayed(Duration.zero);
    });

    test('recovery after failure', () async {
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async => throw const AppFailure(
            type: AppFailureType.business,
            message: 'Registration failed.',
          ),
        ),
      );

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );
      controller.onEmailChanged();

      expect(controller.state.generalMessage, isNull);
      expect(controller.state.status, RegisterStatus.idle);
    });

    test('registration does not authenticate the session', () async {
      final sessionController = SessionController(
        SessionRepository(
          storage: InMemorySessionStorage(),
          config: AppConfig(
            apiBaseUrl: Uri.parse('https://api.example.com/api'),
            flavor: AppFlavor.dev,
            paymentReturnUrl: Uri.parse('skvi://payment/result'),
            paymentCancelUrl: Uri.parse('skvi://payment/cancel'),
          ),
        ),
      );
      final controller = RegisterController(
        authRepository: FakeAuthRepository(
          onRegister: (_) async =>
              'Registration successful. Please verify your email.',
        ),
      );

      await controller.submit(
        fullName: 'User',
        email: 'user@example.com',
        password: 'secret',
        confirmPassword: 'secret',
        phone: '',
        referralCode: '',
      );

      expect(
        sessionController.state.status,
        isNot(SessionStatus.authenticated),
      );
    });
  });
}

RegisterController _buildController() {
  return RegisterController(
    authRepository: FakeAuthRepository(
      onRegister: (_) async => throw UnimplementedError(),
    ),
  );
}
