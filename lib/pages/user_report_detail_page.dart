import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserReportDetailPage extends StatefulWidget {
  final String caseId;

  const UserReportDetailPage({super.key, required this.caseId});

  @override
  State<UserReportDetailPage> createState() => _UserReportDetailPageState();
}

class _UserReportDetailPageState extends State<UserReportDetailPage> {
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

  Future<void> acceptCounselling() async {
    await http.post(
      Uri.parse(
        'https://safespace-backend-z4d6.onrender.com/report/${widget.caseId}/accept-support',
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
        body: Center(child: Text("Unable to load report")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Report ${widget.caseId}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _info("Report Status", report!['case_status']),
            _info("Support Status", report!['support_status']),
            const SizedBox(height: 20),

            const Text(
              "Your Message",
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
            _buildAction(),
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

  Widget _buildAction() {
    final status = report!['support_status'];

    if (status == 'NOT_REQUESTED') {
      return Column(
        children: [
          const Text(
            "If you feel you need support, you can request counselling anytime.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: acceptCounselling,
            child: const Text("Request Counselling"),
          ),
        ],
      );
    }

    if (status == 'ADMIN_SUGGESTED') {
      return Column(
        children: [
          const Text(
            "A counsellor has been suggested for you.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: acceptCounselling,
            child: const Text("Accept Counselling"),
          ),
        ],
      );
    }

    if (status == 'PENDING') {
      return const Text(
        "Your request has been sent. Please wait for approval.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.orange),
      );
    }

    if (status == 'APPROVED' || status == 'IN_PROGRESS') {
      return const Text(
        "You are currently receiving counselling support.",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green),
      );
    }

    return const SizedBox();
  }
}
