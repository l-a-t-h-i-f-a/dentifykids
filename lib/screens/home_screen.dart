import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../services/wifi_service.dart';
import '../utils/session_utils.dart';
import '../widgets/app_bottom_nav.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'wifi_screen.dart';
import 'brushing_session_screen.dart';
import 'education_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _namaUser = '';
  bool _pagiSudah = false;
  bool _malamSudah = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = formatTanggal(DateTime.now());
    final nama = await PreferencesService().getNamaUser();
    final pagi = await DatabaseService().hasSesiToday(today, 'pagi');
    final malam = await DatabaseService().hasSesiToday(today, 'malam');
    if (!mounted) return;
    setState(() {
      _namaUser = nama;
      _pagiSudah = pagi;
      _malamSudah = malam;
      _loading = false;
    });
  }

  Future<void> _startBrushing() async {
    final sesi = determineSesi(DateTime.now());
    if (sesi.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Bukan Waktu Sikat Gigi'),
          content: const Text(
            'Waktu sikat gigi:\n• Pagi: 00.00 – 11.59\n• Malam: 12.00 – 23.59',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Oke'),
            ),
          ],
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BrushingSessionScreen(sesi: sesi)),
    );
    _load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    _load();
  }

  Future<void> _openEducation() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EducationScreen()));
    _load();
  }

  void _selectNavItem(AppNavItem item) {
    if (item == AppNavItem.home) return;

    Widget screen;
    switch (item) {
      case AppNavItem.game:
        screen = const GameScreen();
      case AppNavItem.scan:
        screen = const ScanScreen();
      case AppNavItem.settings:
        _openSettings();
        return;
      case AppNavItem.home:
        return;
    }

    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();
    final namaHari = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ][now.weekday % 7];
    final namaBulan = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ][now.month];
    final tanggalStr = '$namaHari, ${now.day} $namaBulan ${now.year}';

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(tanggalStr),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Text('🦷', style: TextStyle(fontSize: 26)),
                            // Text('✨', style: TextStyle(fontSize: 20)),
                            // Text('🪥', style: TextStyle(fontSize: 26)),
                            // Text('💧', style: TextStyle(fontSize: 20)),
                            // Text('😁', style: TextStyle(fontSize: 26)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSesiCard('Pagi', '🌅', _pagiSudah),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSesiCard('Malam', '🌙', _malamSudah),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStartButton(),
                        const SizedBox(height: 18),
                        _buildEducationVideoCard(),
                        const SizedBox(height: 12),
                        _buildRiwayatCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: AppNavItem.home,
        onItemSelected: _selectNavItem,
      ),
    );
  }

  Widget _buildEducationVideoCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: _openEducation,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('🎬', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📚 Video Edukasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tonton materi seru tentang gigi sehat! ✨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
          _load();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('📊', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 Riwayat Sikat Gigi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lihat rekap sesi sikat gigimu! 💪',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.purple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String tanggalStr) {
    final scheme = Theme.of(context).colorScheme;
    final wifi = WifiService();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.45),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, $_namaUser! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tanggalStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                wifi.isConnected ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
              ),
              tooltip: wifi.isConnected ? 'Terhubung' : 'WiFi',
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const WifiScreen()));
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startBrushing,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🪥', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text(
              'Mulai Sikat Gigi!',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text('✨', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildSesiCard(String label, String emoji, bool sudah) {
    final isPagi = label == 'Pagi';
    final gradient = isPagi
        ? const LinearGradient(
            colors: [Color(0xFFFF9A3C), Color(0xFFFFD93D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF764BA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final shadowColor = isPagi ? Colors.orange : Colors.indigo;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: sudah
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sudah ? '✓ Sudah' : 'Belum',
              style: TextStyle(
                color: sudah
                    ? (isPagi ? const Color(0xFFFF9A3C) : const Color(0xFF6C63FF))
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
