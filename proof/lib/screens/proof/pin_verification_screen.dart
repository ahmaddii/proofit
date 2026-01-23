import 'dart:async';
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

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final _pinController = TextEditingController();
  bool _isVerifying = false;
  int _freezeRemainingSeconds = 0;
  int _remainingAttempts = 3;
  Timer? _freezeTimer;

  @override
  void initState() {
    super.initState();
    _checkFreezeStatus();
    _startFreezeTimer();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _freezeTimer?.cancel();
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
        // Freeze period ended, reset attempts display
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
      return;
    }

    // Check if frozen before attempting verification
    final freezeSeconds = PreferencesService.getPinFreezeRemainingSeconds();
    if (freezeSeconds > 0) {
      setState(() {
        _freezeRemainingSeconds = freezeSeconds;
      });
      _showError('Too many failed attempts. Please wait ${_formatTime(freezeSeconds)} before trying again.');
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
        _showError('Too many failed attempts. Account frozen for ${_formatTime(result.freezeRemainingSeconds)}');
        _startFreezeTimer();
      } else {
        _showError(result.errorMessage ?? AppStrings.incorrectPin);
      }
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
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFrozen = _freezeRemainingSeconds > 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock icon - changes color when frozen
              Icon(
                isFrozen ? Icons.lock : Icons.lock_outline,
                size: 80,
                color: isFrozen ? AppColors.errorColor : AppColors.primaryColor,
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                isFrozen ? 'Account Frozen' : AppStrings.enterPin,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isFrozen ? AppColors.errorColor : AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Freeze message and countdown
              if (isFrozen) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Too many failed attempts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.errorColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait ${_formatTime(_freezeRemainingSeconds)} before trying again',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Countdown timer
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: _freezeRemainingSeconds, end: 0),
                        duration: Duration(seconds: _freezeRemainingSeconds),
                        builder: (context, value, child) {
                          return Text(
                            _formatTime(value),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.errorColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // Remaining attempts warning
                if (_remainingAttempts < 3 && _remainingAttempts > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_remainingAttempts} attempt${_remainingAttempts > 1 ? 's' : ''} remaining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_remainingAttempts < 3 && _remainingAttempts > 0)
                  const SizedBox(height: 24),
              ],
              
              const SizedBox(height: 24),
              
              // PIN input field
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: !isFrozen,
                enabled: !isFrozen && !_isVerifying,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'PIN',
                  prefixIcon: const Icon(Icons.pin),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    borderSide: BorderSide(
                      color: isFrozen 
                          ? AppColors.errorColor.withOpacity(0.3)
                          : AppColors.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.errorColor.withOpacity(0.3),
                    ),
                  ),
                ),
                onSubmitted: isFrozen ? null : (_) => _verifyPin(),
              ),
              
              const SizedBox(height: 24),
              
              // Verify button
              ElevatedButton(
                onPressed: (isFrozen || _isVerifying) ? null : _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFrozen 
                      ? AppColors.errorColor.withOpacity(0.5)
                      : AppColors.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isFrozen ? 'Frozen' : 'Verify PIN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}