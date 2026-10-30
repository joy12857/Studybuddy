import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/profile_sync_service.dart';
import '../widgets/interactive_animations.dart';
import 'academic_onboarding_screen.dart';

/// Shown after registration.
///
/// The user receives a 6-digit OTP in their email.
/// After entering the OTP successfully, they are
/// redirected to the HomeScreen.
class EmailVerifyScreen extends StatefulWidget {
  final String email;

  const EmailVerifyScreen({super.key, required this.email});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _verifying = false;
  bool _resending = false;

  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();

    _startResendTimer();

    // Automatically focus the OTP field shortly after
    // the screen opens.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _otpFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();

    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Resend countdown
  // ───────────────────────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendSeconds = 60;

    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Verify OTP
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showSnack('Please enter the verification code.', error: true);
      return;
    }

    if (otp.length != 6) {
      _showSnack(
        'Please enter the complete 6-digit verification code.',
        error: true,
      );
      return;
    }

    setState(() {
      _verifying = true;
    });

    try {
      await _authService.verifySignupOtp(email: widget.email, token: otp);

      if (!mounted) return;

      _showSnack('Email verified successfully!');

      // Give the success message a moment to display.
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _goHome();
    } catch (e) {
      if (!mounted) return;

      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Resend OTP
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _resending) {
      return;
    }

    setState(() {
      _resending = true;
    });

    try {
      await _authService.resendSignupOtp(widget.email);

      if (!mounted) return;

      _otpController.clear();

      _startResendTimer();

      _showSnack('A new verification code has been sent to ${widget.email}');

      _otpFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;

      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Go to Home
  // ───────────────────────────────────────────────────────────────────────────

  void _goHome() async {
    if (!mounted) return;

    // Sync name & dept from user metadata to SharedPreferences
    final user = _authService.currentUser;
    if (user != null) {
      await ProfileSyncService.syncProfileToLocal(user);
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AcademicOnboardingScreen()),
      (_) => false,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Snackbar
  // ───────────────────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: error ? Colors.red.shade800 : const Color(0xFF0F766E),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ───────────────────────────────────────────────────────────────────
          // Background
          // ───────────────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF1E293B),
                        const Color(0xFF0F2728),
                      ]
                    : [
                        const Color(0xFFE0F2FE),
                        const Color(0xFFF0FDFA),
                        const Color(0xFFFEF3C7),
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ───────────────────────────────────────────────────────────────────
          // Content
          // ───────────────────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeInSlide(
                  child: Column(
                    children: [
                      // ───────────────────────────────────────────────────────
                      // Email icon
                      // ───────────────────────────────────────────────────────
                      PulsingGlow(
                        glowColor: theme.colorScheme.primary,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white.withValues(alpha: 0.75),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.mark_email_unread_rounded,
                            size: 68,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ───────────────────────────────────────────────────────
                      // Title
                      // ───────────────────────────────────────────────────────
                      Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'We sent a 6-digit verification code to',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ───────────────────────────────────────────────────────
                      // Main card
                      // ───────────────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ───────────────────────────────────────────────
                            // Instructions
                            // ───────────────────────────────────────────────
                            _StepItem(
                              number: '1',
                              text: 'Open the email we sent you',
                              isDark: isDark,
                              theme: theme,
                            ),

                            const SizedBox(height: 14),

                            _StepItem(
                              number: '2',
                              text: 'Find the 6-digit verification code',
                              isDark: isDark,
                              theme: theme,
                            ),

                            const SizedBox(height: 14),

                            _StepItem(
                              number: '3',
                              text: 'Enter the code below to verify your email',
                              isDark: isDark,
                              theme: theme,
                            ),

                            const SizedBox(height: 28),

                            // ───────────────────────────────────────────────
                            // OTP label
                            // ───────────────────────────────────────────────
                            Text(
                              'Verification Code',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // ───────────────────────────────────────────────
                            // OTP field
                            // ───────────────────────────────────────────────
                            TextField(
                              controller: _otpController,
                              focusNode: _otpFocusNode,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 12,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '000000',
                                hintStyle: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 12,
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : Colors.grey.shade300,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) {
                                if (!_verifying) {
                                  _verifyOtp();
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            // ───────────────────────────────────────────────
                            // Verify button
                            // ───────────────────────────────────────────────
                            PressableScale(
                              onTap: _verifying ? null : _verifyOtp,
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: _verifying
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Verify Email',
                                            style: GoogleFonts.outfit(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ───────────────────────────────────────────────
                            // Resend
                            // ───────────────────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Didn't receive the code? ",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                _resending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : TextButton(
                                        onPressed: _resendSeconds == 0
                                            ? _resendOtp
                                            : null,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          _resendSeconds > 0
                                              ? 'Resend in ${_resendSeconds}s'
                                              : 'Resend Code',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: _resendSeconds == 0
                                                ? theme.colorScheme.primary
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ───────────────────────────────────────────────────────
                      // Security note
                      // ───────────────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Your verification code can only be used once.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numbered step widget
// ─────────────────────────────────────────────────────────────────────────────

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  final bool isDark;
  final ThemeData theme;

  const _StepItem({
    required this.number,
    required this.text,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
