import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/profile_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://klfxswdtprujmapxfqjg.supabase.co',
    publishableKey: 'sb_publishable_6bwXXqJc0N-z-cS7l0_lKA_aT2wwwIf',
    authOptions: const FlutterAuthClientOptions(
      // PKCE flow + deep link detection handles email confirmation links
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyBuddy',
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
    );
  }
}


/// Checks for an active Supabase session and routes accordingly.
/// Handles password recovery link clicks directly.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Sync profile to local storage on app start if already logged in
    _syncOnStart();
  }

  Future<void> _syncOnStart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await ProfileSyncService.syncProfileToLocal(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final authState = snapshot.data;
        final event = authState?.event;

        // Check if the user clicked a password reset link in their email
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }

        // While the stream hasn't emitted yet, use the cached session
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (session != null) {
            return const HomeScreen();
          }
          return const _SplashScreen();
        }

        // Sync profile when user signs in via auth state change
        if (event == AuthChangeEvent.signedIn && authState?.session?.user != null) {
          ProfileSyncService.syncProfileToLocal(authState!.session!.user);
        }

        final hasSession = authState?.session != null;

        if (hasSession) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 72,
              color: const Color(0xFF0F766E).withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              "StudyBuddy",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F766E),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFF0F766E),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
