import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../admin_report_detail_page.dart';

class AdminActiveTab extends StatefulWidget {
  const AdminActiveTab({super.key});

  @override
  State<AdminActiveTab> createState() => _AdminActiveTabState();
}

class _AdminActiveTabState extends State<AdminActiveTab> with TickerProviderStateMixin {
  bool loading = true;
  bool refreshing = false;
  bool emergencyShown = false;
  List reports = [];
  String selectedCategory = "ALL";
  String selectedSeverity = "ALL";
  String selectedSort = "PRIORITY";
  String? lastEmergencyCaseId;

  // Animation controllers - declare them but initialize in initState
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Fetch reports
    fetchActiveReports();

    // Start emergency polling
    startEmergencyPolling();
  }
  void startEmergencyPolling() {
    Future.doWhile(() async {

      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return false;

      await checkEmergencyAlert();

      return true;

    });
  }
  Future<void> checkEmergencyAlert() async {
    try {

      final response = await http.get(
        Uri.parse(
            "https://safespace-jauf.onrender.com/admin/emergency-alert"
        ),
      );

      final data = jsonDecode(response.body);

      if (data["alert"] == true) {


        final caseId = data["case"]["case_id"];

        // prevent repeat popup
        if (lastEmergencyCaseId == caseId) return;

        lastEmergencyCaseId = caseId;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("🚨 CRITICAL EMERGENCY"),
            content: Text(
                "Emergency reported at\n${data["case"]["location"].toString().replaceAll("_", " ").toUpperCase()}"
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {

                  await http.post(
                    Uri.parse(
                        "https://safespace-jauf.onrender.com/admin/emergency-seen/$caseId"
                    ),
                  );

                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminReportDetailPage(
                        caseId: caseId,
                      ),
                    ),
                  );

                },
                child: const Text("VIEW"),
              )
            ],
          ),
        );

      }

    } catch (e) {
      debugPrint("Emergency check failed: $e");
    }
  }
  @override
  void dispose() {
    _fadeController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start animation after dependencies are loaded
    if (_fadeController != null && !_fadeController.isAnimating) {
      _fadeController.forward();
    }
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
        Uri.parse('https://safespace-jauf.onrender.com/admin/reports/active'),
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

      // Start animation when data is loaded
      if (_fadeController != null && !_fadeController.isAnimating) {
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint("Failed to load active reports: $e");
      if (mounted && showRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Failed to refresh reports'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
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
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFF97316);
      case 'MEDIUM':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _severityIcon(String severity) {
    switch (_normalize(severity)) {
      case 'CRITICAL':
        return Icons.warning_amber_rounded;
      case 'HIGH':
        return Icons.priority_high;
      case 'MEDIUM':
        return Icons.remove_circle_outline;
      default:
        return Icons.low_priority;
    }
  }

  Widget _buildSeverityBadge(String severity) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _severityIcon(severity),
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            severity,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportStatus(String status) {
    Map<String, Map<String, dynamic>> statusConfig = {
      'NOT_REQUESTED': {
        'color': Colors.grey.shade600,
        'text': 'Not Requested',
        'icon': Icons.person_outline,
        'bgColor': Colors.grey.shade50,
      },
      'PENDING': {
        'color': const Color(0xFFF97316),
        'text': 'Pending Review',
        'icon': Icons.pending_actions,
        'bgColor': const Color(0xFFFFF7E6),
      },
      'APPROVED': {
        'color': const Color(0xFF10B981),
        'text': 'Approved',
        'icon': Icons.verified,
        'bgColor': const Color(0xFFE6F7F0),
      },
      'ADMIN_SUGGESTED': {
        'color': const Color(0xFF3B82F6),
        'text': 'Support Suggested',
        'icon': Icons.lightbulb_outline,
        'bgColor': const Color(0xFFE6F0FF),
      },
      'IN_PROGRESS': {
        'color': const Color(0xFF8B5CF6),
        'text': 'In Progress',
        'icon': Icons.psychology,
        'bgColor': const Color(0xFFF0E6FF),
      },
    };

    final config = statusConfig[status] ?? {
      'color': Colors.grey.shade600,
      'text': 'Unknown',
      'icon': Icons.help_outline,
      'bgColor': Colors.grey.shade50,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['bgColor'],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String groupValue, Function(String) onSelected) {
    final isSelected = value == groupValue;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: Colors.grey.shade50,
      selectedColor: const Color(0xFFFF6B81),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFF4F6),
                      const Color(0xFFFFE5E9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B81).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inbox_rounded,
                  size: 50,
                  color: Color(0xFFFF6B81),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Active Reports',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All clear! There are no active reports\nat the moment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'All reports processed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safely check if animations are initialized
    if (_fadeController == null || _fadeAnimation == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B81)),
        ),
      );
    }

    List filteredReports = reports.where((report) {
      if (selectedCategory != "ALL" && report['category'] != selectedCategory) {
        return false;
      }
      if (selectedSeverity != "ALL" && report['severity'] != selectedSeverity) {
        return false;
      }
      return true;
    }).toList();

    if (selectedSort == "NEWEST") {
      filteredReports.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    } else if (selectedSort == "OLDEST") {
      filteredReports.sort((a, b) =>
          DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
    }

    // Category counts for chips
    final categoryCounts = <String, int>{};
    for (var report in filteredReports) {
      final cat = report['category'] ?? 'General';
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    return loading
        ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B81)),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading active reports...',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        : RefreshIndicator(
      onRefresh: () => fetchActiveReports(showRefresh: true),
      color: const Color(0xFFFF6B81),
      backgroundColor: Colors.white,
      strokeWidth: 2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter Bar Sliver
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (selectedCategory != "ALL" || selectedSeverity != "ALL")
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = "ALL";
                                selectedSeverity = "ALL";
                                selectedSort = "PRIORITY";
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Clear all',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFFFF6B81),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Category Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'All Categories (${reports.length})',
                          "ALL",
                          selectedCategory,
                              (v) => setState(() => selectedCategory = v),
                        ),
                        const SizedBox(width: 8),
                        ...['Emergency', 'Ragging and Bullying', 'Mental Stress', 'Abuse and Harassment', 'College Safety']
                            .map((cat) {
                          final count = categoryCounts[cat] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              '$cat${count > 0 ? ' ($count)' : ''}',
                              cat,
                              selectedCategory,
                                  (v) => setState(() => selectedCategory = v),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Severity and Sort Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Severity Dropdown
                        Expanded(
                          child: Container(
                            height: 45,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedSeverity,
                                isExpanded: true,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                                items: [
                                  DropdownMenuItem(
                                    value: "ALL",
                                    child: Row(
                                      children: [
                                        Icon(Icons.filter_list, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text('All Severity', style: TextStyle(color: Colors.grey.shade800)),
                                      ],
                                    ),
                                  ),
                                  ...['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((sev) {
                                    final color = _severityColor(sev);
                                    return DropdownMenuItem(
                                      value: sev,
                                      child: Row(
                                        children: [
                                          Icon(_severityIcon(sev), size: 16, color: color),
                                          const SizedBox(width: 8),
                                          Text(sev, style: TextStyle(color: color)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (v) => setState(() => selectedSeverity = v!),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Sort Dropdown
                        Container(
                          width: 120,
                          height: 45,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSort,
                              isExpanded: true,
                              icon: Icon(Icons.swap_vert_rounded, color: Colors.grey.shade600, size: 18),
                              items: [
                                DropdownMenuItem(
                                  value: "PRIORITY",
                                  child: Row(
                                    children: [
                                      Icon(Icons.priority_high, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text('Priority', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "NEWEST",
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text('Newest', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: "OLDEST",
                                  child: Row(
                                    children: [
                                      Icon(Icons.history, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text('Oldest', style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (v) => setState(() => selectedSort = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${filteredReports.length} active ${filteredReports.length == 1 ? 'report' : 'reports'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Reports List
          if (filteredReports.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final report = filteredReports[index];
                  final isEmergency = _isEmergency(report['category'] ?? '');

                  // Only apply animation if controller is valid
                  return _fadeController != null && _fadeAnimation != null
                      ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildReportCard(report, isEmergency),
                  )
                      : _buildReportCard(report, isEmergency);
                },
                childCount: filteredReports.length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  // Extract report card to a separate method for cleaner code
  Widget _buildReportCard(Map<String, dynamic> report, bool isEmergency) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: isEmergency ? 4 : 2,
        shadowColor: isEmergency
            ? Colors.red.withOpacity(0.2)
            : Colors.black.withOpacity(0.05),
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
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isEmergency
                  ? LinearGradient(
                colors: [
                  Colors.red.shade50,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              border: Border.all(
                color: isEmergency
                    ? Colors.red.shade200
                    : Colors.grey.shade200,
                width: isEmergency ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? Colors.red.shade50
                            : const Color(0xFFFFF4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEmergency ? Icons.warning : Icons.description_outlined,
                        size: 20,
                        color: isEmergency
                            ? Colors.red.shade600
                            : const Color(0xFFFF6B81),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Case #${report['case_id']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report['category'] ?? 'General',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSeverityBadge(report['severity'] ?? 'LOW'),
                  ],
                ),

                const SizedBox(height: 16),

                // Message preview
                if (report['report_text'] != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report['report_text'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSupportStatus(report['support_status'] ?? 'UNKNOWN'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDate((report['created_at'] ?? DateTime.now().toIso8601String()).toString()),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // View details button
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View full details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF6B81),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: const Color(0xFFFF6B81),
                      ),
                    ],
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