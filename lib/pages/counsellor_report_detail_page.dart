import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CounsellorReportDetailPage extends StatefulWidget {
  final String caseId;

  const CounsellorReportDetailPage({super.key, required this.caseId});

  @override
  State<CounsellorReportDetailPage> createState() =>
      _CounsellorReportDetailPageState();
}

class _CounsellorReportDetailPageState
    extends State<CounsellorReportDetailPage> {
  bool loading = true;
  Map<String, dynamic>? report;

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/admin/report/${widget.caseId}',
        ),
      );

      final data = jsonDecode(response.body);
      report = data['report'];
    } catch (e) {
      debugPrint("Failed to load report: $e");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _postAction(String endpoint) async {
    await http.post(
      Uri.parse(
        'https://safespace-backend-z4d6.onrender.com/counsellor/report/${widget.caseId}/$endpoint',
      ),
    );
    fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (report == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load report")),
      );
    }

    final status = report!['support_status'];

    return Scaffold(
      appBar: AppBar(title: Text(widget.caseId)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _info("Category", report!['category']),
            _info("Severity", report!['severity']),
            _info("Location", report!['location'] ?? "Unknown"),
            _info("Support Status", status),
            const SizedBox(height: 20),

            const Text(
              "User Report",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(report!['report_text']),
            ),

            const SizedBox(height: 30),

            if (status == 'APPROVED')
              ElevatedButton(
                onPressed: () => _postAction('start'),
                child: const Text("Start Counselling"),
              ),

            if (status == 'IN_PROGRESS')
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => _postAction('close'),
                child: const Text("Close Counselling"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
