import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AnonIdStorage {
  static const _key = 'anon_id';

  static Future<String> getOrCreateAnonId() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Return existing ID
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    // ✅ Create ONCE
    final newId = _generateAnonId();
    await prefs.setString(_key, newId);
    return newId;
  }

  static String _generateAnonId() {
    final rand = Random();
    return 'U-${List.generate(8, (_) => rand.nextInt(36).toRadixString(36)).join()}';
  }

  // Optional debug
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
