import 'package:flutter_test/flutter_test.dart';
import 'package:study_buddy/utils/validators.dart';

void main() {
  group('AuthValidators - Email Regex', () {
    test('valid emails should pass', () {
      expect(AuthValidators.isValidEmail('user@example.com'), isTrue);
      expect(AuthValidators.isValidEmail('student.john@university.edu'), isTrue);
      expect(AuthValidators.isValidEmail('test_user+filter@sub.domain.org'), isTrue);
      expect(AuthValidators.validateEmail('user@example.com'), isNull);
    });

    test('invalid emails should fail', () {
      expect(AuthValidators.isValidEmail(''), isFalse);
      expect(AuthValidators.isValidEmail('notanemail'), isFalse);
      expect(AuthValidators.isValidEmail('missing@domain'), isFalse);
      expect(AuthValidators.isValidEmail('@domain.com'), isFalse);
      expect(AuthValidators.isValidEmail('user@.com'), isFalse);
      expect(AuthValidators.validateEmail(''), isNotNull);
      expect(AuthValidators.validateEmail('bad@email'), isNotNull);
    });
  });

  group('AuthValidators - Password Regex & Requirements', () {
    test('strong password satisfies all requirements', () {
      const strong = 'SecretPass123!';
      expect(AuthValidators.hasMinLength(strong), isTrue);
      expect(AuthValidators.hasUppercase(strong), isTrue);
      expect(AuthValidators.hasLowercase(strong), isTrue);
      expect(AuthValidators.hasDigit(strong), isTrue);
      expect(AuthValidators.hasSpecialChar(strong), isTrue);
      expect(AuthValidators.isValidPassword(strong), isTrue);
      expect(AuthValidators.validatePassword(strong), isNull);
      expect(AuthValidators.getPasswordStrength(strong), equals(1.0));
    });

    test('fails if missing uppercase', () {
      const noUpper = 'secretpass123!';
      expect(AuthValidators.hasUppercase(noUpper), isFalse);
      expect(AuthValidators.isValidPassword(noUpper), isFalse);
      expect(AuthValidators.validatePassword(noUpper), contains('uppercase'));
    });

    test('fails if missing lowercase', () {
      const noLower = 'SECRETPASS123!';
      expect(AuthValidators.hasLowercase(noLower), isFalse);
      expect(AuthValidators.isValidPassword(noLower), isFalse);
      expect(AuthValidators.validatePassword(noLower), contains('lowercase'));
    });

    test('fails if missing digit', () {
      const noDigit = 'SecretPass!@#';
      expect(AuthValidators.hasDigit(noDigit), isFalse);
      expect(AuthValidators.isValidPassword(noDigit), isFalse);
      expect(AuthValidators.validatePassword(noDigit), contains('number'));
    });

    test('fails if missing special character', () {
      const noSpecial = 'SecretPass123';
      expect(AuthValidators.hasSpecialChar(noSpecial), isFalse);
      expect(AuthValidators.isValidPassword(noSpecial), isFalse);
      expect(AuthValidators.validatePassword(noSpecial), contains('special'));
    });

    test('fails if too short', () {
      const shortPass = 'Sec1!';
      expect(AuthValidators.hasMinLength(shortPass), isFalse);
      expect(AuthValidators.isValidPassword(shortPass), isFalse);
      expect(AuthValidators.validatePassword(shortPass), contains('at least 8'));
    });
  });
}

