import 'package:flutter/material.dart';
import '../../services/admin_api.dart';

class ActiveReportsTab extends StatefulWidget {
  const ActiveReportsTab({super.key});

  @override
  State<ActiveReportsTab> createState() => _ActiveReportsTabState();
}

class _ActiveReportsTabState extends State<ActiveReportsTab> {
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = AdminApi.getActiveReports();
  }

  Future<void> _closeReport(String caseId) async {
    await AdminApi.closeReport(caseId);
    setState(() {
      _loadReports(); // refresh list
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reports',
              style: TextStyle(color: Colors.red.shade600),
            ),
          );
        }

        final reports = snapshot.data ?? [];

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
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  'Case ID: ${report['case_id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text('Category: ${report['category'] ?? 'Unknown'}'),
                    Text('Severity: ${report['severity'] ?? 'LOW'}'),
                  ],
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await _closeReport(report['case_id']);
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
