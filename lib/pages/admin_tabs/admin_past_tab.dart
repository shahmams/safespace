import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminPastTab extends StatefulWidget {
  const AdminPastTab({super.key});

  @override
  State<AdminPastTab> createState() => _AdminPastTabState();
}

class _AdminPastTabState extends State<AdminPastTab> {
  bool loading = true;
  List reports = [];

  @override
  void initState() {
    super.initState();
    _loadPastReports();
  }

  Future<void> _loadPastReports() async {
    final response = await http.get(
      Uri.parse(
        'https://safespace-backend-z4d6.onrender.com/admin/reports/past',
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
      return const Center(child: Text("No past reports"));
    }

    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return Card(
          child: ListTile(
            title: Text("Case ID: ${r['case_id']}"),
            subtitle: Text(
              "${r['category']} • ${r['severity']}",
            ),
          ),
        );
      },
    );
  }
}
