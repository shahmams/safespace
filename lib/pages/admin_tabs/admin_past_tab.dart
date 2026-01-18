import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin_report_detail_page.dart';

class AdminPastTab extends StatefulWidget {
  const AdminPastTab({super.key});

  @override
  State<AdminPastTab> createState() => _AdminPastTabState();
}

class _AdminPastTabState extends State<AdminPastTab> {
  bool loading = true;
  bool refreshing = false;
  List reports = [];

  @override
  void initState() {
    super.initState();
    _loadPastReports();
  }

  Future<void> _loadPastReports({bool showRefresh = false}) async {
    if (showRefresh) {
      setState(() => refreshing = true);
    } else {
      setState(() => loading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('https://safespace-backend-z4d6.onrender.com/admin/reports/past'),
      );

      final data = jsonDecode(response.body);
      setState(() {
        reports = data['reports'];
      });
    } catch (e) {
      debugPrint("Failed to load past reports: $e");
      if (mounted && showRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh reports'),
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

  Color _getCaseStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
        return Colors.green.shade600;
      case 'CLOSED':
        return Colors.blue.shade600;
      case 'ARCHIVED':
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildCaseStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCaseStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCaseStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getCaseStatusColor(status),
        ),
      ),
    );
  }

  Widget _buildSupportStatus(String? status) {
    Map<String, Map<String, dynamic>> statusConfig = {
      'APPROVED': {
        'color': Colors.green.shade600,
        'text': 'Support Approved',
        'icon': Icons.verified,
      },
      'COMPLETED': {
        'color': Colors.blue.shade600,
        'text': 'Support Completed',
        'icon': Icons.check_circle,
      },
      'REJECTED': {
        'color': Colors.red.shade600,
        'text': 'Support Rejected',
        'icon': Icons.block,
      },
      'NOT_REQUESTED': {
        'color': Colors.grey.shade600,
        'text': 'No Support Requested',
        'icon': Icons.person_outline,
      },
    };

    final config = statusConfig[status ?? 'NOT_REQUESTED'] ?? {
      'color': Colors.grey.shade600,
      'text': 'Support: ${status ?? 'Unknown'}',
      'icon': Icons.help_outline,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          config['icon'],
          size: 12,
          color: config['color'],
        ),
        const SizedBox(width: 4),
        Text(
          config['text'],
          style: TextStyle(
            fontSize: 11,
            color: config['color'],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
                Icons.archive_rounded,
                size: 40,
                color: Color(0xFF7A7A7A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Past Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All resolved and closed cases will\nappear here for reference',
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
            'Loading past reports...',
            style: TextStyle(
              color: Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: () => _loadPastReports(showRefresh: true),
      color: const Color(0xFFFF6B81),
      child: reports.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportDetailPage(caseId: report['case_id']),
                    ),
                  );
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
                      // Header with Case ID and Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Case #${report['case_id']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          _buildCaseStatusBadge(report['case_status'] ?? 'CLOSED'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Category and Support Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report['category'] ?? 'General',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                          ),
                          _buildSupportStatus(report['support_status']),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Severity and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label_important_outline,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${report['severity'] ?? 'LOW'} Severity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatDate((report['created_at'] ?? DateTime.now().toIso8601String()).toString()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // View details row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B81),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: const Color(0xFFFF6B81),
                            size: 20,
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