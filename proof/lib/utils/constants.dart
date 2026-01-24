import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF00FF7F); // Neon green
  static const Color secondaryColor = Color(0xFF00FF7F); // Neon green
  static const Color backgroundColor = Colors.black;
  static const Color errorColor = Color(0xFFFF4C4C); // Neon red
  static const Color successColor = Color(0xFF00FF7F); // Neon green
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(
    0xFF999999,
  ); // Gray for secondary text
  static const Color neonGreen = Color(0xFF00FF7F);
  static const Color neonRed = Color(0xFFFF4C4C);
  static const Color neonOrange = Color(0xFFFF9500);
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
}

class AppStrings {
  static const String appName = 'ProofIt';
  static const String tagline =
      'Secure your evidence with blockchain-like integrity';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String createProof = 'Create Proof';
  static const String viewProofs = 'My Proofs';
  static const String settings = 'Settings';
  static const String title = 'Title';
  static const String description = 'Description';
  static const String enterPin = 'Enter your PIN to view this proof';
  static const String incorrectPin = 'Incorrect PIN';
  static const String proofLocked =
      'This proof is locked and cannot be modified';
}
