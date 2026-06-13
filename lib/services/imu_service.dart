import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum MotionType { correct, wrong }

class ImuService {
  static const double _threshold = 6.0;   // m/s² spike untuk deteksi gerakan
  static const double _wrongRatio = 1.5;  // X lebih besar X kali dari Y = salah

  static final ImuService _instance = ImuService._();
  factory ImuService() => _instance;
  ImuService._();

  final _movementCtrl = StreamController<MotionType>.broadcast();
  Stream<MotionType> get motionStream => _movementCtrl.stream;

  StreamSubscription<AccelerometerEvent>? _accelSub;

  // Simpan nilai terakhir untuk deteksi peak
  double _lastY = 0;
  double _lastX = 0;
  bool _initialized = false;
  DateTime _lastDetected = DateTime.fromMillisecondsSinceEpoch(0);

  void start() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen(_onAccel);
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
    _lastY = 0;
    _lastX = 0;
    _initialized = false;
  }

  void _onAccel(AccelerometerEvent e) {
    if (!_initialized) {
      _lastY = e.y;
      _lastX = e.x;
      _initialized = true;
      return;
    }

    final deltaY = (e.y - _lastY).abs();
    final deltaX = (e.x - _lastX).abs();
    _lastY = e.y;
    _lastX = e.x;

    final magnitude = sqrt(deltaX * deltaX + deltaY * deltaY);
    if (magnitude < _threshold) return;

    // Debounce — minimal 300ms antar deteksi
    final now = DateTime.now();
    if (now.difference(_lastDetected).inMilliseconds < 300) return;
    _lastDetected = now;

    // Gerakan benar: Y (atas-bawah) dominan
    // Gerakan salah: X (kiri-kanan) dominan
    if (deltaY >= deltaX) {
      _movementCtrl.add(MotionType.correct);
    } else if (deltaX > deltaY * _wrongRatio) {
      _movementCtrl.add(MotionType.wrong);
    }
    // diagonal (hampir sama) — diabaikan
  }

  void dispose() {
    stop();
    _movementCtrl.close();
  }
}
