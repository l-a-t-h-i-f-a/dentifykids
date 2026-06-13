import 'package:flutter/material.dart';
import '../models/brushing_record.dart';
import '../services/database_service.dart';
import '../utils/session_utils.dart';
import '../widgets/app_bottom_nav.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BrushingRecord> _records = [];
  bool _loading = true;
  late DateTime _weekStart;

  static const _dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // weekday: 1=Mon..7=Sun, subtract (weekday-1) days to get Monday
    _weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    _load();
  }

  Future<void> _load() async {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final records = await DatabaseService().getRecordsByDateRange(
      formatTanggal(_weekStart),
      formatTanggal(weekEnd),
    );
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  void _prevWeek() {
    setState(() {
      _loading = true;
      _weekStart = _weekStart.subtract(const Duration(days: 7));
    });
    _load();
  }

  void _nextWeek() {
    final nextMonday = _weekStart.add(const Duration(days: 7));
    final today = DateTime.now();
    if (nextMonday.isAfter(today)) return;
    setState(() {
      _loading = true;
      _weekStart = nextMonday;
    });
    _load();
  }

  bool _hasSesi(DateTime date, String sesi) {
    final tanggal = formatTanggal(date);
    return _records.any((r) => r.tanggal == tanggal && r.sesi == sesi);
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final headerLabel =
        '${_weekStart.day} ${_monthNames[_weekStart.month]} – '
        '${weekEnd.day} ${_monthNames[weekEnd.month]} ${weekEnd.year}';

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Riwayat Mingguan'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevWeek,
                  ),
                  Text(
                    headerLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextWeek,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildWeekList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: null,
        onItemSelected: _selectNavItem,
      ),
    );
  }

  void _selectNavItem(AppNavItem item) {
    Widget screen;
    switch (item) {
      case AppNavItem.home:
        screen = const HomeScreen();
      case AppNavItem.game:
        screen = const GameScreen();
      case AppNavItem.scan:
        screen = const ScanScreen();
      case AppNavItem.settings:
        screen = const SettingsScreen();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildWeekList() {
    final today = formatTanggal(DateTime.now());
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (_, i) {
        final date = _weekStart.add(Duration(days: i));
        final tanggal = formatTanggal(date);
        final isToday = tanggal == today;
        final pagiSudah = _hasSesi(date, 'pagi');
        final malamSudah = _hasSesi(date, 'malam');

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Column(
                    children: [
                      Text(
                        _dayNames[i],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      _statusChip('🌅 Pagi', pagiSudah),
                      const SizedBox(width: 8),
                      _statusChip('🌙 Malam', malamSudah),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, bool sudah) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: sudah
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sudah ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Icon(
              sudah ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: sudah ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
