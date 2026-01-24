import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../models/pin_verification_result.dart';
import '../../services/preferences_service.dart';

class PinVerificationScreen extends StatefulWidget {
  final String proofId;
  final VoidCallback onSuccess;

  const PinVerificationScreen({
    super.key,
    required this.proofId,
    required this.onSuccess,
  });

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _isVerifying = false;
  int _freezeRemainingSeconds = 0;
  int _remainingAttempts = 3;
  Timer? _freezeTimer;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  // Neon colors
  static const neonGreen = Color(0xFF00FF7F);
  static const neonRed = Color(0xFFFF4C4C);
  static const neonOrange = Color(0xFFFF9500);

  @override
  void initState() {
    super.initState();
    _checkFreezeStatus();
    _startFreezeTimer();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _freezeTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _checkFreezeStatus() {
    final freezeSeconds = PreferencesService.getPinFreezeRemainingSeconds();
    final attempts = PreferencesService.getPinFailedAttempts();
    setState(() {
      _freezeRemainingSeconds = freezeSeconds;
      _remainingAttempts = 3 - attempts;
    });
  }

  void _startFreezeTimer() {
    _freezeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final freezeSeconds = PreferencesService.getPinFreezeRemainingSeconds();
      setState(() {
        _freezeRemainingSeconds = freezeSeconds;
      });

      if (freezeSeconds == 0 && _freezeRemainingSeconds > 0) {
        final attempts = PreferencesService.getPinFailedAttempts();
        setState(() {
          _remainingAttempts = 3 - attempts;
        });
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_pinController.text.isEmpty) {
      _showError('Please enter your PIN');
      _shakeController.forward(from: 0);
      return;
    }

    final freezeSeconds = PreferencesService.getPinFreezeRemainingSeconds();
    if (freezeSeconds > 0) {
      setState(() {
        _freezeRemainingSeconds = freezeSeconds;
      });
      _showError(
        'Too many failed attempts. Please wait ${_formatTime(freezeSeconds)} before trying again.',
      );
      _shakeController.forward(from: 0);
      return;
    }

    setState(() => _isVerifying = true);

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.verifyPin(_pinController.text);

    setState(() {
      _isVerifying = false;
      _freezeRemainingSeconds = result.freezeRemainingSeconds;
      _remainingAttempts = result.remainingAttempts;
    });

    if (!mounted) return;

    if (result.isValid) {
      widget.onSuccess();
      Navigator.of(context).pop(true);
    } else {
      if (result.isFrozen) {
        _showError(
          'Too many failed attempts. Account frozen for ${_formatTime(result.freezeRemainingSeconds)}',
        );
        _startFreezeTimer();
      } else {
        _showError(result.errorMessage ?? AppStrings.incorrectPin);
      }
      _shakeController.forward(from: 0);
      _pinController.clear();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''} ${secs > 0 ? 'and $secs second${secs > 1 ? 's' : ''}' : ''}';
    }
    return '$secs second${secs > 1 ? 's' : ''}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: neonRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrozen = _freezeRemainingSeconds > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Enter PIN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              // Animated Lock Icon
              if (isFrozen)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: neonRed, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: neonRed.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(Icons.lock, size: 64, color: neonRed),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: neonGreen, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: neonGreen.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.lock_outline, size: 64, color: neonGreen),
                ),

              const SizedBox(height: 40),

              // Title
              Text(
                isFrozen ? 'Account Frozen' : AppStrings.enterPin,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isFrozen ? neonRed : Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Freeze message and countdown
              if (isFrozen) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: neonRed.withOpacity(0.1),
                    border: Border.all(color: neonRed.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Too many failed attempts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: neonRed,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait before trying again',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Circular countdown
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: _freezeRemainingSeconds / 300,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  neonRed,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${_freezeRemainingSeconds ~/ 60}:${(_freezeRemainingSeconds % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: neonRed,
                                  ),
                                ),
                                Text(
                                  'remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Remaining attempts warning
                if (_remainingAttempts < 3 && _remainingAttempts > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: neonOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: neonOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: neonOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_remainingAttempts} attempt${_remainingAttempts > 1 ? 's' : ''} remaining',
                          style: TextStyle(
                            fontSize: 14,
                            color: neonOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // PIN input with shake animation
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _shakeAnimation.value *
                            (_shakeController.status == AnimationStatus.forward
                                ? 1
                                : -1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    autofocus: !isFrozen,
                    enabled: !isFrozen && !_isVerifying,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '● ● ● ● ● ●',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        letterSpacing: 12,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: neonGreen, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      counterText: '',
                    ),
                    onSubmitted: isFrozen ? null : (_) => _verifyPin(),
                  ),
                ),

                const SizedBox(height: 32),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (isFrozen || _isVerifying) ? null : _verifyPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withOpacity(0.1),
                      disabledForegroundColor: Colors.white.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            isFrozen ? 'Frozen' : 'Verify PIN',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Info text
              Text(
                'Enter your 6-digit PIN to unlock this proof',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
