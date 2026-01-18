import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin_report_detail_page.dart';

class AdminSpamTab extends StatefulWidget {
  const AdminSpamTab({super.key});

  @override
  State<AdminSpamTab> createState() => _AdminSpamTabState();
}

class _AdminSpamTabState extends State<AdminSpamTab> {
  bool loading = true;
  bool refreshing = false;
  List reports = [];

  @override
  void initState() {
    super.initState();
    _loadSpamReports();
  }

  Future<void> _loadSpamReports({bool showRefresh = false}) async {
    if (showRefresh) {
      setState(() => refreshing = true);
    } else {
      setState(() => loading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('https://safespace-backend-z4d6.onrender.com/admin/reports/spam'),
      );

      final data = jsonDecode(response.body);

      setState(() {
        reports = data['reports'];
      });
    } catch (e) {
      debugPrint("Failed to load spam reports: $e");
      if (mounted && showRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh spam reports'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        loading = false;
        refreshing = false;
      });
    }
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return isoDate;
    }
  }

  String _truncateText(String text, {int maxLength = 80}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildSpamReason(String? reason) {
    final reasons = {
      'INAPPROPRIATE': {
        'color': Colors.red.shade600,
        'text': 'Inappropriate Content',
        'icon': Icons.block,
      },
      'SPAM': {
        'color': Colors.orange.shade600,
        'text': 'Spam Content',
        'icon': Icons.report_gmailerrorred,
      },
      'HARASSMENT': {
        'color': Colors.purple.shade600,
        'text': 'Harassment',
        'icon': Icons.warning_amber,
      },
      'OTHER': {
        'color': Colors.grey.shade600,
        'text': 'Other Violation',
        'icon': Icons.error_outline,
      },
    };

    final config = reasons[reason ?? 'OTHER'] ?? {
      'color': Colors.grey.shade600,
      'text': 'Spam Detected',
      'icon': Icons.error_outline,
    };

    final Color color = config['color'] as Color;
    final IconData icon = config['icon'] as IconData;
    final String text = config['text'] as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Spam Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Great! No spam or inappropriate content\nhas been detected recently.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7A7A7A),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportPreview(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        _truncateText(text),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade700,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFF6B81),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading spam reports...',
            style: TextStyle(
              color: Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: () => _loadSpamReports(showRefresh: true),
      color: const Color(0xFFFF6B81),
      child: reports.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          final reportText = report['report_text'] as String?;
          final createdAt = report['created_at'] as String?;
          final caseId = report['case_id']?.toString() ?? 'Unknown';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportDetailPage(
                        caseId: caseId,
                        fromSpam: true,
                      ),
                    ),
                  );
                  _loadSpamReports(showRefresh: true);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Case ID and Spam Reason
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Case #$caseId",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          _buildSpamReason(report['spam_reason'] as String?),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Report preview
                      if (reportText != null)
                        _buildReportPreview(reportText),

                      const SizedBox(height: 12),

                      // Date and View details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(createdAt ?? DateTime.now().toIso8601String()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Review',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF6B81),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFFFF6B81),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}