// lib/core/app_lifecycle.dart
// ──────────────────────────────────────────────────────────────
// État partagé pour gérer le splash après longue inactivité

class AppLifecycle {
  static DateTime? pausedAt;
  static bool needsSplash = false;
  static const splashThreshold = Duration(minutes: 3);
}
