import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin_report_detail_page.dart';

class AdminActiveTab extends StatefulWidget {
  const AdminActiveTab({super.key});

  @override
  State<AdminActiveTab> createState() => _AdminActiveTabState();
}

class _AdminActiveTabState extends State<AdminActiveTab> {
  bool loading = true;
  bool refreshing = false;
  List reports = [];

  @override
  void initState() {
    super.initState();
    fetchActiveReports();
  }

  String _normalize(String s) => s.trim().toUpperCase();

  int _severityRank(String s) {
    switch (_normalize(s)) {
      case 'CRITICAL':
        return 0;
      case 'HIGH':
        return 1;
      case 'MEDIUM':
        return 2;
      default:
        return 3;
    }
  }

  bool _isEmergency(String category) {
    return _normalize(category) == 'EMERGENCY';
  }

  Future<void> fetchActiveReports({bool showRefresh = false}) async {
    if (showRefresh) {
      setState(() => refreshing = true);
    } else {
      setState(() => loading = true);
    }

    try {
      final response = await http.get(
        Uri.parse('https://safespace-backend-z4d6.onrender.com/admin/reports/active'),
      );

      final data = jsonDecode(response.body);
      setState(() {
        reports = data['reports'];

        // Sort reports
        reports.sort((a, b) {
          final catA = (a['category'] ?? '').toString();
          final catB = (b['category'] ?? '').toString();
          final sevA = (a['severity'] ?? 'LOW').toString();
          final sevB = (b['severity'] ?? 'LOW').toString();

          final aEmergency = _isEmergency(catA);
          final bEmergency = _isEmergency(catB);

          if (aEmergency && !bEmergency) return -1;
          if (!aEmergency && bEmergency) return 1;

          return _severityRank(sevA).compareTo(_severityRank(sevB));
        });
      });
    } catch (e) {
      debugPrint("Failed to load active reports: $e");
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
      final now = DateTime.now();
      final difference = now.difference(date);

      const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

      if (difference.inDays == 0) {
        return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return "${date.day} ${months[date.month - 1]} ${date.year}";
      }
    } catch (e) {
      return isoDate;
    }
  }

  Color _severityColor(String severity) {
    switch (_normalize(severity)) {
      case 'CRITICAL':
        return Colors.red.shade600;
      case 'HIGH':
        return Colors.orange.shade600;
      case 'MEDIUM':
        return Colors.amber.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  Widget _buildSeverityBadge(String severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _severityColor(severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _severityColor(severity).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        severity,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _severityColor(severity),
        ),
      ),
    );
  }

  Widget _buildSupportStatus(String status) {
    Map<String, Map<String, dynamic>> statusConfig = {
      'NOT_REQUESTED': {
        'color': Colors.grey.shade600,
        'text': 'No Support',
        'icon': Icons.person_outline,
      },
      'PENDING': {
        'color': Colors.orange.shade600,
        'text': 'Pending',
        'icon': Icons.pending_actions,
      },
      'APPROVED': {
        'color': Colors.green.shade600,
        'text': 'Approved',
        'icon': Icons.verified,
      },
      'ADMIN_SUGGESTED': {
        'color': Colors.blue.shade600,
        'text': 'Suggested',
        'icon': Icons.lightbulb_outline,
      },
      'IN_PROGRESS': {
        'color': Colors.purple.shade600,
        'text': 'In Progress',
        'icon': Icons.psychology,
      },
    };

    final config = statusConfig[status] ?? {
      'color': Colors.grey.shade600,
      'text': 'Unknown',
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
                color: const Color(0xFFFFF4F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6B81).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 40,
                color: Color(0xFFFF6B81),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Reports',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All reports are currently processed\nor no active reports available',
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
            'Loading active reports...',
            style: TextStyle(
              color: Color(0xFF7A7A7A),
            ),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: () => fetchActiveReports(showRefresh: true),
      color: const Color(0xFFFF6B81),
      child: reports.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          final isEmergency = _isEmergency(report['category'] ?? '');

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportDetailPage(caseId: report['case_id']),
                    ),
                  );
                  fetchActiveReports(showRefresh: true);
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
                      // Header with Case ID and Emergency badge
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
                          if (isEmergency)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 12,
                                    color: Colors.red.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'EMERGENCY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Category and Severity
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
                          _buildSeverityBadge(report['severity'] ?? 'LOW'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Support Status and Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSupportStatus(report['support_status'] ?? 'UNKNOWN'),
                          Text(
                            formatDate((report['created_at'] ?? DateTime.now().toIso8601String()).toString()),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

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