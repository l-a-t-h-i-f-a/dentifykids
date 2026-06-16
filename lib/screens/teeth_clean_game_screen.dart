import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _stainEmojis = ['🍬', '🍭', '🍩', '🍫', '🥤', '🎂', '🧃', '🍦'];

class _Stain {
  final double x;
  final double y;
  final String emoji;
  bool cleaned;
  _Stain(this.x, this.y, this.emoji) : cleaned = false;
}

class TeethCleanGameScreen extends StatefulWidget {
  const TeethCleanGameScreen({super.key});

  @override
  State<TeethCleanGameScreen> createState() => _TeethCleanGameScreenState();
}

class _TeethCleanGameScreenState extends State<TeethCleanGameScreen>
    with TickerProviderStateMixin {
  static const _totalStains = 16;
  static const _totalTime = 40;

  late List<_Stain> _stains;
  final List<AnimationController> _animCtrl = [];
  int _cleanedCount = 0;
  int _timeLeft = _totalTime;
  bool _done = false;
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateStains();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _animCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _generateStains() {
    final rng = Random();
    _stains = List.generate(_totalStains, (_) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
        value: 1.0,
      );
      _animCtrl.add(ctrl);
      return _Stain(
        0.08 + rng.nextDouble() * 0.84,
        0.08 + rng.nextDouble() * 0.84,
        _stainEmojis[rng.nextInt(_stainEmojis.length)],
      );
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _timer?.cancel();
        if (!_done) setState(() => _timedOut = true);
      }
    });
  }

  Future<void> _cleanStain(int index) async {
    if (_stains[index].cleaned || _done || _timedOut) return;
    HapticFeedback.lightImpact();
    await _animCtrl[index].reverse();
    setState(() {
      _stains[index].cleaned = true;
      _cleanedCount++;
    });
    if (_cleanedCount >= _totalStains) {
      _timer?.cancel();
      setState(() => _done = true);
    }
  }

  void _restart() {
    _timer?.cancel();
    for (final c in _animCtrl) {
      c.dispose();
    }
    _animCtrl.clear();
    setState(() {
      _cleanedCount = 0;
      _timeLeft = _totalTime;
      _done = false;
      _timedOut = false;
    });
    _generateStains();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        title: const Text('Bersihkan Gigi! 🦷',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _done || _timedOut ? _buildResult() : _buildGame(),
    );
  }

  Widget _buildGame() {
    final progress = _cleanedCount / _totalStains;
    final timerColor = _timeLeft <= 10 ? Colors.red : Colors.green.shade700;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header: progress + timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_cleanedCount / $_totalStains noda',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Row(
                  children: [
                    Icon(Icons.timer_rounded, color: timerColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_timeLeft detik',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.green.shade500,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ketuk semua makanan manis untuk\nmembersihkan gigi! 🪥',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            // Tooth area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(
                    children: [
                      // Tooth background
                      Container(
                        width: w,
                        height: h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🦷',
                              style: TextStyle(fontSize: 100)),
                        ),
                      ),
                      // Stains
                      ..._stains.asMap().entries.map((e) {
                        final i = e.key;
                        final stain = e.value;
                        return Positioned(
                          left: stain.x * w - 18,
                          top: stain.y * h - 18,
                          child: ScaleTransition(
                            scale: _animCtrl[i],
                            child: GestureDetector(
                              onTap: () => _cleanStain(i),
                              child: stain.cleaned
                                  ? const SizedBox(width: 36, height: 36)
                                  : Text(
                                      stain.emoji,
                                      style: const TextStyle(fontSize: 30),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final win = _done;
    final pct = _cleanedCount / _totalStains;
    final stars = win ? (pct == 1.0 ? 3 : 2) : (_cleanedCount >= _totalStains * 0.5 ? 1 : 0);
    final msg = win
        ? '🎉 Gigi Bersih Sempurna!'
        : _cleanedCount >= _totalStains * 0.5
            ? '😅 Hampir! Masih ada noda tersisa.'
            : '⏰ Waktu habis! Coba lagi!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(win ? '🦷✨' : '😬',
                style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  Icons.star_rounded,
                  size: 52,
                  color: i < stars ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$_cleanedCount / $_totalStains',
              style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'noda dibersihkan',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Main Lagi',
                    style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali ke Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
