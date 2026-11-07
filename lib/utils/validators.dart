/// Utility class containing Regex definitions and validation logic
/// for Authentication (Email, Password) across the StudyBuddy app.
class AuthValidators {
  // ---------------------------------------------------------------------------
  // REGEX DEFINITIONS
  // ---------------------------------------------------------------------------

  /// Standard robust email regex conforming to RFC 5322 format.
  /// Requires alphanumeric characters, valid domain name, and minimum 2-char TLD.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password regex components:
  /// - Minimum 8 characters
  /// - At least 1 uppercase letter (A-Z)
  /// - At least 1 lowercase letter (a-z)
  /// - At least 1 numeric digit (0-9)
  /// - At least 1 special character (@$!%*?&_#^~`+=-)
  static final RegExp upperCaseRegex = RegExp(r'[A-Z]');
  static final RegExp lowerCaseRegex = RegExp(r'[a-z]');
  static final RegExp digitRegex = RegExp(r'[0-9]');
  static final RegExp specialCharRegex = RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\/\\~`']''');

  /// Complete single-regex pattern for password strength validation
  static final RegExp passwordFullRegex = RegExp(
    r'''^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-+=\[\]\/\\~`']).{8,}$''',
  );

  // ---------------------------------------------------------------------------
  // EMAIL VALIDATION
  // ---------------------------------------------------------------------------

  static bool isValidEmail(String? email) {
    if (email == null) return false;
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return emailRegex.hasMatch(trimmed);
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address.';
    }
    final trimmed = value.trim();
    if (!isValidEmail(trimmed)) {
      return 'Please enter a valid email address (e.g. name@domain.com).';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // PASSWORD VALIDATION
  // ---------------------------------------------------------------------------

  static bool hasMinLength(String password, {int minLength = 8}) =>
      password.length >= minLength;

  static bool hasUppercase(String password) =>
      upperCaseRegex.hasMatch(password);

  static bool hasLowercase(String password) =>
      lowerCaseRegex.hasMatch(password);

  static bool hasDigit(String password) =>
      digitRegex.hasMatch(password);

  static bool hasSpecialChar(String password) =>
      specialCharRegex.hasMatch(password);

  /// Returns true only if all password criteria are satisfied.
  static bool isValidPassword(String? password) {
    if (password == null) return false;
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasDigit(password) &&
        hasSpecialChar(password);
  }

  /// Calculates password strength score from 0.0 to 1.0
  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    int score = 0;
    if (hasMinLength(password)) score++;
    if (hasUppercase(password)) score++;
    if (hasLowercase(password)) score++;
    if (hasDigit(password)) score++;
    if (hasSpecialChar(password)) score++;
    return score / 5.0;
  }

  /// Returns descriptive error message or null if valid.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (!hasMinLength(value)) {
      return 'Password must be at least 8 characters long.';
    }
    if (!hasUppercase(value)) {
      return 'Password must contain at least one uppercase letter (A-Z).';
    }
    if (!hasLowercase(value)) {
      return 'Password must contain at least one lowercase letter (a-z).';
    }
    if (!hasDigit(value)) {
      return 'Password must contain at least one number (0-9).';
    }
    if (!hasSpecialChar(value)) {
      return 'Password must contain at least one special symbol (!@#\$%...).';
    }
    return null;
  }
}
