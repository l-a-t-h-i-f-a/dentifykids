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
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEAF6FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEAF6FF),
          foregroundColor: Color(0xFF0D47A1),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.92),
          surfaceTintColor: const Color(0xFFBBDEFB),
        ),
        bottomAppBarTheme: const BottomAppBarThemeData(
          color: Color(0xFFEAF6FF),
          surfaceTintColor: Color(0xFFBBDEFB),
        ),
        useMaterial3: true,
      ),
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
