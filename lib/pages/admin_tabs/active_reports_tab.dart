import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin_report_detail_page.dart';

class AdminActiveTab extends StatefulWidget {
  const AdminActiveTab({super.key});

  @override
  State<AdminActiveTab> createState() => _AdminActiveTabState();
}

class _AdminActiveTabState extends State<AdminActiveTab> {
  bool loading = true;
  List reports = [];

  @override
  void initState() {
    super.initState();
    fetchActiveReports();
  }

  Future<void> fetchActiveReports() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/admin/reports/active',
        ),
      );

      final data = jsonDecode(response.body);
      reports = data['reports'];
    } catch (e) {
      debugPrint("Failed to load active reports: $e");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  // ✅ CLEAN DATE FORMAT (16 Jan)
  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${date.day} ${months[date.month - 1]}";
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return const Center(
        child: Text(
          'No active reports',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminReportDetailPage(
                    caseId: report['case_id'],
                  ),
                ),
              );

              // 🔄 REFRESH LIST AFTER RETURN
              fetchActiveReports();
            },

            title: Text(
              report['case_id'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                Text(
                  "${report['category']} • ${report['severity']}",
                  style: TextStyle(
                    color: _severityColor(report['severity']),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                // ✅ SUPPORT STATUS SHOWN
                Text(
                  "Support: ${report['support_status']}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),

                const SizedBox(height: 4),

                // ✅ CLEAN DATE
                Text(
                  "Created: ${formatDate(report['created_at'])}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}
