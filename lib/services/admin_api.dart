import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApi {
  static const String baseUrl =
      'https://safespace-backend-z4d6.onrender.com';

  // -------------------------------
  // GET ACTIVE REPORTS
  // -------------------------------
  static Future<List<Map<String, dynamic>>> getActiveReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/reports/active'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['reports']);
    } else {
      throw Exception('Failed to load active reports');
    }
  }

  // -------------------------------
  // CLOSE REPORT
  // -------------------------------
  static Future<void> closeReport(String caseId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/report/$caseId/close'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to close report');
    }
  }
}
