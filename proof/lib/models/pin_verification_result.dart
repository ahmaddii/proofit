/// Result of PIN verification attempt
class PinVerificationResult {
  final bool isValid;
  final bool isFrozen;
  final int remainingAttempts;
  final int freezeRemainingSeconds;
  final String? errorMessage;

  PinVerificationResult({
    required this.isValid,
    required this.isFrozen,
    required this.remainingAttempts,
    required this.freezeRemainingSeconds,
    this.errorMessage,
  });

  /// Successful PIN verification
  factory PinVerificationResult.success() {
    return PinVerificationResult(
      isValid: true,
      isFrozen: false,
      remainingAttempts: 3,
      freezeRemainingSeconds: 0,
    );
  }

  /// Failed PIN verification
  factory PinVerificationResult.failed({
    required int remainingAttempts,
    required bool isFrozen,
    required int freezeRemainingSeconds,
  }) {
    return PinVerificationResult(
      isValid: false,
      isFrozen: isFrozen,
      remainingAttempts: remainingAttempts,
      freezeRemainingSeconds: freezeRemainingSeconds,
      errorMessage: isFrozen
          ? 'Too many failed attempts. Please wait before trying again.'
          : 'Incorrect PIN. $remainingAttempts attempt(s) remaining.',
    );
  }

  /// PIN is frozen
  factory PinVerificationResult.frozen({required int freezeRemainingSeconds}) {
    return PinVerificationResult(
      isValid: false,
      isFrozen: true,
      remainingAttempts: 0,
      freezeRemainingSeconds: freezeRemainingSeconds,
      errorMessage: 'Too many failed attempts. Please wait before trying again.',
    );
  }
}
