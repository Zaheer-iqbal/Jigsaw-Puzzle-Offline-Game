# Proguard rules for Jigsaw Pro (Release Optimization)

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

-dontwarn io.flutter.embedding.engine.deferred.**
-dontwarn com.google.android.play.core.**

# Google Mobile Ads SDK
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# In-App Purchases (Google Play Billing)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**

# Audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# Native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
