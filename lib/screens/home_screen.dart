import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../widgets/interactive_animations.dart';
import 'ai_quiz_screen.dart';
import 'chatbot_screen.dart';
import 'cgpa_simulator_screen.dart';
import 'course_manager_screen.dart';
import 'focus_flashcards_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'resources_tutor_screen.dart';
import 'study_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService auth = AuthService();
  String? fullName;
  bool isProfileLoading = true;

  final List<Map<String, String>> dailyQuotes = [
    {
      "quote": "“Education is the passport to the future, for tomorrow belongs to those who prepare for it today.”",
      "author": "Malcolm X"
    },
    {
      "quote": "“The expert in anything was once a beginner.”",
      "author": "Helen Hayes"
    },
    {
      "quote": "“Success is the sum of small efforts, repeated day in and day out.”",
      "author": "Robert Collier"
    },
    {
      "quote": "“Focus on your goal. Don't look in any direction but ahead.”",
      "author": "Anonymous"
    }
  ];

  late Map<String, String> activeQuote;

  @override
  void initState() {
    super.initState();
    activeQuote = (dailyQuotes..shuffle()).first;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = auth.currentUser;
      if (user != null) {
        final data = await SupabaseService.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (data != null && data['full_name'] != null) {
          setState(() {
            fullName = data['full_name'];
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        isProfileLoading = false;
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Future<void> logout() async {
    await auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final displayName = fullName ?? (user?.email?.split('@').first ?? "Student");

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "StudyBuddy",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F766E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Color(0xFF0F766E)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ).then((_) => _loadProfile());
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ).then((_) => _loadProfile());
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Text(
                        displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : "S",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    icon: Icons.home_rounded,
                    title: "Dashboard",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.account_circle_outlined,
                    title: "Academic Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      ).then((_) => _loadProfile());
                    },
                  ),
                  _drawerItem(
                    icon: Icons.menu_book_rounded,
                    title: "Course & Grade Manager",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CourseManagerScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.calculate_outlined,
                    title: "CGPA What-If Simulator",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CgpaSimulatorScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.quiz_outlined,
                    title: "AI Practice Quiz",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiQuizScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.timer_outlined,
                    title: "Focus & Flashcards",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FocusFlashcardsScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.auto_stories_rounded,
                    title: "Study Planner",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudyPlannerScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "AI Course Tutor",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.library_books_outlined,
                    title: "Free Resources & Tutors",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ResourcesTutorScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return SwitchListTile(
                        value: themeProvider.isDarkMode,
                        activeThumbColor: const Color(0xFF14B8A6),
                        secondary: Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: themeProvider.isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFFF59E0B),
                        ),
                        title: Text(
                          "Night Mode",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onChanged: (val) {
                          themeProvider.toggleTheme(val);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.grey),
                title: Text(
                  "Log Out",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.auto_stories_rounded, size: 35, color: Color(0xFF0F766E)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getGreeting(),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Daily Motivation Quote Card
            Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF332A15), const Color(0xFF1E293B)]
                          : [const Color(0xFFFFF7ED), const Color(0xFFFEF3C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.05 : 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Daily Study Inspiration",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        activeQuote["quote"]!,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "— ${activeQuote["author"]!}",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 25),

            // Main Student Ecosystem Features Grid
            Text(
              "Student Helper Hub",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 15),

            // Feature Grid View with Staggered Entrance Animations
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                FadeInSlide(
                  delay: const Duration(milliseconds: 50),
                  child: _dashboardCard(
                    "Course & Grade Manager",
                    Icons.menu_book_rounded,
                    const Color(0xFF0F766E),
                    const CourseManagerScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 100),
                  child: _dashboardCard(
                    "CGPA Simulator",
                    Icons.calculate_rounded,
                    const Color(0xFF0284C7),
                    const CgpaSimulatorScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 150),
                  child: _dashboardCard(
                    "AI Adaptive Quiz",
                    Icons.quiz_outlined,
                    const Color(0xFF10B981),
                    const AiQuizScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: _dashboardCard(
                    "Focus & Flashcards",
                    Icons.timer_outlined,
                    const Color(0xFF8B5CF6),
                    const FocusFlashcardsScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 250),
                  child: _dashboardCard(
                    "Study Planner",
                    Icons.auto_stories_rounded,
                    const Color(0xFFD97706),
                    const StudyPlannerScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 300),
                  child: _dashboardCard(
                    "AI Course Tutor",
                    Icons.chat_bubble_outline_rounded,
                    const Color(0xFF3B82F6),
                    const ChatbotScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 350),
                  child: _dashboardCard(
                    "Free Resources & Tutors",
                    Icons.library_books_rounded,
                    const Color(0xFFEC4899),
                    const ResourcesTutorScreen(),
                  ),
                ),
                FadeInSlide(
                  delay: const Duration(milliseconds: 400),
                  child: _dashboardCard(
                    "Academic Profile",
                    Icons.account_circle_rounded,
                    const Color(0xFF64748B),
                    const ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardCard(
    String title,
    IconData icon,
    Color color,
    Widget page,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color lightColor = Color.lerp(color, isDark ? Colors.black : Colors.white, 0.4)!;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, lightColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.4 : 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0F766E)),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF334155),
        ),
      ),
      onTap: onTap,
    );
  }
}