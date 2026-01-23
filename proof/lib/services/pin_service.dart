import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pin_verification_result.dart';
import 'preferences_service.dart';

class PinService {
  static const _storage = FlutterSecureStorage();
  static const String _pinStorageKey = 'user_pin_hash';
  final _supabase = Supabase.instance.client;

  // Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Setup PIN for first time
  Future<bool> setupPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        throw Exception('PIN must be 4-6 digits');
      }

      final hashedPin = _hashPin(pin);
      
      // Store locally
      await _storage.write(key: _pinStorageKey, value: hashedPin);
      
      // Store in Supabase
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('user_profiles').upsert({
          'id': userId,
          'pin_hash': hashedPin,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('PIN setup error: $e');
      return false;
    }
  }

  // Verify PIN with freeze protection
  Future<PinVerificationResult> verifyPin(String pin) async {
    try {
      // Check if PIN is currently frozen
      final freezeRemainingSeconds = PreferencesService.getPinFreezeRemainingSeconds();
      if (freezeRemainingSeconds > 0) {
        return PinVerificationResult.frozen(
          freezeRemainingSeconds: freezeRemainingSeconds,
        );
      }

      final storedHash = await _storage.read(key: _pinStorageKey);
      if (storedHash == null) {
        return PinVerificationResult.failed(
          remainingAttempts: 2,
          isFrozen: false,
          freezeRemainingSeconds: 0,
        );
      }
      
      final inputHash = _hashPin(pin);
      final isValid = inputHash == storedHash;

      if (isValid) {
        // Reset failed attempts on successful verification
        await PreferencesService.resetPinFailedAttempts();
        await PreferencesService.clearPinFreezeTimestamp();
        return PinVerificationResult.success();
      } else {
        // Increment failed attempts
        await PreferencesService.incrementPinFailedAttempts();
        final failedAttempts = PreferencesService.getPinFailedAttempts();
        final remainingAttempts = 3 - failedAttempts;

        // Freeze if 3 failed attempts reached
        if (failedAttempts >= 3) {
          await PreferencesService.setPinFreezeTimestamp(DateTime.now());
          return PinVerificationResult.frozen(
            freezeRemainingSeconds: 120, // 2 minutes = 120 seconds
          );
        }

        return PinVerificationResult.failed(
          remainingAttempts: remainingAttempts,
          isFrozen: false,
          freezeRemainingSeconds: 0,
        );
      }
    } catch (e) {
      print('PIN verification error: $e');
      return PinVerificationResult.failed(
        remainingAttempts: 2,
        isFrozen: false,
        freezeRemainingSeconds: 0,
      );
    }
  }

  // Legacy verifyPin method for backward compatibility (returns bool)
  // This is kept for places that still use the old API
  Future<bool> verifyPinLegacy(String pin) async {
    final result = await verifyPin(pin);
    return result.isValid && !result.isFrozen;
  }

  // Check if PIN exists
  Future<bool> hasPinSetup() async {
    final pin = await _storage.read(key: _pinStorageKey);
    return pin != null;
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final result = await verifyPin(oldPin);
      if (!result.isValid || result.isFrozen) {
        throw Exception(result.isFrozen 
            ? 'PIN is frozen. Please wait before trying again.'
            : 'Old PIN is incorrect');
      }
      
      // Reset attempts on successful PIN change
      await PreferencesService.resetPinFailedAttempts();
      await PreferencesService.clearPinFreezeTimestamp();
      
      return await setupPin(newPin);
    } catch (e) {
      print('PIN change error: $e');
      return false;
    }
  }

  // Delete PIN (for account deletion)
  Future<void> deletePin() async {
    await _storage.delete(key: _pinStorageKey);
    // Clear freeze data when PIN is deleted
    await PreferencesService.clearPinFreezeData();
  }

  // Sync PIN from Supabase (in case of device change)
  Future<void> syncPinFromCloud() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('user_profiles')
          .select('pin_hash')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['pin_hash'] != null) {
        await _storage.write(
          key: _pinStorageKey,
          value: response['pin_hash'] as String,
        );
      }
    } catch (e) {
      print('PIN sync error: $e');
    }
  }
}