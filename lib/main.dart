import 'package:flutter/material.dart';
import 'services/preferences_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final nama = await PreferencesService().getNamaUser();
  runApp(DentifyKidsApp(showOnboarding: nama.isEmpty));
}

class DentifyKidsApp extends StatelessWidget {
  final bool showOnboarding;
  const DentifyKidsApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DentifyKids',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F0FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F0FF),
          foregroundColor: Color(0xFF3A3185),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.95),
          surfaceTintColor: Colors.transparent,
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFFF3F0FF),
          surfaceTintColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
          ),
        ),
        useMaterial3: true,
      ),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
