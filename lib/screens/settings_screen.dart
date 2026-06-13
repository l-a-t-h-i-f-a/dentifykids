import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/wifi_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'game_screen.dart';
import 'scan_screen.dart';
import 'home_screen.dart';
import 'wifi_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();
  final _wifi = WifiService();
  final _nameCtrl = TextEditingController();
  final _geminiCtrl = TextEditingController();
  String _deviceName = '';
  String _deviceIp = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _geminiCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final nama = await _prefs.getNamaUser();
    final dName = await _prefs.getDeviceName();
    final dIp = await _prefs.getDeviceIp();
    final apiKey = await _prefs.getGeminiApiKey();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = nama;
      _deviceName = dName;
      _deviceIp = dIp;
      _geminiCtrl.text = apiKey;
    });
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await _prefs.setNamaUser(name);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nama tersimpan')));
  }

  Future<void> _disconnect() async {
    await _wifi.disconnect();
    await _prefs.clearDevice();
    if (!mounted) return;
    setState(() {
      _deviceName = '';
      _deviceIp = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Pengaturan'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Profil'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveName,
                child: const Text('Simpan Nama'),
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle('Perangkat SmartBrush'),
            const SizedBox(height: 12),
            if (_deviceIp.isNotEmpty) ...[
              Card(
                color: scheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: scheme.primary),
                ),
                child: ListTile(
                  leading: Icon(
                    _wifi.isConnected ? Icons.wifi : Icons.wifi_off,
                    color: scheme.primary,
                  ),
                  title: Text(
                    _deviceName.isNotEmpty ? _deviceName : 'SmartBrush',
                  ),
                  subtitle: Text(
                    _deviceIp,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: _disconnect,
                    child: const Text('Putuskan'),
                  ),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const WifiScreen()));
                  _load();
                },
                icon: const Icon(Icons.wifi),
                label: const Text('Hubungkan Perangkat'),
              ),
            ],
            // const SizedBox(height: 28),
            // _sectionTitle('Gemini AI (Pindai Gigi)'),
            // const SizedBox(height: 12),
            // TextField(
            //   controller: _geminiCtrl,
            //   decoration: const InputDecoration(
            //     labelText: 'API Key Gemini',
            //     hintText: 'AIza...',
            //     border: OutlineInputBorder(),
            //     prefixIcon: Icon(Icons.key_rounded),
            //   ),
            //   obscureText: true,
            // ),
            // const SizedBox(height: 12),
            // SizedBox(
            //   width: double.infinity,
            //   child: FilledButton(
            //     onPressed: _saveGeminiKey,
            //     child: const Text('Simpan API Key'),
            //   ),
            // ),
            const SizedBox(height: 28),
            _sectionTitle('Tentang Sesi'),
            const SizedBox(height: 8),
            _infoTile('Sesi Pagi', '05:00 – 11:59'),
            _infoTile('Sesi Malam', '18:00 – 23:59'),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: AppNavItem.settings,
        onItemSelected: _selectNavItem,
      ),
    );
  }

  void _selectNavItem(AppNavItem item) {
    if (item == AppNavItem.settings) return;

    Widget screen;
    switch (item) {
      case AppNavItem.home:
        screen = const HomeScreen();
      case AppNavItem.game:
        screen = const GameScreen();
      case AppNavItem.scan:
        screen = const ScanScreen();
      case AppNavItem.settings:
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
  );

  Widget _infoTile(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: Colors.grey.shade700)),
      ],
    ),
  );
}
