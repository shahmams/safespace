import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminReportDetailPage extends StatefulWidget {
  final String caseId;

  const AdminReportDetailPage({super.key, required this.caseId});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
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
          'https://safespace-backend-z4d6.onrender.com/admin/report/${widget
              .caseId}',
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
        'https://safespace-backend-z4d6.onrender.com/admin/report/${widget
            .caseId}/$endpoint',
      ),
    );
    fetchReport();
  }

  Future<void> _closeReport() async {
    await http.post(
      Uri.parse(
        'https://safespace-backend-z4d6.onrender.com/admin/report/${widget
            .caseId}/close',
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report closed')),
    );

    Navigator.pop(context);
  }

  void _confirmClose() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text('Close Report'),
            content: const Text(
              'Are you sure you want to close this report? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _closeReport();
                },
                child: const Text('Close Report'),
              ),
            ],
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

    if (report == null) {
      return const Scaffold(
        body: Center(child: Text("Failed to load report")),
      );
    }

    final bool isClosed = report!['case_status'] == 'CLOSED';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caseId),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _info("Category", report!['category']),
            _info("Severity", report!['severity']),
            _info("Location", report!['location'] ?? "Unknown"),
            _info("Case Status", report!['case_status']),
            _info(
              "Support Requested",
              report!['support_requested'] == 1 ? "Yes" : "No",
            ),
            _info("Support Status", report!['support_status']),

            const SizedBox(height: 20),

            const Text(
              "Report Text",
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

            if (!isClosed) ...[
              _buildActions(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  label: const Text('Close Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _confirmClose,
                ),
              ),
            ] else
              const Center(
                child: Text(
                  "This report is closed",
                  style: TextStyle(color: Colors.grey),
                ),
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
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final bool requested = report!['support_requested'] == 1;
    final String status = report!['support_status'];

    // 🟢 User requested counselling → Admin decision
    if (requested && status == 'PENDING') {
      return Column(
        children: [
          ElevatedButton(
            onPressed: () => _postAction('approve-support'),
            child: const Text("Approve Counselling"),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _postAction('reject-support'),
            child: const Text("Reject"),
          ),
        ],
      );
    }

    // 🟡 User did NOT request → Admin suggests
    if (!requested && status == 'NOT_REQUESTED') {
      return ElevatedButton(
        onPressed: () => _postAction('suggest-support'),
        child: const Text("Suggest Counselling"),
      );
    }

    // 🟣 Admin already suggested → waiting for user
    if (status == 'ADMIN_SUGGESTED') {
      return const Text(
        "Waiting for user to accept counselling",
        style: TextStyle(color: Colors.orange),
        textAlign: TextAlign.center,
      );
    }

    // 🔵 Approved (handled by counsellor later)
    if (status == 'APPROVED') {
      return const Text(
        "Counselling approved",
        style: TextStyle(color: Colors.green),
        textAlign: TextAlign.center,
      );
    }

    return const Text(
      "No actions available",
      style: TextStyle(color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }
}