import 'dart:async';
import 'package:e_learning_mobile/features/running/data/models/running_models.dart';
import 'package:e_learning_mobile/features/running/data/running_repository.dart';
import 'package:e_learning_mobile/features/running/presentation/controllers/running_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum LiveRunStatus {
  initial,
  running,
  paused,
  completed,
  permissionDenied,
  serviceDisabled,
}

class LiveRunState {
  const LiveRunState({
    this.status = LiveRunStatus.initial,
    this.elapsedSeconds = 0,
    this.distanceMeters = 0.0,
    this.distanceKm = 0.0,
    this.currentPaceMinPerKm,
    this.currentPaceFormatted = '--',
    this.caloriesBurned = 0,
    this.errorMessage,
    this.isSaving = false,
  });

  final LiveRunStatus status;
  final int elapsedSeconds;
  final double distanceMeters;
  final double distanceKm;
  final double? currentPaceMinPerKm;
  final String currentPaceFormatted;
  final int caloriesBurned;
  final String? errorMessage;
  final bool isSaving;

  bool get isRunning => status == LiveRunStatus.running;
  bool get isPaused => status == LiveRunStatus.paused;
  bool get isActive => isRunning || isPaused;

  String get durationFormatted {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  LiveRunState copyWith({
    LiveRunStatus? status,
    int? elapsedSeconds,
    double? distanceMeters,
    double? distanceKm,
    double? currentPaceMinPerKm,
    String? currentPaceFormatted,
    int? caloriesBurned,
    String? errorMessage,
    bool? isSaving,
  }) {
    return LiveRunState(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      distanceKm: distanceKm ?? this.distanceKm,
      currentPaceMinPerKm: currentPaceMinPerKm ?? this.currentPaceMinPerKm,
      currentPaceFormatted: currentPaceFormatted ?? this.currentPaceFormatted,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final liveGpsControllerProvider =
    StateNotifierProvider.autoDispose<LiveGpsController, LiveRunState>((ref) {
  return LiveGpsController(ref);
});

class LiveGpsController extends StateNotifier<LiveRunState> {
  LiveGpsController(this._ref) : super(const LiveRunState());

  final Ref _ref;
  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  Position? _lastPosition;

  Future<bool> start() async {
    state = state.copyWith(errorMessage: null);

    // 1. Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        status: LiveRunStatus.serviceDisabled,
        errorMessage: 'Dịch vụ định vị GPS chưa được bật. Vui lòng bật GPS trên thiết bị.',
      );
      return false;
    }

    // 2. Check location permissions
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          status: LiveRunStatus.permissionDenied,
          errorMessage: 'Ứng dụng cần quyền định vị GPS để đo quãng đường chạy bộ.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: LiveRunStatus.permissionDenied,
        errorMessage:
            'Quyền vị trí đã bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền cho ứng dụng.',
      );
      return false;
    }

    // 3. Start running
    state = state.copyWith(status: LiveRunStatus.running);
    _startTimer();
    _startGpsStream();
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status != LiveRunStatus.running) return;

      final newSeconds = state.elapsedSeconds + 1;
      _updatePaceAndCalories(newSeconds, state.distanceKm);
    });
  }

  void _startGpsStream() {
    _positionSub?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Emit every 2 meters
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (state.status != LiveRunStatus.running) return;

      if (_lastPosition != null) {
        // Filter out poor accuracy
        if (position.accuracy > 35) return;

        final dist = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        // Filter out unreasonable GPS jumps (> 15 m/s = 54 km/h) or micro-jitter (< 1m)
        if (dist >= 1.0 && dist < 50.0) {
          final newMeters = state.distanceMeters + dist;
          final newKm = double.parse((newMeters / 1000.0).toStringAsFixed(3));
          _lastPosition = position;
          _updatePaceAndCalories(state.elapsedSeconds, newKm, meters: newMeters);
          return;
        }
      }

      _lastPosition = position;
    }, onError: (Object err) {
      state = state.copyWith(errorMessage: 'Lỗi tín hiệu GPS: $err');
    });
  }

  void _updatePaceAndCalories(int seconds, double km, {double? meters}) {
    double? pace;
    String paceStr = '--';

    if (km > 0.02 && seconds > 0) {
      pace = (seconds / 60.0) / km;
      final m = pace.toInt();
      var s = ((pace - m) * 60).round();
      var finalM = m;
      if (s >= 60) {
        finalM++;
        s = 0;
      }
      paceStr = "$finalM'${s.toString().padLeft(2, '0')}\"/km";
    }

    // Calories: approx 65kg * km * 1.036
    final cal = (km * 65.0 * 1.036).round();

    state = state.copyWith(
      elapsedSeconds: seconds,
      distanceKm: km,
      distanceMeters: meters ?? state.distanceMeters,
      currentPaceMinPerKm: pace,
      currentPaceFormatted: paceStr,
      caloriesBurned: cal,
    );
  }

  void pause() {
    if (state.status == LiveRunStatus.running) {
      _positionSub?.pause();
      state = state.copyWith(status: LiveRunStatus.paused);
    }
  }

  void resume() {
    if (state.status == LiveRunStatus.paused) {
      _positionSub?.resume();
      state = state.copyWith(status: LiveRunStatus.running);
    }
  }

  Future<bool> finishAndSave({String? title, String? notes}) async {
    _timer?.cancel();
    _positionSub?.cancel();

    // Must have at least 0.01 km or 5 seconds
    if (state.distanceKm <= 0.005 && state.elapsedSeconds < 5) {
      reset();
      return true;
    }

    state = state.copyWith(isSaving: true);
    try {
      final repo = _ref.read(runningRepositoryProvider);
      final finalDistance = state.distanceKm > 0 ? state.distanceKm : 0.01;

      final dto = CreateRunningActivityDto(
        distanceKm: double.parse(finalDistance.toStringAsFixed(2)),
        durationSeconds: state.elapsedSeconds > 0 ? state.elapsedSeconds : 1,
        activityDate: DateTime.now(),
        title: title ?? 'Chạy bộ ngoài trời',
        notes: notes,
        trackingMode: 'GPS',
      );

      await repo.createActivity(dto);
      _ref.read(runningControllerProvider.notifier).refresh();

      state = state.copyWith(
        status: LiveRunStatus.completed,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Không thể lưu buổi chạy: $e',
      );
      return false;
    }
  }

  void reset() {
    _timer?.cancel();
    _positionSub?.cancel();
    _lastPosition = null;
    state = const LiveRunState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}
