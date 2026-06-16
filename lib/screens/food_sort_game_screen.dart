import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class _FoodItem {
  final String emoji;
  final String name;
  final bool isGood;
  const _FoodItem(this.emoji, this.name, this.isGood);
}

const _foods = [
  _FoodItem('🥦', 'Brokoli', true),
  _FoodItem('🍎', 'Apel', true),
  _FoodItem('🥕', 'Wortel', true),
  _FoodItem('🥛', 'Susu', true),
  _FoodItem('🧀', 'Keju', true),
  _FoodItem('💧', 'Air Putih', true),
  _FoodItem('🍐', 'Pir', true),
  _FoodItem('🐟', 'Ikan', true),
  _FoodItem('🍩', 'Donat', false),
  _FoodItem('🍬', 'Permen', false),
  _FoodItem('🥤', 'Minuman Soda', false),
  _FoodItem('🍫', 'Cokelat', false),
  _FoodItem('🍦', 'Es Krim', false),
  _FoodItem('🎂', 'Kue Manis', false),
  _FoodItem('🍭', 'Lolipop', false),
  _FoodItem('🧃', 'Jus Kemasan', false),
];

class FoodSortGameScreen extends StatefulWidget {
  const FoodSortGameScreen({super.key});

  @override
  State<FoodSortGameScreen> createState() => _FoodSortGameScreenState();
}

class _FoodSortGameScreenState extends State<FoodSortGameScreen>
    with SingleTickerProviderStateMixin {
  late final List<_FoodItem> _deck;
  int _index = 0;
  int _score = 0;
  bool? _lastCorrect;
  bool _done = false;
  late AnimationController _animCtrl;
  Color _flashColor = Colors.transparent;
  VideoPlayerController? _ctrlBenar;
  VideoPlayerController? _ctrlSalah;

  @override
  void initState() {
    super.initState();
    _deck = List.of(_foods)..shuffle();
    _deck.length; // use all 16 cards

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadSounds();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _ctrlBenar?.dispose();
    _ctrlSalah?.dispose();
    super.dispose();
  }

  Future<void> _loadSounds() async {
    _ctrlBenar = VideoPlayerController.asset('assets/audios/benar.mp3');
    _ctrlSalah = VideoPlayerController.asset('assets/audios/salah.mp3');
    await Future.wait([
      _ctrlBenar!.initialize(),
      _ctrlSalah!.initialize(),
    ]);
  }

  Future<void> _playSound(VideoPlayerController? ctrl, {int? stopAfterMs}) async {
    if (ctrl == null || !ctrl.value.isInitialized) return;
    await ctrl.seekTo(Duration.zero);
    await ctrl.play();
    if (stopAfterMs != null) {
      Future.delayed(Duration(milliseconds: stopAfterMs), () => ctrl.pause());
    }
  }

  Future<void> _answer(bool isGood) async {
    if (_animCtrl.isAnimating) return;
    final correct = isGood == _deck[_index].isGood;
    if (correct) {
      HapticFeedback.mediumImpact();
      _playSound(_ctrlBenar);
    } else {
      HapticFeedback.heavyImpact();
      _playSound(_ctrlSalah, stopAfterMs: 2000);
    }
    setState(() {
      _lastCorrect = correct;
      _flashColor = correct ? Colors.green.shade100 : Colors.red.shade100;
      if (correct) _score++;
    });

    await _animCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1500));

    if (_index + 1 >= _deck.length) {
      setState(() => _done = true);
    } else {
      setState(() {
        _index++;
        _flashColor = Colors.transparent;
        _lastCorrect = null;
      });
      _animCtrl.reset();
    }
  }

  void _restart() {
    setState(() {
      _deck.shuffle();
      _index = 0;
      _score = 0;
      _lastCorrect = null;
      _done = false;
      _flashColor = Colors.transparent;
    });
    _animCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F0),
        elevation: 0,
        title: const Text('Makanan & Minuman',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _done ? _buildResult() : _buildGame(),
    );
  }

  Widget _buildGame() {
    final item = _deck[_index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: _flashColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_index + 1} / ${_deck.length}',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('$_score',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_index + 1) / _deck.length,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green.shade400,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 32),
              // Pertanyaan
              const Text(
                'Apakah ini baik untuk gigi?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 32),
              // Kartu makanan
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.emoji,
                          style: const TextStyle(fontSize: 80)),
                      const SizedBox(height: 12),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Feedback
              SizedBox(
                height: 48,
                child: Center(
                  child: _lastCorrect == null
                      ? const SizedBox.shrink()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _lastCorrect!
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: _lastCorrect!
                                  ? Colors.green
                                  : Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _lastCorrect! ? 'Benar! 🎉' : 'Salah 😅',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _lastCorrect!
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const Spacer(),
              // Tombol jawab
              Row(
                children: [
                  Expanded(
                    child: _AnswerButton(
                      label: 'BURUK',
                      emoji: '✗',
                      color: Colors.red.shade400,
                      onTap: () => _answer(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AnswerButton(
                      label: 'BAIK',
                      emoji: '✓',
                      color: Colors.green.shade500,
                      onTap: () => _answer(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final total = _deck.length;
    final pct = _score / total;
    final msg = pct == 1.0
        ? 'Sempurna! Kamu hebat! 🏆'
        : pct >= 0.7
            ? 'Bagus sekali! 🌟'
            : pct >= 0.5
                ? 'Lumayan! Coba lagi ya! 😊'
                : 'Yuk belajar lagi! 💪';
    final stars = pct == 1.0 ? 3 : pct >= 0.7 ? 2 : 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  Icons.star_rounded,
                  size: 48,
                  color: i < stars ? Colors.amber : Colors.grey.shade300,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$_score / $total',
              style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
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

class _AnswerButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji,
                style: const TextStyle(
                    fontSize: 24, color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
