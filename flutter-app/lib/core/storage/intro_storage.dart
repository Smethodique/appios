// Nassreddin — new file. Remembers whether the first-launch guide has been
// shown, so it appears once and never again unless the parent asks for it
// from the "?" button in the home header.

import 'package:shared_preferences/shared_preferences.dart';

/// Whether the guided tour has already been seen on this device.
///
/// Cached in memory because the home screen decides synchronously, right after
/// its first frame, whether to open the tour. [load] runs once from main()
/// before runApp, so the answer is known before any screen builds.
abstract final class IntroStorage {
  /// Versioned on purpose: bumping the suffix re-shows the guide to everyone,
  /// which is what you want after adding or reordering steps.
  static const String _key = 'guide_seen_v1';

  // Defaults to "seen" so that a storage failure can never trap a parent in
  // the guide on every launch. Only a successful read can turn it off.
  static bool _seen = true;

  static bool get seen => _seen;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seen = prefs.getBool(_key) ?? false;
    } catch (_) {
      _seen = true;
    }
  }

  static Future<void> markSeen() async {
    _seen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // In-memory flag still holds for this session.
    }
  }
}
