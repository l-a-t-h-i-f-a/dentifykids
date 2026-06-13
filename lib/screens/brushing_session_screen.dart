import 'dart:async';
import 'package:flutter/material.dart';
import '../models/brushing_record.dart';
import '../services/database_service.dart';
import '../services/wifi_service.dart';
import '../utils/session_utils.dart';

class BrushingSessionScreen extends StatefulWidget {
  final String sesi;
  const BrushingSessionScreen({super.key, required this.sesi});

  @override
  State<BrushingSessionScreen> createState() => _BrushingSessionScreenState();
}

class _BrushingSessionScreenState extends State<BrushingSessionScreen> {
  final _wifi = WifiService();
  late final DateTime _waktuMulai;
  int _durasiDetik = 0;
  int _jumlahGerakan = 0;
  bool _selesai = false;
  bool _showWrongMotion = false;
  Timer? _timer;
  Timer? _wrongMotionTimer;
  StreamSubscription<int>? _moveSub;
  StreamSubscription<int>? _wrongMoveSub;

  @override
  void initState() {
    super.initState();
    _waktuMulai = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_selesai && mounted) setState(() => _durasiDetik++);
    });

    if (_wifi.isConnected) {
      _moveSub = _wifi.movementStream.listen((_) {
        if (!_selesai && mounted) setState(() => _jumlahGerakan++);
      });

      _wrongMoveSub = _wifi.wrongMovementStream.listen((_) {
        if (_selesai || !mounted) return;
        _wrongMotionTimer?.cancel();
        setState(() => _showWrongMotion = true);
        _wrongMotionTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showWrongMotion = false);
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wrongMotionTimer?.cancel();
    _moveSub?.cancel();
    _wrongMoveSub?.cancel();
    super.dispose();
  }

  Future<void> _selesaikan() async {
    if (_selesai) return;
    setState(() => _selesai = true);
    _timer?.cancel();
    _moveSub?.cancel();

    final waktuSelesai = DateTime.now();
    await DatabaseService().insertRecord(
      BrushingRecord(
        tanggal: formatTanggal(_waktuMulai),
        waktuMulai: formatWaktu(_waktuMulai),
        waktuSelesai: formatWaktu(waktuSelesai),
        durasiDetik: _durasiDetik,
        jumlahGerakan: _jumlahGerakan,
        sesi: widget.sesi,
        createdAt: waktuSelesai.toIso8601String(),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sesiLabel = widget.sesi == 'pagi' ? 'Pagi 🌅' : 'Malam 🌙';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sesi $sesiLabel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    formatDurasi(_durasiDetik),
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w200,
                      color: scheme.primary,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    'Waktu sikat',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 48),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showWrongMotion
                        ? Container(
                            key: const ValueKey('wrong'),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_rounded,
                                    color: Colors.orange.shade700, size: 28),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gerakan Kurang Tepat!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Sikat gigi ke atas dan ke bawah ya! 🪥',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('ok')),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 32,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$_jumlahGerakan',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          const Text(
                            'Gerakan terdeteksi',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _selesaikan,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
