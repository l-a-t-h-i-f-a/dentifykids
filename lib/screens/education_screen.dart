import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/app_bottom_nav.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  static const _sections = [
    _EducationSection(
      title: 'Cara menyikat gigi yang benar',
      icon: Icons.brush,
      points: [
        'Gunakan pasta gigi sebesar biji kacang.',
        'Sikat bagian depan, belakang, dan permukaan kunyah gigi.',
        'Gerakkan sikat pelan memutar selama 2 menit.',
      ],
    ),
    _EducationSection(
      title: 'Kesehatan gigi',
      icon: Icons.health_and_safety,
      points: [
        'Gigi berlubang bisa muncul karena sisa makanan dan gula.',
        'Pasta gigi berfluoride membantu melindungi email gigi.',
        'Makanan seperti buah, sayur, susu, dan air putih baik untuk gigi.',
      ],
    ),
    _EducationSection(
      title: 'Pengetahuan umum',
      icon: Icons.lightbulb,
      points: [
        'Menyikat terlalu keras bisa membuat gusi sakit.',
        'Ganti sikat gigi setiap 3 bulan atau saat bulunya rusak.',
        'Sikat gigi pagi setelah sarapan dan malam sebelum tidur.',
      ],
    ),
    _EducationSection(
      title: 'Tips merawat gigi',
      icon: Icons.star,
      points: [
        'Kurangi makanan manis dan lengket.',
        'Berkumur setelah makan jika belum sempat sikat gigi.',
        'Periksa gigi ke dokter secara rutin.',
      ],
    ),
  ];

  late final VideoPlayerController _videoController;
  late final Future<void> _initializeVideo;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(
      'assets/videos/video_edukasi.mp4',
    );
    _initializeVideo = _videoController.initialize();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Video Edukasi'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _VideoHeader(),
              const SizedBox(height: 16),
              _EducationVideoPlayer(
                controller: _videoController,
                initializeVideo: _initializeVideo,
              ),
              const SizedBox(height: 16),
              for (final section in _sections) ...[
                _EducationCard(section: section),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentItem: null,
        onItemSelected: (item) => _selectNavItem(context, item),
      ),
    );
  }

  void _selectNavItem(BuildContext context, AppNavItem item) {
    Widget screen;
    switch (item) {
      case AppNavItem.home:
        screen = const HomeScreen();
      case AppNavItem.game:
        screen = const GameScreen();
      case AppNavItem.settings:
        screen = const SettingsScreen();
      case AppNavItem.scan:
        screen = const ScanScreen();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }
}

class _EducationVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final Future<void> initializeVideo;

  const _EducationVideoPlayer({
    required this.controller,
    required this.initializeVideo,
  });

  @override
  State<_EducationVideoPlayer> createState() => _EducationVideoPlayerState();
}

class _EducationVideoPlayerState extends State<_EducationVideoPlayer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    if (widget.controller.value.isPlaying) {
      await widget.controller.pause();
    } else {
      await widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<void>(
          future: widget.initializeVideo,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                  child: Text(
                    'Video belum bisa diputar.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            final isPlaying = widget.controller.value.isPlaying;
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: widget.controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(widget.controller),
                        Material(
                          color: Colors.black.withValues(alpha: 0.22),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 34,
                            ),
                            onPressed: _togglePlay,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                VideoProgressIndicator(
                  widget.controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.only(top: 10),
                  colors: VideoProgressColors(
                    playedColor: scheme.primary,
                    bufferedColor: scheme.primaryContainer,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VideoHeader extends StatelessWidget {
  const _VideoHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.ondemand_video,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Edukasi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Materi video tentang sikat gigi dan kebiasaan sehat.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final _EducationSection section;

  const _EducationCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(section.icon, color: scheme.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final point in section.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 7, color: scheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EducationSection {
  final String title;
  final IconData icon;
  final List<String> points;

  const _EducationSection({
    required this.title,
    required this.icon,
    required this.points,
  });
}
