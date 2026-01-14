import 'dart:convert';
import 'dart:html' as html;

class ReportStorage {
  static const String _reportsKey = "reports";
  static const String _hasReportedKey = "hasReported";

  static Future<void> saveNewReport(String caseId) async {
    final reports = await getReports();

    reports.insert(0, {
      "caseId": caseId,
      "status": "ACTIVE",
    });

    html.window.localStorage[_reportsKey] = jsonEncode(reports);
    html.window.localStorage[_hasReportedKey] = "true";
  }

  static Future<List<Map<String, dynamic>>> getReports() async {
    final data = html.window.localStorage[_reportsKey];
    if (data == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<bool> hasReported() async {
    return html.window.localStorage[_hasReportedKey] == "true";
  }
}