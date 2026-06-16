import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class _Question {
  final String question;
  final List<String> options;
  final int correct; // index jawaban benar
  const _Question(this.question, this.options, this.correct);
}

const _questions = [
  _Question(
    'Berapa kali sehari kita harus sikat gigi? 🪥',
    ['1 kali', '2 kali', '5 kali', '10 kali'],
    1,
  ),
  _Question(
    'Kapan waktu terbaik untuk sikat gigi? ⏰',
    ['Saat makan', 'Saat nonton TV', 'Pagi dan malam', 'Siang dan sore'],
    2,
  ),
  _Question(
    'Makanan apa yang BAIK untuk gigi? 🦷',
    ['Permen 🍬', 'Minuman soda 🥤', 'Wortel 🥕', 'Es krim 🍦'],
    2,
  ),
  _Question(
    'Berapa menit waktu ideal sikat gigi? ⏱️',
    ['30 detik', '1 menit', '2 menit', '10 menit'],
    2,
  ),
  _Question(
    'Apa yang harus dilakukan setelah makan permen? 🍬',
    ['Tidur langsung', 'Sikat gigi', 'Makan lagi', 'Minum soda'],
    1,
  ),
  _Question(
    'Minuman apa yang PALING BAIK untuk gigi? 💧',
    ['Soda 🥤', 'Jus kemasan 🧃', 'Kopi ☕', 'Air putih 💧'],
    3,
  ),
  _Question(
    'Warna gigi yang sehat adalah... ✨',
    ['Hitam', 'Merah', 'Putih', 'Biru'],
    2,
  ),
  _Question(
    'Siapa yang membantu menjaga kesehatan gigi kita? 👨‍⚕️',
    ['Guru olahraga', 'Chef', 'Dokter gigi', 'Polisi'],
    2,
  ),
  _Question(
    'Makanan apa yang BURUK untuk gigi? 😬',
    ['Apel 🍎', 'Keju 🧀', 'Susu 🥛', 'Lolipop 🍭'],
    3,
  ),
  _Question(
    'Apa yang terjadi jika jarang sikat gigi? 😱',
    ['Gigi makin putih', 'Gigi berlubang', 'Gigi makin kuat', 'Tidak ada efek'],
    1,
  ),
];

const _optionColors = [
  Color(0xFFE74C3C), // merah
  Color(0xFF3498DB), // biru
  Color(0xFFF39C12), // kuning
  Color(0xFF2ECC71), // hijau
];

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _done = false;

  VideoPlayerController? _ctrlBenar;
  VideoPlayerController? _ctrlSalah;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  @override
  void dispose() {
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

  void _pick(int choice) {
    if (_answered) return;
    final correct = choice == _questions[_index].correct;
    if (correct) {
      HapticFeedback.mediumImpact();
      _playSound(_ctrlBenar);
    } else {
      HapticFeedback.heavyImpact();
      _playSound(_ctrlSalah, stopAfterMs: 2000);
    }
    setState(() {
      _selected = choice;
      _answered = true;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_index + 1 >= _questions.length) {
        setState(() => _done = true);
      } else {
        setState(() {
          _index++;
          _selected = null;
          _answered = false;
        });
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _answered = false;
      _done = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        title: const Text('Kuis Gigi Sehat',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _done ? _buildResult() : _buildQuiz(),
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_index];
    return SafeArea(
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildQuizLandscape(q);
          }
          return _buildQuizPortrait(q);
        },
      ),
    );
  }

  Widget _buildQuizPortrait(_Question q) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildProgressRow(),
          const SizedBox(height: 8),
          _buildProgressBar(),
          const SizedBox(height: 28),
          _buildQuestionCard(q.question),
          const SizedBox(height: 28),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(q.options.length, (i) {
              return _buildOption(i, q.options[i], q.correct);
            }),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuizLandscape(_Question q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          _buildProgressRow(),
          const SizedBox(height: 6),
          _buildProgressBar(),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 45,
                  child: _buildQuestionCard(q.question),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 55,
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(q.options.length, (i) {
                      return _buildOption(i, q.options[i], q.correct);
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProgressRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${_index + 1} / ${_questions.length}',
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Row(children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text('$_score',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ],
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_index + 1) / _questions.length,
      backgroundColor: Colors.grey.shade200,
      color: const Color(0xFF6C63FF),
      minHeight: 6,
      borderRadius: BorderRadius.circular(4),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          question,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int i, String label, int correct) {
    Color bg = _optionColors[i];
    Widget? badge;

    if (_answered) {
      if (i == correct) {
        bg = const Color(0xFF27AE60);
        badge = const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22);
      } else if (i == _selected) {
        bg = const Color(0xFFE74C3C);
        badge = const Icon(Icons.cancel_rounded, color: Colors.white, size: 22);
      } else {
        bg = Colors.grey.shade400;
      }
    }

    return GestureDetector(
      onTap: () => _pick(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (badge != null)
              Positioned(top: 8, right: 8, child: badge),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final total = _questions.length;
    final pct = _score / total;
    final msg = pct == 1.0
        ? 'Sempurna! Kamu jenius! 🏆'
        : pct >= 0.8
            ? 'Keren banget! 🌟'
            : pct >= 0.5
                ? 'Lumayan! Coba lagi ya! 😊'
                : 'Yuk belajar lagi! 💪';
    final stars = pct == 1.0 ? 3 : pct >= 0.6 ? 2 : 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎊', style: TextStyle(fontSize: 72)),
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
              '$_score / $total',
              style: const TextStyle(
                  fontSize: 52, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
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
                  backgroundColor: const Color(0xFF6C63FF),
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
