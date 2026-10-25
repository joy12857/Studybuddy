import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Custom exception used by StudyBuddy authentication.
class AuthServiceException implements Exception {
  final String message;
  final String? code;

  const AuthServiceException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;

  // ===========================================================================
  // SIGN UP
  // ===========================================================================

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String department = '',
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'department': department.trim()},
      );

      return response;
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException(
        'Unable to create your account. Please try again.',
      );
    }
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  /// Normal email/password login.
  ///
  /// Verified users go directly to the dashboard.
  /// No OTP is requested for verified users.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      return response;
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException(
        'Unable to sign in. Please check your email and password.',
      );
    }
  }

  // ===========================================================================
  // VERIFY SIGNUP OTP
  // ===========================================================================

  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.signup,
      );

      return response;
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException('Invalid or expired verification code.');
    }
  }

  // ===========================================================================
  // RESEND OTP
  // ===========================================================================

  Future<void> resendSignupOtp(String email) async {
    try {
      await _supabase.auth.resend(type: OtpType.signup, email: email.trim());
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException(
        'Unable to resend the verification code.',
      );
    }
  }

  // ===========================================================================
  // OLD METHOD COMPATIBILITY
  // ===========================================================================

  Future<void> resendConfirmationEmail(String email) async {
    await resendSignupOtp(email);
  }

  // ===========================================================================
  // SIGN OUT
  // ===========================================================================

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Ignore sign-out errors.
    }
  }

  // ===========================================================================
  // DELETE ACCOUNT
  // ===========================================================================

  Future<void> deleteAccount() async {
    try {
      final user = currentUser;

      if (user != null) {
        try {
          await _supabase.from('profiles').delete().eq('id', user.id);
        } catch (_) {}

        try {
          await _supabase.from('moods').delete().eq('user_id', user.id);
        } catch (_) {}
      }
    } finally {
      await signOut();
    }
  }

  // ===========================================================================
  // PASSWORD RESET & UPDATE
  // ===========================================================================

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'io.supabase.studybuddy://reset-password/',
      );
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException(
        'Unable to send the password reset email.',
      );
    }
  }

  Future<void> verifyRecoveryOTP({required String email, required String token}) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException(
        'Invalid or expired verification code.',
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword.trim()),
      );
    } on AuthException catch (e) {
      throw AuthServiceException(e.message, code: e.code);
    } catch (_) {
      throw const AuthServiceException(
        'Failed to update password.',
      );
    }
  }

  // ===========================================================================
  // CURRENT USER
  // ===========================================================================

  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  // ===========================================================================
  // CURRENT SESSION
  // ===========================================================================

  Session? get currentSession {
    return _supabase.auth.currentSession;
  }

  // ===========================================================================
  // LOGIN STATUS
  // ===========================================================================

  bool get isLoggedIn {
    return currentUser != null;
  }
}
