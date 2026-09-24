# Flutter's engine keeps its own entry points; R8 must not strip them.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
