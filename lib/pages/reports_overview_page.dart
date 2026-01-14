import 'package:flutter/material.dart';
import 'package:safespacee/utils/report_storage.dart';
import 'write_page.dart';

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
    final reports = await ReportStorage.getReports();

    activeReports =
        reports.where((r) => r["status"] == "ACTIVE").toList();

    pastReports =
        reports.where((r) => r["status"] == "CLOSED").toList();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Reports"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeReports.isNotEmpty) _activeSection(),
                if (pastReports.isNotEmpty) _pastSection(),
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

          // Fixed bottom button
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

  // ---------------- ACTIVE SECTION ----------------
  Widget _activeSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Active Reports",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...activeReports.map((report) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text("Reference ID: ${report["caseId"]}"),
                subtitle: const Text("Your report is being processed"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // future: report detail / chat page
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ---------------- PAST SECTION ----------------
  Widget _pastSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Past Reports",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...pastReports.map((report) {
            return Card(
              child: ListTile(
                title: Text("Reference ID: ${report["caseId"]}"),
                subtitle: const Text("Status: Closed"),
                trailing: TextButton(
                  onPressed: () {
                    // future: view-only details
                  },
                  child: const Text("View"),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
