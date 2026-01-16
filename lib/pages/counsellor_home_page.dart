import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'counsellor_report_detail_page.dart';

class CounsellorHomePage extends StatefulWidget {
  const CounsellorHomePage({super.key});

  @override
  State<CounsellorHomePage> createState() => _CounsellorHomePageState();
}

class _CounsellorHomePageState extends State<CounsellorHomePage> {
  bool loading = true;
  List reports = [];

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/counsellor/reports',
        ),
      );

      final data = jsonDecode(response.body);
      reports = data['reports'];
    } catch (e) {
      debugPrint("Failed to load counsellor reports: $e");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counsellor Dashboard'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(
        child: Text(
          "No counselling cases",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CounsellorReportDetailPage(
                      caseId: report['case_id'],
                    ),
                  ),
                );
                fetchReports(); // auto refresh
              },
              title: Text(
                report['case_id'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "${report['category']} • ${report['severity']}",
              ),
              trailing: Chip(
                label: Text(report['support_status']),
                backgroundColor:
                _statusColor(report['support_status'])
                    .withOpacity(0.15),
                labelStyle: TextStyle(
                  color: _statusColor(report['support_status']),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
