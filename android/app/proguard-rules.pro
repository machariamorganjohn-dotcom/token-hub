# Flutter-specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Fonts
-keep class com.google.android.gms.** { *; }

# Prevent R8 from stripping interface information from serialized classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Preserve SharedPreferences
-keep class androidx.datastore.** { *; }

# Keep permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# Fix Play Core R8 missing class errors
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
