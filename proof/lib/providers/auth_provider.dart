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

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  AuthProvider() {
    _initializeAuth();
    _listenToAuthState();
  }

  void _initializeAuth() {
    _currentUser = _authService.currentUser;
    _isOnboardingCompleted = PreferencesService.isOnboardingCompleted();
    if (_currentUser != null) {
      PreferencesService.setUserId(_currentUser!.id);
    }
    notifyListeners();
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

  Future<void> completeOnboarding() async {
    await PreferencesService.setOnboardingCompleted(true);
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  // Sign up
  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _authService.signUp(
        email: email,
        password: password,
      );

      _currentUser = response.user;
      if (_currentUser != null) {
        await PreferencesService.setUserId(_currentUser!.id);
      }
      _isLoading = false;
      notifyListeners();

      return response.user != null;
    } catch (e) {
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

      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      _currentUser = response.user;

      if (_currentUser != null) {
        await PreferencesService.setUserId(_currentUser!.id);
        await _pinService.syncPinFromCloud();
      }

      _isLoading = false;
      notifyListeners();

      return response.user != null;
    } catch (e) {
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

      final result = await _authService.signInWithGoogle();

      if (result) {
        _currentUser = _authService.currentUser;
        if (_currentUser != null) {
          await PreferencesService.setUserId(_currentUser!.id);
          await _pinService.syncPinFromCloud();
        }
      }

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      await PreferencesService.clearUserData();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Check if PIN is setup
  Future<bool> hasPinSetup() async {
    return await _pinService.hasPinSetup();
  }

  // Setup PIN
  Future<bool> setupPin(String pin) async {
    return await _pinService.setupPin(pin);
  }

  // Verify PIN (returns detailed result with freeze status)
  Future<PinVerificationResult> verifyPin(String pin) async {
    return await _pinService.verifyPin(pin);
  }

  // Legacy verifyPin method for backward compatibility
  Future<bool> verifyPinLegacy(String pin) async {
    final result = await _pinService.verifyPin(pin);
    return result.isValid && !result.isFrozen;
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    return await _pinService.changePin(oldPin, newPin);
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _pinService.deletePin();
      await _authService.deleteAccount();

      _currentUser = null;
      await PreferencesService.clearUserData();
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
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
