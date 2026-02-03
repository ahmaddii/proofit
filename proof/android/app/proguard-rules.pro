# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Notification Service
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Supabase & Json Serialization
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Google Sign In
-keepattributes *Annotation*
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# SharedPreferences
-keep class com.example.shared_preferences.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Prevent R8 from stripping native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Fix R8 Missing Class Errors for Play Core
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
