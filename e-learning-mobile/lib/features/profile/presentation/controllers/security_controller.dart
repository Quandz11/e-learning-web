import 'package:e_learning_mobile/core/errors/app_failure.dart';
import 'package:e_learning_mobile/core/session/session_controller.dart';
import 'package:e_learning_mobile/features/auth/data/auth_repository.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:e_learning_mobile/features/profile/presentation/controllers/security_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityControllerProvider =
    StateNotifierProvider.autoDispose<SecurityController, SecurityState>((ref) {
      return SecurityController(
        authRepository: ref.read(authRepositoryProvider),
        profileController: ref.read(profileControllerProvider.notifier),
        sessionController: ref.read(sessionControllerProvider.notifier),
      );
    });

class SecurityController extends StateNotifier<SecurityState> {
  SecurityController({
    required AuthRepository authRepository,
    required ProfileController profileController,
    required SessionController sessionController,
  }) : _authRepository = authRepository,
       _profileController = profileController,
       _sessionController = sessionController,
       super(const SecurityState());

  final AuthRepository _authRepository;
  final ProfileController _profileController;
  final SessionController _sessionController;

  Future<void> loadSetup() async {
    if (state.isBusy) {
      return;
    }
    state = const SecurityState(status: SecurityStatus.loadingSetup);
    try {
      final result = await _authRepository.setupTwoFactor();
      state = SecurityState(
        status: SecurityStatus.setupReady,
        secret: result.secret,
        qrCodeUri: result.qrCodeUri,
      );
    } on AppFailure catch (failure) {
      state = SecurityState(
        status: SecurityStatus.failure,
        generalMessage: failure.message,
      );
    }
  }

  void clearSetup() {
    state = const SecurityState();
  }

  Future<bool> enable(String code) async {
    if (state.isBusy) {
      return false;
    }
    final normalizedCode = code.trim();
    if (state.secret == null || state.secret!.isEmpty) {
      state = const SecurityState(
        status: SecurityStatus.failure,
        generalMessage: 'Phiên thiết lập xác thực hai lớp đã hết hạn.',
      );
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedCode)) {
      state = SecurityState(
        status: SecurityStatus.setupReady,
        secret: state.secret,
        qrCodeUri: state.qrCodeUri,
        codeError: 'Mã xác thực phải gồm 6 chữ số.',
      );
      return false;
    }

    state = SecurityState(
      status: SecurityStatus.enabling,
      secret: state.secret,
      qrCodeUri: state.qrCodeUri,
    );
    try {
      final result = await _authRepository.enableTwoFactor(
        secret: state.secret!,
        code: normalizedCode,
      );
      if (result.session != null) {
        _sessionController.syncSession(result.session!);
      }
      await _profileController.refresh();
      state = const SecurityState(
        status: SecurityStatus.success,
        generalMessage: 'Đã bật xác thực hai lớp.',
      );
      return true;
    } on AppFailure catch (failure) {
      state = SecurityState(
        status: SecurityStatus.setupReady,
        secret: state.secret,
        qrCodeUri: state.qrCodeUri,
        codeError: failure.validationErrors?['code']?.join(' '),
        generalMessage: failure.message,
      );
      return false;
    }
  }

  Future<bool> disable(String password) async {
    if (state.isBusy) {
      return false;
    }
    if (password.isEmpty) {
      state = const SecurityState(
        status: SecurityStatus.failure,
        passwordError: 'Vui lòng nhập mật khẩu hiện tại.',
      );
      return false;
    }

    state = const SecurityState(status: SecurityStatus.disabling);
    try {
      await _authRepository.disableTwoFactor(password: password);
      await _profileController.refresh();
      state = const SecurityState(
        status: SecurityStatus.success,
        generalMessage: 'Đã tắt xác thực hai lớp.',
      );
      return true;
    } on AppFailure catch (failure) {
      state = SecurityState(
        status: SecurityStatus.failure,
        passwordError: failure.validationErrors?['password']?.join(' '),
        generalMessage: failure.message,
      );
      return false;
    }
  }
}
