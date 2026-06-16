import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'food_sort_game_screen.dart';
import 'home_screen.dart';
import 'quiz_game_screen.dart';
import 'teeth_clean_game_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Game 🎮',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Belajar sambil bermain!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 28),
                _GameCard(
                  emoji: '🥦',
                  title: 'Makanan & Minuman',
                  subtitle: 'Pilih makanan yang baik\nuntuk gigimu!',
                  gradientColors: [Color(0xFF56AB2F), Color(0xFFA8E063)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FoodSortGameScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _GameCard(
                  emoji: '🧠',
                  title: 'Kuis Gigi Sehat',
                  subtitle: 'Uji pengetahuanmu\ntentang kesehatan gigi!',
                  gradientColors: [Color(0xFF6C63FF), Color(0xFF9B8FFF)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const QuizGameScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _GameCard(
                  emoji: '🪥',
                  title: 'Bersihkan Gigi!',
                  subtitle: 'Ketuk semua noda sebelum\nwaktu habis!',
                  gradientColors: [Color(0xFF00BFA5), Color(0xFF69F0AE)],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TeethCleanGameScreen()),
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: AppNavItem.game,
        onItemSelected: (item) {
          if (item == AppNavItem.game) return;
          Widget screen;
          switch (item) {
            case AppNavItem.home:
              screen = const HomeScreen();
            case AppNavItem.scan:
              screen = const ScanScreen();
            case AppNavItem.settings:
              screen = const SettingsScreen();
            case AppNavItem.game:
              return;
          }
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
