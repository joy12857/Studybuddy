import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin {
  int activeTab = 0; // 0: Breathing Coach, 1: Relaxing Tracks

  // Breathing Coach states
  bool isBreathing = false;
  int breathingSeconds = 0;
  Timer? breathingTimer;
  String breathingInstruction = "Press Start to Begin";
  double circleScale = 1.0;
  Color circleColor = const Color(0xFF8B5CF6);

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? playingTrackIndex;
  bool isAudioPlaying = false;
  Duration audioDuration = Duration.zero;
  Duration audioPosition = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _completeSub;
  StreamSubscription? _stateSub;

  // Royalty-free ambient audio URLs (from archive.org / freesound-compatible CDN)
  final List<Map<String, String>> tracks = [
    {
      "title": "Ocean Waves",
      "desc": "Soothing tidal rhythms for deep sleep",
      "icon": "🌊",
      "url":
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    },
    {
      "title": "Forest Rain",
      "desc": "Gentle rainfall and rustling leaves",
      "icon": "🌧️",
      "url":
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    },
    {
      "title": "Tibetan Singing Bowls",
      "desc": "Deep resonance for meditation focus",
      "icon": "🔔",
      "url":
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    },
    {
      "title": "Zen Flute",
      "desc": "Peaceful melody for calm mind",
      "icon": "🎵",
      "url":
          "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _durationSub = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => audioDuration = d);
    });
    _positionSub = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => audioPosition = p);
    });
    _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isAudioPlaying = false;
          playingTrackIndex = null;
          audioPosition = Duration.zero;
          audioDuration = Duration.zero;
        });
      }
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isAudioPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    breathingTimer?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Breathing Coach ───────────────────────────────────────────────────────

  void startBreathing() {
    setState(() {
      isBreathing = true;
      breathingSeconds = 0;
    });
    runBreathingCycle();
    breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => breathingSeconds++);
      runBreathingCycle();
    });
  }

  void stopBreathing() {
    breathingTimer?.cancel();
    setState(() {
      isBreathing = false;
      breathingInstruction = "Press Start to Begin";
      circleScale = 1.0;
      circleColor = const Color(0xFF8B5CF6);
    });
  }

  void runBreathingCycle() {
    int cycleTime = breathingSeconds % 12;
    if (cycleTime < 4) {
      setState(() {
        breathingInstruction = "Inhale slowly...";
        circleScale = 2.0;
        circleColor = const Color(0xFF8B5CF6);
      });
    } else if (cycleTime < 8) {
      setState(() {
        breathingInstruction = "Hold your breath...";
        circleScale = 2.0;
        circleColor = const Color(0xFFF59E0B);
      });
    } else {
      setState(() {
        breathingInstruction = "Exhale slowly...";
        circleScale = 1.0;
        circleColor = const Color(0xFF10B981);
      });
    }
  }

  // ── Audio Player ──────────────────────────────────────────────────────────

  Future<void> playTrack(int index) async {
    try {
      final url = tracks[index]["url"]!;
      await _audioPlayer.stop();
      setState(() {
        playingTrackIndex = index;
        audioPosition = Duration.zero;
        audioDuration = Duration.zero;
        isAudioPlaying = false;
      });
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.red.shade800,
            content: Text(
              "Could not play audio. Check your internet connection.",
              style: GoogleFonts.outfit(color: Colors.white),
            ),
          ),
        );
        setState(() => playingTrackIndex = null);
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (playingTrackIndex == null) return;
    if (isAudioPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> stopTrack() async {
    await _audioPlayer.stop();
    setState(() {
      playingTrackIndex = null;
      audioPosition = Duration.zero;
      audioDuration = Duration.zero;
      isAudioPlaying = false;
    });
  }

  Future<void> seekBy(int seconds) async {
    final newPos = audioPosition + Duration(seconds: seconds);
    final clamped = newPos.isNegative ? Duration.zero : newPos;
    await _audioPlayer.seek(clamped);
  }

  String formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  String formatTime(int totalSecs) {
    int mins = totalSecs ~/ 60;
    int secs = totalSecs % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Mindfulness & Meditation",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => activeTab = 0),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: activeTab == 0
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Breathing Coach",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: activeTab == 0
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => activeTab = 1),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: activeTab == 1
                              ? const Color(0xFF8B5CF6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "Relaxing Sounds",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: activeTab == 1
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: activeTab == 0
                ? _buildBreathingTab(theme)
                : _buildSoundsTab(theme),
          ),
          if (playingTrackIndex != null) _buildAudioPlayerPanel(theme),
        ],
      ),
    );
  }

  Widget _buildBreathingTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Guided Breathing Cycle",
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Slow down your heart rate and ease anxiety using box breathing.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 14, color: Colors.grey.shade500),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 240,
              height: 240,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(seconds: 4),
                curve: Curves.easeInOut,
                width: 100 * circleScale,
                height: 100 * circleScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor.withValues(alpha: 0.15),
                  border: Border.all(color: circleColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: circleColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.spa_rounded,
                    size: 32 * circleScale,
                    color: circleColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            breathingInstruction,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: circleColor,
            ),
          ),
          const SizedBox(height: 8),
          if (isBreathing)
            Text(
              "Timer: ${formatTime(breathingSeconds)}",
              style: GoogleFonts.outfit(
                  fontSize: 14, color: Colors.grey.shade500),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isBreathing ? stopBreathing : startBreathing,
              style: ElevatedButton.styleFrom(
                backgroundColor: isBreathing
                    ? Colors.red.shade600
                    : const Color(0xFF8B5CF6),
              ),
              child: Text(
                isBreathing ? "End Session" : "Start Breathing Exercise",
                style: GoogleFonts.outfit(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSoundsTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isCurrent = playingTrackIndex == index;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: isCurrent
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey.shade100),
          ),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isCurrent
                        ? const Color(0xFF8B5CF6)
                        : Colors.grey.shade500)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                track["icon"]!,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            title: Text(
              track["title"]!,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              track["desc"]!,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            trailing: IconButton(
              icon: Icon(
                isCurrent && isAudioPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                size: 40,
                color: isCurrent
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey.shade400,
              ),
              onPressed: () {
                if (isCurrent) {
                  togglePlayPause();
                } else {
                  playTrack(index);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioPlayerPanel(ThemeData theme) {
    final track = tracks[playingTrackIndex!];
    final progress = audioDuration.inMilliseconds > 0
        ? audioPosition.inMilliseconds / audioDuration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(track["icon"]!, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track["title"]!,
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        isAudioPlaying
                            ? "▶ Playing Ambient Soundscape"
                            : "⏸ Paused",
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: stopTrack,
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  formatDuration(audioPosition),
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                ),
                Expanded(
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    activeColor: const Color(0xFF8B5CF6),
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (val) async {
                      if (audioDuration.inMilliseconds > 0) {
                        final newPos = Duration(
                            milliseconds:
                                (val * audioDuration.inMilliseconds).toInt());
                        await _audioPlayer.seek(newPos);
                      }
                    },
                  ),
                ),
                Text(
                  formatDuration(audioDuration),
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 28),
                  onPressed: () => seekBy(-10),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: IconButton(
                    icon: Icon(
                      isAudioPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: togglePlayPause,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, size: 28),
                  onPressed: () => seekBy(10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
