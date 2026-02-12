import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/pin_service.dart';
import '../services/preferences_service.dart';
import '../models/pin_verification_result.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final PinService _pinService = PinService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnboardingCompleted = false;
  bool _isInitialized = false; // NEW: Track initialization state

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isInitialized => _isInitialized; // NEW: Expose initialization state

  AuthProvider() {
    _initializeAuth();
    _listenToAuthState();
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('🔄 AuthProvider: Starting initialization...');

      // Get current user from Supabase
      _currentUser = _authService.currentUser;

      // Load onboarding status from preferences
      _isOnboardingCompleted = PreferencesService.isOnboardingCompleted();

      debugPrint(
        '✅ AuthProvider: User=${_currentUser?.email}, Onboarding=$_isOnboardingCompleted',
      );

      if (_currentUser != null) {
        await PreferencesService.setUserId(_currentUser!.id);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AuthProvider initialization error: $e');
      // Set safe defaults on error
      _currentUser = null;
      _isOnboardingCompleted = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _listenToAuthState() {
    _authService.authStateChanges.listen((data) {
      final User? user = data.session?.user;
      if (_currentUser?.id != user?.id) {
        _currentUser = user;
        if (user != null) {
          PreferencesService.setUserId(user.id);
        }
        notifyListeners();
      }
    });
  }

  // NEW: Method to check auth status (called from main.dart)
  Future<void> checkAuthStatus() async {
    try {
      debugPrint('🔄 Checking auth status...');

      // Refresh current user
      _currentUser = _authService.currentUser;

      // Reload onboarding status
      _isOnboardingCompleted = PreferencesService.isOnboardingCompleted();

      debugPrint(
        '✅ Auth status - User: ${_currentUser != null}, Onboarding: $_isOnboardingCompleted',
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error checking auth status: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    try {
      debugPrint('🔄 Completing onboarding...');
      await PreferencesService.setOnboardingCompleted(true);
      _isOnboardingCompleted = true;
      debugPrint('✅ Onboarding completed successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      rethrow;
    }
  }

  // Sign up
  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔄 Signing up user: $email');

      final response = await _authService.signUp(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      if (_currentUser != null) {
        await PreferencesService.setUserId(_currentUser!.id);
        debugPrint('✅ Sign up successful: ${_currentUser!.email}');
      }
      _isLoading = false;
      notifyListeners();

      return response.user != null;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔄 Signing in user: $email');

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      _currentUser = response.user;

      if (_currentUser != null) {
        await PreferencesService.setUserId(_currentUser!.id);
        await _pinService.syncPinFromCloud();
        debugPrint('✅ Sign in successful: ${_currentUser!.email}');
      }

      _isLoading = false;
      notifyListeners();

      return response.user != null;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔄 Signing in with Google...');

      final result = await _authService.signInWithGoogle();

      if (result) {
        _currentUser = _authService.currentUser;
        if (_currentUser != null) {
          await PreferencesService.setUserId(_currentUser!.id);
          await _pinService.syncPinFromCloud();
          debugPrint('✅ Google sign in successful: ${_currentUser!.email}');
        }
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('🔄 Signing out...');
      await _authService.signOut();
      _currentUser = null;
      await PreferencesService.clearUserData();
      debugPrint('✅ Sign out successful');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Check if PIN is setup
  Future<bool> hasPinSetup() async {
    try {
      final hasPin = await _pinService.hasPinSetup();
      debugPrint('📌 PIN setup status: $hasPin');
      return hasPin;
    } catch (e) {
      debugPrint('❌ Error checking PIN setup: $e');
      return false;
    }
  }

  // Setup PIN
  Future<bool> setupPin(String pin) async {
    try {
      debugPrint('🔄 Setting up PIN...');
      final result = await _pinService.setupPin(pin);
      debugPrint(result ? '✅ PIN setup successful' : '❌ PIN setup failed');
      return result;
    } catch (e) {
      debugPrint('❌ PIN setup error: $e');
      return false;
    }
  }

  // Verify PIN (returns detailed result with freeze status)
  Future<PinVerificationResult> verifyPin(String pin) async {
    try {
      final result = await _pinService.verifyPin(pin);
      debugPrint(
        '📌 PIN verification: Valid=${result.isValid}, Frozen=${result.isFrozen}',
      );
      return result;
    } catch (e) {
      debugPrint('❌ PIN verification error: $e');
      rethrow;
    }
  }

  // Legacy verifyPin method for backward compatibility
  Future<bool> verifyPinLegacy(String pin) async {
    final result = await _pinService.verifyPin(pin);
    return result.isValid && !result.isFrozen;
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      debugPrint('🔄 Changing PIN...');
      final result = await _pinService.changePin(oldPin, newPin);
      debugPrint(result ? '✅ PIN changed successfully' : '❌ PIN change failed');
      return result;
    } catch (e) {
      debugPrint('❌ PIN change error: $e');
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔄 Deleting account...');

      await _pinService.deletePin();
      await _authService.deleteAccount();

      _currentUser = null;
      await PreferencesService.clearUserData();
      _isLoading = false;
      debugPrint('✅ Account deleted successfully');
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('❌ Account deletion error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
