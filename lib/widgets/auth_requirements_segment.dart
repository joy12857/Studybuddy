import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/validators.dart';

/// Interactive UI segment displaying real-time password criteria checklist
/// and a strength meter.
class PasswordRequirementsSegment extends StatelessWidget {
  final String password;

  const PasswordRequirementsSegment({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool hasLength = AuthValidators.hasMinLength(password);
    final bool hasUpper = AuthValidators.hasUppercase(password);
    final bool hasLower = AuthValidators.hasLowercase(password);
    final bool hasNum = AuthValidators.hasDigit(password);
    final bool hasSpecial = AuthValidators.hasSpecialChar(password);

    final double strength = AuthValidators.getPasswordStrength(password);
    final Color strengthColor = strength <= 0.4
        ? Colors.redAccent
        : strength <= 0.8
            ? Colors.orangeAccent
            : const Color(0xFF10B981); // Emerald green

    final String strengthLabel = strength == 0.0
        ? "Not entered"
        : strength <= 0.4
            ? "Weak"
            : strength <= 0.8
                ? "Moderate"
                : "Strong & Secure";

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: strength == 1.0
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFCCFBF1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 18,
                color: const Color(0xFF0F766E),
              ),
              const SizedBox(width: 8),
              Text(
                "Password Requirements",
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F766E),
                ),
              ),
              const Spacer(),
              if (password.isNotEmpty)
                Text(
                  strengthLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: strengthColor,
                  ),
                ),
            ],
          ),
          if (password.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildRequirementItem(
                label: "8+ characters",
                isMet: hasLength,
                isDark: isDark,
              ),
              _buildRequirementItem(
                label: "Uppercase letter (A-Z)",
                isMet: hasUpper,
                isDark: isDark,
              ),
              _buildRequirementItem(
                label: "Lowercase letter (a-z)",
                isMet: hasLower,
                isDark: isDark,
              ),
              _buildRequirementItem(
                label: "Number (0-9)",
                isMet: hasNum,
                isDark: isDark,
              ),
              _buildRequirementItem(
                label: "Special character (!@#\$%...)",
                isMet: hasSpecial,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem({
    required String label,
    required bool isMet,
    required bool isDark,
  }) {
    final activeColor = const Color(0xFF10B981);
    final inactiveColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet ? activeColor : inactiveColor.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            color: isMet ? activeColor : inactiveColor,
            decoration: isMet ? TextDecoration.none : null,
          ),
        ),
      ],
    );
  }
}

/// Interactive UI segment displaying real-time email format requirement and status.
class EmailRequirementSegment extends StatelessWidget {
  final String email;

  const EmailRequirementSegment({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trimmed = email.trim();
    final bool isValid = AuthValidators.isValidEmail(trimmed);
    final bool isEmpty = trimmed.isEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid
                ? Icons.mark_email_read_outlined
                : isEmpty
                    ? Icons.mail_outline_rounded
                    : Icons.error_outline_rounded,
            size: 16,
            color: isValid
                ? const Color(0xFF10B981)
                : isEmpty
                    ? const Color(0xFF0F766E)
                    : Colors.orangeAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid
                  ? "Valid email address format"
                  : "Email Requirement: Must be a valid address (e.g. name@domain.com)",
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
                color: isValid
                    ? const Color(0xFF10B981)
                    : isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

