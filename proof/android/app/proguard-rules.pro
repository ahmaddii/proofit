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
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Prevent R8 from stripping native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Fix R8 Missing Class Errors for Play Core
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**
