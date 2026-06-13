import 'dart:io';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import '../services/wifi_service.dart';
import '../widgets/app_bottom_nav.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

enum _ScanState { idle, imageSelected, analyzing, result }

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  _ScanState _state = _ScanState.idle;
  File? _imageFile;
  GigiAnalysisResult? _result;
  String? _errorMsg;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureFromDevice() async {
    final wifi = WifiService();
    if (!wifi.isConnected) {
      setState(() {
        _errorMsg = 'Alat tidak terhubung. Hubungkan alat terlebih dahulu.';
      });
      return;
    }
    setState(() {
      _state = _ScanState.analyzing;
      _errorMsg = null;
    });
    try {
      final file = await wifi.captureImage();
      setState(() {
        _imageFile = file;
        _state = _ScanState.imageSelected;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
        _state = _ScanState.idle;
      });
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _state = _ScanState.analyzing;
      _errorMsg = null;
    });
    try {
      final result = await GeminiService().analyzeGigi(_imageFile!);
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _ScanState.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
        _state = _ScanState.imageSelected;
      });
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _imageFile = null;
      _result = null;
      _errorMsg = null;
    });
  }

  void _selectNavItem(AppNavItem item) {
    if (item == AppNavItem.scan) return;
    Widget screen;
    switch (item) {
      case AppNavItem.home:
        screen = const HomeScreen();
      case AppNavItem.game:
        screen = const GameScreen();
      case AppNavItem.settings:
        screen = const SettingsScreen();
      case AppNavItem.scan:
        return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pindai Gigi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_state == _ScanState.result)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Scan ulang',
              onPressed: _reset,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _state == _ScanState.result
              ? _buildResultPage()
              : _buildScanPage(),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: AppNavItem.scan,
        onItemSelected: _selectNavItem,
      ),
    );
  }

  // ─── Scan Page ────────────────────────────────────────────────────────────

  Widget _buildScanPage() {
    final scheme = Theme.of(context).colorScheme;
    final isAnalyzing = _state == _ScanState.analyzing;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight -
              kBottomNavigationBarHeight,
        ),
        child: Column(
          children: [
          const SizedBox(height: 24),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing outer ring while analyzing
              if (isAnalyzing)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, _) => Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: _pulseAnim.value),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              // Main circle
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isAnalyzing
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.35),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_rounded,
                            size: 60,
                            color: scheme.primary.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Foto dari alat',
                            style: TextStyle(
                              color: scheme.primary.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
              // "— scanning —" overlay
              if (isAnalyzing)
                Positioned(
                  bottom: 42,
                  child: Text(
                    '— scanning —',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              // Green dot
              if (isAnalyzing)
                Positioned(
                  bottom: 24,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, _) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.withValues(alpha: _pulseAnim.value),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (isAnalyzing) ...[
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          const Text(
            'Menganalisis foto gigi...',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ] else ...[
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Tombol ambil foto dari ESP32-CAM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _captureFromDevice,
                icon: const Icon(Icons.camera_rounded),
                label: const Text(
                  'Foto dari Alat',
                  style: TextStyle(fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          // const SizedBox(height: 10),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 32),
          //   child: SizedBox(
          //     width: double.infinity,
          //     height: 52,
          //     child: OutlinedButton.icon(
          //       onPressed: _pickFromGallery,
          //       icon: const Icon(Icons.photo_library_rounded),
          //       label: const Text(
          //         'Pilih dari Galeri',
          //         style: TextStyle(fontSize: 15),
          //       ),
          //       style: OutlinedButton.styleFrom(
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(14),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          if (_state == _ScanState.imageSelected) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _analyze,
                  icon: const Icon(Icons.search_rounded),
                  label: const Text(
                    'Analisis Gigi',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
      ),
    ),
    );
  }

  // ─── Result Page ──────────────────────────────────────────────────────────

  Widget _buildResultPage() {
    final scheme = Theme.of(context).colorScheme;
    final result = _result!;
    final healthColor = result.skorKesehatan >= 80
        ? Colors.green.shade600
        : result.skorKesehatan >= 60
            ? Colors.orange.shade600
            : Colors.red.shade600;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'hasil pindaian :',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 1. Gambar + skor
          _ResultCard(
            number: '1',
            label: 'gambar hasil scanning',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.primary, width: 2.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${result.skorKesehatan}',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: healthColor,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text('/100', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ),
                        ],
                      ),
                      Text(
                        result.kondisi,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (result.masalah.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: result.masalah
                              .map(
                                (m) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    m,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Grafik analisis
          _ResultCard(
            number: '2',
            label: 'grafik analisis',
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildBarChart(result.skorDetail),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Rekomendasi
          _ResultCard(
            number: null,
            label: null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hal yang harus dilakukan :',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'solusi jika kamu punya masalah gigi tersebut',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                ...result.rekomendasi.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(right: 10, top: 1),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> skorDetail) {
    final labels = {
      'kebersihan': 'Kebersihan',
      'warna': 'Warna',
      'karang_gigi': 'Karang',
      'kondisi_umum': 'Kondisi',
    };
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: labels.entries.map((e) {
          final skor = skorDetail[e.key] ?? 0;
          final barColor = skor >= 80
              ? Colors.green.shade400
              : skor >= 60
                  ? Colors.orange.shade400
                  : Colors.red.shade400;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$skor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 38,
                height: (skor / 100 * 80).clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e.value,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Shared Card Widget ────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final String? number;
  final String? label;
  final Widget child;

  const _ResultCard({this.number, this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.13),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (number != null || label != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (number != null)
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        number!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (label != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}
