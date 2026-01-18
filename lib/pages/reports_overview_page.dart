import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:safespacee/utils/anon_id_storage.dart';
import 'write_page.dart';
import 'user_report_detail_page.dart';

class ReportsOverviewPage extends StatefulWidget {
  const ReportsOverviewPage({super.key});

  @override
  State<ReportsOverviewPage> createState() => _ReportsOverviewPageState();
}

class _ReportsOverviewPageState extends State<ReportsOverviewPage> {
  bool loading = true;
  bool refreshing = false;
  List<Map<String, dynamic>> activeReports = [];
  List<Map<String, dynamic>> pastReports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({bool showRefresh = false}) async {
    if (showRefresh) {
      setState(() => refreshing = true);
    }

    try {
      final anonId = await AnonIdStorage.getOrCreateAnonId();

      final response = await http.get(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/reports/by-anon/$anonId',
        ),
      );

      final data = jsonDecode(response.body);
      final List reports = data['reports'];

      setState(() {
        activeReports = reports
            .where((r) => r['case_status'] == 'ACTIVE')
            .cast<Map<String, dynamic>>()
            .toList();

        pastReports = reports
            .where((r) => r['case_status'] == 'CLOSED')
            .cast<Map<String, dynamic>>()
            .toList();
      });
    } catch (e) {
      debugPrint("Failed to load reports: $e");
      // Show error snackbar
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

  // 🗓️ Format date → "14 Jan 2024"
  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      const months = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return raw;
    }
  }

  // 🏷️ Support status badge with improved design
  Widget _supportBadge(String? status) {
    Map<String, Map<String, dynamic>> statusConfig = {
      'ADMIN_SUGGESTED': {
        'color': Colors.orange.shade600,
        'text': 'Counselling Suggested',
        'icon': Icons.lightbulb_outline,
      },
      'PENDING': {
        'color': Colors.deepOrange.shade600,
        'text': 'Pending Approval',
        'icon': Icons.pending_actions,
      },
      'APPROVED': {
        'color': Colors.green.shade600,
        'text': 'Counselling Approved',
        'icon': Icons.verified,
      },
      'REJECTED': {
        'color': Colors.red.shade600,
        'text': 'Counselling Unavailable',
        'icon': Icons.block,
      },
    };

    final config = statusConfig[status] ?? {
      'color': Colors.grey.shade600,
      'text': 'No Counselling Requested',
      'icon': Icons.info_outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config['color'].withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'],
            size: 14,
            color: config['color'],
          ),
          const SizedBox(width: 6),
          Text(
            config['text'],
            style: TextStyle(
              color: config['color'],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Empty state widget
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F6),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6B81).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 50,
              color: Color(0xFFFF6B81),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start your first report to begin your journey\nwith SafeSpace',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7A7A7A),
              height: 1.5,
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
        title: const Text(
          "My Reports",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _loadReports(showRefresh: true),
            icon: refreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded),
            color: const Color(0xFFFF6B81),
          ),
        ],
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
              'Loading your reports...',
              style: TextStyle(
                color: Color(0xFF7A7A7A),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () => _loadReports(showRefresh: true),
        color: const Color(0xFFFF6B81),
        child: CustomScrollView(
          slivers: [
            // Active Reports Section
            if (activeReports.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B81),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Active Reports",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B81),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activeReports.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

            // Active Reports List
            if (activeReports.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final report = activeReports[index];
                    return _buildReportCard(report, context);
                  },
                  childCount: activeReports.length,
                ),
              ),

            // Past Reports Section
            if (pastReports.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Past Reports",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pastReports.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

            // Past Reports List
            if (pastReports.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final report = pastReports[index];
                    return _buildReportCard(report, context, isPast: true);
                  },
                  childCount: pastReports.length,
                ),
              ),

            // Empty State
            if (activeReports.isEmpty && pastReports.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WritePage(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF6B81),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "New Report",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildReportCard(
      Map<String, dynamic> report,
      BuildContext context, {
        bool isPast = false,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserReportDetailPage(
                  caseId: report['case_id'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
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
                // Header with ID and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ID: ${report['case_id']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    Text(
                      _formatDate(report['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status badge
                _supportBadge(report['support_status']),

                const SizedBox(height: 12),

                // Case Status
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isPast ? Colors.grey.shade400 : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPast ? 'Case Closed' : 'Active Case',
                      style: TextStyle(
                        color: isPast ? Colors.grey.shade600 : Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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
                        color: const Color(0xFFFF6B81),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
  }
}