import 'package:flutter/material.dart';
import '../services/wifi_service.dart';
import '../services/preferences_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final _wifi = WifiService();
  final _prefs = PreferencesService();
  bool _connecting = false;

  Future<void> _connectDirect() async {
    setState(() => _connecting = true);
    final success = await _wifi.connectDirect();
    if (success) {
      await _prefs.setDevice(_wifi.esp32Ssid, '192.168.4.1');
    }
    if (!mounted) return;
    setState(() => _connecting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Berhasil terhubung ke ESP32!' : 'Gagal terhubung. Pastikan HP sudah tersambung ke WiFi ${_wifi.esp32Ssid}.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  Future<void> _connectManual(WifiDevice device) async {
    setState(() => _connecting = true);
    final success = await _wifi.connect(device);
    if (success) {
      await _prefs.setDevice(device.name, device.ip);
    }
    if (!mounted) return;
    setState(() => _connecting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Perangkat berhasil terhubung!' : 'Gagal terhubung. Coba lagi.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
    if (success) Navigator.of(context).pop();
  }

  Future<void> _disconnect() async {
    await _wifi.disconnect();
    await _prefs.clearDevice();
    if (!mounted) return;
    setState(() {});
  }

  void _showManualEntry() {
    final ipCtrl = TextEditingController(text: '192.168.4.1');
    final portCtrl = TextEditingController(text: '80');
    final nameCtrl = TextEditingController(text: 'dentifykids');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan IP Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Perangkat'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ipCtrl,
              decoration: const InputDecoration(
                labelText: 'Alamat IP',
                hintText: '192.168.4.1',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portCtrl,
              decoration: const InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final ip = ipCtrl.text.trim();
              final port = int.tryParse(portCtrl.text.trim()) ?? 80;
              final name = nameCtrl.text.trim().isEmpty
                  ? 'dentifykids'
                  : nameCtrl.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                _connectManual(WifiDevice(name: name, ip: ip, port: port));
              }
            },
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _wifi.isConnected;
    final deviceName = _wifi.connectedDevice?.name ?? '';
    final deviceIp = _wifi.connectedDevice?.ip ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Hubungkan Alat'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isConnected)
                _buildConnectedCard(deviceName, deviceIp)
              else ...[
                _buildInstructionCard(scheme),
                const SizedBox(height: 16),
                if (_connecting)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Menghubungkan ke ESP32...'),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _connectDirect,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Hubungkan ke dentifykids'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showManualEntry,
                      icon: const Icon(Icons.edit),
                      label: const Text('Masukkan IP Manual'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: null,
        onItemSelected: _selectNavItem,
      ),
    );
  }

  Widget _buildInstructionCard(ColorScheme scheme) {
    return Card(
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: scheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Cara Menghubungkan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _step('1', 'Buka Pengaturan WiFi di HP'),
            _step('2', 'Sambungkan ke: dentifykids'),
            _step('3', 'Password: 12345678'),
            _step('4', 'Kembali ke sini lalu tekan Hubungkan'),
          ],
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 10, child: Text(number, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
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
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildConnectedCard(String name, String ip) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.primary),
      ),
      child: ListTile(
        leading: Icon(Icons.wifi, color: scheme.primary),
        title: Text(name.isNotEmpty ? name : 'dentifykids'),
        subtitle: Text(ip),
        trailing: TextButton(
          onPressed: _disconnect,
          child: const Text('Putuskan'),
        ),
      ),
    );
  }
}
