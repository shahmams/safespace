import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safespacee/utils/anon_id_storage.dart';
import 'write_page.dart';
import 'user_report_detail_page.dart';

class ReportsOverviewPage extends StatefulWidget {
  const ReportsOverviewPage({super.key});

  @override
  State<ReportsOverviewPage> createState() => _ReportsOverviewPageState();
}

class _ReportsOverviewPageState extends State<ReportsOverviewPage> {
  bool loading = true;
  List<Map<String, dynamic>> activeReports = [];
  List<Map<String, dynamic>> pastReports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final anonId = await AnonIdStorage.getOrCreateAnonId();

      final response = await http.get(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/reports/by-anon/$anonId',
        ),
      );

      final data = jsonDecode(response.body);
      final List reports = data['reports'];

      activeReports = reports
          .where((r) => r['case_status'] == 'ACTIVE')
          .cast<Map<String, dynamic>>()
          .toList();

      pastReports = reports
          .where((r) => r['case_status'] == 'CLOSED')
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      debugPrint("Failed to load reports: $e");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  // 🗓️ Format date → "14 Jan"
  String _formatDate(String raw) {
    final date = DateTime.parse(raw);
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${months[date.month - 1]}";
  }

  // 🏷️ Support status badge
  Widget _supportBadge(String? status) {
    Color color;
    String text;

    switch (status) {
      case 'ADMIN_SUGGESTED':
        color = Colors.orange;
        text = 'Counselling suggested';
        break;
      case 'PENDING':
        color = Colors.deepOrange;
        text = 'Waiting for approval';
        break;
      case 'APPROVED':
        color = Colors.green;
        text = 'Counselling approved';
        break;
      case 'REJECTED':
        color = Colors.red;
        text = 'Counselling unavailable';
        break;
      default:
        color = Colors.grey;
        text = 'No counselling requested';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Your Reports")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              children: [
                if (activeReports.isNotEmpty)
                  _section("Active Reports", activeReports),
                if (pastReports.isNotEmpty)
                  _section("Past Reports", pastReports),
                if (activeReports.isEmpty && pastReports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "No reports found.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WritePage(),
                    ),
                  );
                },
                child: const Text("Start new report"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Map<String, dynamic>> reports) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...reports.map((report) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserReportDetailPage(
                        caseId: report['case_id'],
                      ),
                    ),
                  );
                },
                title: Text(
                  "Reference ID: ${report['case_id']}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      "Submitted on ${_formatDate(report['created_at'])}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    _supportBadge(report['support_status']),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
