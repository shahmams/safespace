import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class AnonStorage {
  static const _key = "anon_id";
  static const _backendUrl = "https://safespace-backend-z4d6.onrender.com";

  /// Get anon_id from storage or backend
  static Future<String> getAnonId() async {
    final stored = html.window.localStorage[_key];
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    // fetch from backend
    final response = await http.get(
      Uri.parse("$_backendUrl/anon-id"),
    );

    final data = jsonDecode(response.body);
    final anonId = data["anon_id"];

    html.window.localStorage[_key] = anonId;
    return anonId;
  }
}
