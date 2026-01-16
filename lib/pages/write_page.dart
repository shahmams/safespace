import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'reports_overview_page.dart';
import 'package:safespacee/utils/anon_id_storage.dart';

class WritePage extends StatefulWidget {
  const WritePage({super.key});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  bool wantCounsellor = false;
  bool isLoading = false;

  final TextEditingController reportController = TextEditingController();

  Future<void> submitReport() async {
    if (reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ STEP 1: Get or create anon_id (ONLY ONCE)
      final anonId = await AnonIdStorage.getOrCreateAnonId();

      // ✅ STEP 2: Send report to backend
      final response = await http.post(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/report',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'anon_id': anonId,
          'report_text': reportController.text.trim(),
          'support_requested': wantCounsellor,
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final caseId = data['case_id'];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Report Submitted'),
            content: Text(
              'Your case ID is:\n\n$caseId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  reportController.clear();
                  wantCounsellor = false;

                  Navigator.pop(context); // close dialog

                  // ✅ Go to overview page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportsOverviewPage(),
                    ),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error, try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'SafeSpace',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'You can write as much or little you want',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Container(
                  height: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: reportController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText: 'Write here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: const [
                    Icon(Icons.attach_file, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Attach files (optional)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Images, videos, or documents',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'I would like to talk to a counselor',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Switch(
                      value: wantCounsellor,
                      onChanged: (value) {
                        setState(() {
                          wantCounsellor = value;
                        });
                      },
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    wantCounsellor
                        ? 'A counselor will reach out.'
                        : 'You can stop anytime.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B86A4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
