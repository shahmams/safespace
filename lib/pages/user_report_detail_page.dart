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
  bool actionLoading = false;
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
      setState(() {
        report = data['report'];
        loading = false;
        actionLoading = false;
      });
    } catch (e) {
      debugPrint("Failed to load report: $e");
      if (mounted) {
        setState(() {
          loading = false;
          actionLoading = false;
        });
      }
    }
  }

  Future<void> acceptCounselling() async {
    setState(() => actionLoading = true);
    try {
      await http.post(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/report/${widget.caseId}/accept-support',
        ),
      );
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request submitted successfully!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await fetchReport();
    } catch (e) {
      debugPrint("Failed to accept counselling: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit request. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Status badge widget
  Widget _buildStatusBadge(String status, String label) {
    Color color;
    IconData icon;

    switch (status) {
      case 'ACTIVE':
        color = Colors.green.shade600;
        icon = Icons.circle_outlined;
        break;
      case 'CLOSED':
        color = Colors.grey.shade600;
        icon = Icons.check_circle_outline;
        break;
      default:
        color = Colors.blue.shade600;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Support status widget
  Widget _buildSupportStatus(String status) {
    Map<String, Map<String, dynamic>> statusConfig = {
      'NOT_REQUESTED': {
        'color': Colors.grey.shade600,
        'text': 'No Counselling Requested',
        'icon': Icons.person_outline,
        'description': 'You can request counselling support anytime',
      },
      'ADMIN_SUGGESTED': {
        'color': Colors.orange.shade600,
        'text': 'Counselling Suggested',
        'icon': Icons.lightbulb_outline,
        'description': 'A counsellor has been suggested for you',
      },
      'PENDING': {
        'color': Colors.deepOrange.shade600,
        'text': 'Awaiting Approval',
        'icon': Icons.pending_actions,
        'description': 'Your request is being reviewed',
      },
      'APPROVED': {
        'color': Colors.green.shade600,
        'text': 'Counselling Approved',
        'icon': Icons.verified,
        'description': 'You can start counselling sessions',
      },
      'IN_PROGRESS': {
        'color': Colors.blue.shade600,
        'text': 'Counselling in Progress',
        'icon': Icons.psychology,
        'description': 'You are receiving support',
      },
      'REJECTED': {
        'color': Colors.red.shade600,
        'text': 'Counselling Unavailable',
        'icon': Icons.block,
        'description': 'Counselling is not available for this case',
      },
    };

    final config = statusConfig[status] ?? {
      'color': Colors.grey.shade600,
      'text': 'Unknown Status',
      'icon': Icons.help_outline,
      'description': 'Status information unavailable',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config['color'].withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: config['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(config['icon'], color: config['color']),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['text'],
                  style: TextStyle(
                    color: config['color'],
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config['description'],
                  style: TextStyle(
                    color: config['color'].withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2B2B2B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Report Details",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: loading
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
              'Loading report details...',
              style: TextStyle(
                color: Color(0xFF7A7A7A),
              ),
            ),
          ],
        ),
      )
          : report == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load report',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: fetchReport,
              child: const Text('Try Again'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case ID Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B81),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Case Reference',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A7A7A),
                          ),
                        ),
                        Text(
                          widget.caseId,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status Section
            const Text(
              'Status Overview',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatusBadge(
                    report!['case_status'],
                    report!['case_status'] == 'ACTIVE'
                        ? 'Active Case'
                        : 'Case Closed',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Support Status
            _buildSupportStatus(report!['support_status']),

            const SizedBox(height: 32),

            // Your Message Section
            const Text(
              'Your Message',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report!['report_text'],
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2B2B2B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(report!['created_at']),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Section
            _buildActionSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        const months = [
          "Jan", "Feb", "Mar", "Apr", "May", "Jun",
          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ];
        return "${date.day} ${months[date.month - 1]} ${date.year}";
      }
    } catch (e) {
      return raw;
    }
  }

  Widget _buildActionSection() {
    final status = report!['support_status'];

    switch (status) {
      case 'NOT_REQUESTED':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF6B81).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.support_agent_outlined,
                size: 48,
                color: Color(0xFFFF6B81).withOpacity(0.8),
              ),
              const SizedBox(height: 16),
              const Text(
                'Need Support?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you feel you need professional support, you can request counselling anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: actionLoading ? null : acceptCounselling,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: actionLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Request Counselling',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'ADMIN_SUGGESTED':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Column(
            children: [
              Icon(
                Icons.thumb_up_outlined,
                size: 48,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
              const Text(
                'Counsellor Suggested',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A counsellor has been suggested for you based on your needs.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: actionLoading ? null : acceptCounselling,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: actionLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Accept Counselling',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'PENDING':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.pending_actions,
                size: 48,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Submitted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your request has been sent. Please wait for approval from our team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );

      case 'APPROVED':
      case 'IN_PROGRESS':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 48,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              const Text(
                'Counselling Active',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are currently receiving counselling support. Your counsellor will reach out to you soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7A7A7A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }
}