import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage all app preferences and state using SharedPreferences
/// This service handles non-sensitive data that should persist across app sessions
class PreferencesService {
  static SharedPreferences? _prefs;
  
  // Preference keys
  static const String _keyLastEmail = 'last_email';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyAutoLockEnabled = 'auto_lock_enabled';
  static const String _keyAutoLockDuration = 'auto_lock_duration';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyCacheEnabled = 'cache_enabled';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLocationTrackingEnabled = 'location_tracking_enabled';
  static const String _keyLastProofId = 'last_proof_id';
  static const String _keyAppVersion = 'app_version';
  static const String _keyUserId = 'user_id';
  static const String _keySessionToken = 'session_token';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyPinFailedAttempts = 'pin_failed_attempts';
  static const String _keyPinFreezeTimestamp = 'pin_freeze_timestamp';

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ============ Authentication & User Preferences ============
  
  /// Save last used email for convenience
  static Future<bool> setLastEmail(String email) async {
    return await prefs.setString(_keyLastEmail, email);
  }

  /// Get last used email
  static String? getLastEmail() {
    return prefs.getString(_keyLastEmail);
  }

  /// Clear last email
  static Future<bool> clearLastEmail() async {
    return await prefs.remove(_keyLastEmail);
  }

  /// Save user ID
  static Future<bool> setUserId(String userId) async {
    return await prefs.setString(_keyUserId, userId);
  }

  /// Get user ID
  static String? getUserId() {
    return prefs.getString(_keyUserId);
  }

  /// Clear user ID
  static Future<bool> clearUserId() async {
    return await prefs.remove(_keyUserId);
  }

  /// Set remember me preference
  static Future<bool> setRememberMe(bool remember) async {
    return await prefs.setBool(_keyRememberMe, remember);
  }

  /// Get remember me preference
  static bool getRememberMe() {
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // ============ App State & Onboarding ============
  
  /// Check if this is the first launch
  static bool isFirstLaunch() {
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// Mark first launch as completed
  static Future<bool> setFirstLaunchCompleted() async {
    return await prefs.setBool(_keyFirstLaunch, false);
  }

  /// Check if onboarding is completed
  static bool isOnboardingCompleted() {
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  /// Mark onboarding as completed
  static Future<bool> setOnboardingCompleted(bool completed) async {
    return await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  // ============ Security Preferences ============
  
  /// Enable/disable biometric authentication
  static Future<bool> setBiometricEnabled(bool enabled) async {
    return await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Check if biometric is enabled
  static bool isBiometricEnabled() {
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Enable/disable auto lock
  static Future<bool> setAutoLockEnabled(bool enabled) async {
    return await prefs.setBool(_keyAutoLockEnabled, enabled);
  }

  /// Check if auto lock is enabled
  static bool isAutoLockEnabled() {
    return prefs.getBool(_keyAutoLockEnabled) ?? false;
  }

  /// Set auto lock duration in minutes
  static Future<bool> setAutoLockDuration(int minutes) async {
    return await prefs.setInt(_keyAutoLockDuration, minutes);
  }

  /// Get auto lock duration in minutes
  static int getAutoLockDuration() {
    return prefs.getInt(_keyAutoLockDuration) ?? 5; // Default 5 minutes
  }

  // ============ Theme & Appearance ============
  
  /// Set theme mode (light, dark, system)
  static Future<bool> setThemeMode(String mode) async {
    return await prefs.setString(_keyThemeMode, mode);
  }

  /// Get theme mode
  static String getThemeMode() {
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  /// Set language preference
  static Future<bool> setLanguage(String languageCode) async {
    return await prefs.setString(_keyLanguage, languageCode);
  }

  /// Get language preference
  static String getLanguage() {
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  // ============ Feature Preferences ============
  
  /// Enable/disable cache
  static Future<bool> setCacheEnabled(bool enabled) async {
    return await prefs.setBool(_keyCacheEnabled, enabled);
  }

  /// Check if cache is enabled
  static bool isCacheEnabled() {
    return prefs.getBool(_keyCacheEnabled) ?? true; // Default enabled
  }

  /// Enable/disable notifications
  static Future<bool> setNotificationsEnabled(bool enabled) async {
    return await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Check if notifications are enabled
  static bool areNotificationsEnabled() {
    return prefs.getBool(_keyNotificationsEnabled) ?? true; // Default enabled
  }

  /// Enable/disable location tracking
  static Future<bool> setLocationTrackingEnabled(bool enabled) async {
    return await prefs.setBool(_keyLocationTrackingEnabled, enabled);
  }

  /// Check if location tracking is enabled
  static bool isLocationTrackingEnabled() {
    return prefs.getBool(_keyLocationTrackingEnabled) ?? true; // Default enabled
  }

  // ============ Sync & Data Management ============
  
  /// Save last sync timestamp
  static Future<bool> setLastSyncTime(DateTime time) async {
    return await prefs.setString(_keyLastSyncTime, time.toIso8601String());
  }

  /// Get last sync timestamp
  static DateTime? getLastSyncTime() {
    final timeString = prefs.getString(_keyLastSyncTime);
    if (timeString == null) return null;
    return DateTime.tryParse(timeString);
  }

  /// Save last viewed proof ID
  static Future<bool> setLastProofId(String proofId) async {
    return await prefs.setString(_keyLastProofId, proofId);
  }

  /// Get last viewed proof ID
  static String? getLastProofId() {
    return prefs.getString(_keyLastProofId);
  }

  /// Save app version
  static Future<bool> setAppVersion(String version) async {
    return await prefs.setString(_keyAppVersion, version);
  }

  /// Get app version
  static String? getAppVersion() {
    return prefs.getString(_keyAppVersion);
  }

  // ============ PIN Freeze Management ============
  
  /// Get failed PIN attempts count
  static int getPinFailedAttempts() {
    return prefs.getInt(_keyPinFailedAttempts) ?? 0;
  }

  /// Increment failed PIN attempts
  static Future<bool> incrementPinFailedAttempts() async {
    final current = getPinFailedAttempts();
    return await prefs.setInt(_keyPinFailedAttempts, current + 1);
  }

  /// Reset failed PIN attempts (on successful PIN entry)
  static Future<bool> resetPinFailedAttempts() async {
    return await prefs.remove(_keyPinFailedAttempts);
  }

  /// Set PIN freeze timestamp
  static Future<bool> setPinFreezeTimestamp(DateTime timestamp) async {
    return await prefs.setString(_keyPinFreezeTimestamp, timestamp.toIso8601String());
  }

  /// Get PIN freeze timestamp
  static DateTime? getPinFreezeTimestamp() {
    final timestampString = prefs.getString(_keyPinFreezeTimestamp);
    if (timestampString == null) return null;
    return DateTime.tryParse(timestampString);
  }

  /// Clear PIN freeze timestamp
  static Future<bool> clearPinFreezeTimestamp() async {
    return await prefs.remove(_keyPinFreezeTimestamp);
  }

  /// Check if PIN is currently frozen
  /// Returns remaining freeze seconds, or 0 if not frozen
  static int getPinFreezeRemainingSeconds() {
    final freezeTimestamp = getPinFreezeTimestamp();
    if (freezeTimestamp == null) return 0;
    
    const freezeDurationMinutes = 2;
    final freezeEndTime = freezeTimestamp.add(Duration(minutes: freezeDurationMinutes));
    final now = DateTime.now();
    
    if (now.isAfter(freezeEndTime)) {
      // Freeze period has ended, clear it
      clearPinFreezeTimestamp();
      resetPinFailedAttempts();
      return 0;
    }
    
    return freezeEndTime.difference(now).inSeconds;
  }

  /// Clear all PIN freeze data
  static Future<void> clearPinFreezeData() async {
    await prefs.remove(_keyPinFailedAttempts);
    await prefs.remove(_keyPinFreezeTimestamp);
  }

  // ============ Generic Methods ============
  
  /// Save any string value
  static Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }

  /// Get any string value
  static String? getString(String key) {
    return prefs.getString(key);
  }

  /// Save any boolean value
  static Future<bool> setBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }

  /// Get any boolean value
  static bool? getBool(String key) {
    return prefs.getBool(key);
  }

  /// Save any integer value
  static Future<bool> setInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }

  /// Get any integer value
  static int? getInt(String key) {
    return prefs.getInt(key);
  }

  /// Save any double value
  static Future<bool> setDouble(String key, double value) async {
    return await prefs.setDouble(key, value);
  }

  /// Get any double value
  static double? getDouble(String key) {
    return prefs.getDouble(key);
  }

  /// Save any string list
  static Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }

  /// Get any string list
  static List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }

  /// Remove a specific key
  static Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }

  /// Clear all preferences (use with caution)
  static Future<bool> clear() async {
    return await prefs.clear();
  }

  /// Clear user-specific data (call on logout)
  static Future<void> clearUserData() async {
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyLastEmail);
    await prefs.remove(_keySessionToken);
    await prefs.remove(_keyLastProofId);
    await prefs.remove(_keyLastSyncTime);
  }

  /// Check if a key exists
  static bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  /// Get all keys
  static Set<String> getAllKeys() {
    return prefs.getKeys();
  }

  /// Reload preferences from disk
  static Future<void> reload() async {
    await prefs.reload();
  }
}
