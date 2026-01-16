import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminSpamTab extends StatefulWidget {
  const AdminSpamTab({super.key});

  @override
  State<AdminSpamTab> createState() => _AdminSpamTabState();
}

class _AdminSpamTabState extends State<AdminSpamTab> {
  bool loading = true;
  List reports = [];

  @override
  void initState() {
    super.initState();
    _loadSpamReports();
  }

  Future<void> _loadSpamReports() async {
    final response = await http.get(
      Uri.parse(
        'https://safespace-backend-z4d6.onrender.com/admin/reports/spam',
      ),
    );

    final data = jsonDecode(response.body);
    setState(() {
      reports = data['reports'];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return const Center(child: Text("No spam reports"));
    }

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return Card(
          child: ListTile(
            title: Text("Case ID: ${r['case_id']}"),
            subtitle: Text(r['report_text']),
          ),
        );
      },
    );
  }
}
