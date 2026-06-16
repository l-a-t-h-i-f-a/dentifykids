import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WifiDevice {
  final String name;
  final String ip;
  final int port;
  const WifiDevice({required this.name, required this.ip, required this.port});
}

class MpuData {
  final double ax, ay, az;
  final double gx, gy, gz;
  const MpuData({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });
  factory MpuData.fromJson(Map<String, dynamic> json) => MpuData(
        ax: (json['ax'] as num).toDouble(),
        ay: (json['ay'] as num).toDouble(),
        az: (json['az'] as num).toDouble(),
        gx: (json['gx'] as num).toDouble(),
        gy: (json['gy'] as num).toDouble(),
        gz: (json['gz'] as num).toDouble(),
      );
}

// Sesuai kode ESP32: ay > 0.60 = ATAS, ay < 0.20 = BAWAH, else = TENGAH
enum _BrushPos { up, down, neutral }

class WifiService {
  static const _esp32Port = 80;

  static final WifiService _instance = WifiService._();
  factory WifiService() => _instance;
  WifiService._();

  WifiDevice? _connectedDevice;
  Timer? _pollTimer;
  _BrushPos _lastPos = _BrushPos.neutral;
  int _failCount = 0;
  bool _capturing = false;
  static const _maxFail = 4;

  final _movementCtrl = StreamController<int>.broadcast();
  final _wrongMovementCtrl = StreamController<int>.broadcast();
  final _connectionCtrl = StreamController<bool>.broadcast();
  final _mpuCtrl = StreamController<MpuData>.broadcast();

  WifiDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  Stream<int> get movementStream => _movementCtrl.stream;
  Stream<int> get wrongMovementStream => _wrongMovementCtrl.stream;
  Stream<bool> get connectionStream => _connectionCtrl.stream;
  Stream<MpuData> get mpuStream => _mpuCtrl.stream;

  // Scan subnet lokal untuk menemukan alat via endpoint /whoami
  Future<WifiDevice?> discover() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? subnet;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
              break;
            }
          }
        }
        if (subnet != null) break;
      }

      if (subnet == null) return null;

      final completer = Completer<WifiDevice?>();
      int remaining = 254;

      for (int i = 1; i <= 254; i++) {
        _probeIp('$subnet.$i').then((device) {
          if (device != null && !completer.isCompleted) {
            completer.complete(device);
          }
          remaining--;
          if (remaining == 0 && !completer.isCompleted) {
            completer.complete(null);
          }
        });
      }

      return completer.future;
    } catch (_) {
      return null;
    }
  }

  Future<WifiDevice?> _probeIp(String ip) async {
    try {
      final res = await http
          .get(Uri.parse('http://$ip:$_esp32Port/whoami'))
          .timeout(const Duration(milliseconds: 600));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final name = (data['device'] as String?) ?? 'dentifykids';
        return WifiDevice(name: name, ip: ip, port: _esp32Port);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> connect(WifiDevice device) async {
    try {
      final res = await http
          .get(Uri.parse('http://${device.ip}:${device.port}/'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        _connectedDevice = device;
        _lastPos = _BrushPos.neutral;
        _failCount = 0;
        _capturing = false;
        _startPolling();
        _connectionCtrl.add(true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _failCount = 0;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) async {
      if (_connectedDevice == null || _capturing) return;
      try {
        final res = await http
            .get(Uri.parse(
                'http://${_connectedDevice!.ip}:${_connectedDevice!.port}/mpu'))
            .timeout(const Duration(milliseconds: 250));

        if (res.statusCode != 200) {
          _registerFail();
          return;
        }

        _failCount = 0;
        final data =
            MpuData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
        _mpuCtrl.add(data);
        _detectMovement(data);
      } catch (_) {
        _registerFail();
      }
    });
  }

  void _registerFail() {
    _failCount++;
    if (_failCount >= _maxFail) _onDisconnected();
  }

  void _detectMovement(MpuData data) {
    final _BrushPos pos;
    if (data.ay > 0.60) {
      pos = _BrushPos.up;
    } else if (data.ay < 0.20) {
      pos = _BrushPos.down;
    } else {
      pos = _BrushPos.neutral;
    }

    if (pos != _lastPos && pos != _BrushPos.neutral) {
      if (data.ax.abs() > data.ay.abs() * 1.5) {
        _wrongMovementCtrl.add(1);
      } else {
        _movementCtrl.add(1);
      }
    }
    _lastPos = pos;
  }

  void _onDisconnected() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _connectedDevice = null;
    _connectionCtrl.add(false);
  }

  Future<File> captureImage() async {
    if (_connectedDevice == null) throw Exception('Alat tidak terhubung');

    _capturing = true;
    _pollTimer?.cancel();

    try {
      final res = await http
          .get(Uri.parse(
              'http://${_connectedDevice!.ip}:${_connectedDevice!.port}/capture'))
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('Gagal mengambil foto dari alat (${res.statusCode})');
      }

      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('image')) {
        throw Exception('Belum ada foto. Tekan tombol pada alat terlebih dahulu.');
      }

      final dir = Directory.systemTemp;
      final file = File(
          '${dir.path}/esp32_capture_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(res.bodyBytes);
      return file;
    } finally {
      _capturing = false;
      if (_connectedDevice != null) _startPolling();
    }
  }

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _connectedDevice = null;
    _connectionCtrl.add(false);
  }
}
