import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import 'admin_report_detail_page.dart';

class HeatmapReport {
  final String caseId;
  final String location;
  final String category;
  final String severity;
  final String reportText;
  final String caseStatus;
  final DateTime createdAt;

  HeatmapReport({
    required this.caseId,
    required this.location,
    required this.category,
    required this.severity,
    required this.reportText,
    required this.caseStatus,
    required this.createdAt,
  });

  factory HeatmapReport.fromJson(Map<String, dynamic> json) {
    return HeatmapReport(
      caseId: json['case_id'],
      location: json['location'],
      category: json['category'],
      severity: json['severity'],
      reportText: json['report_text'],
      caseStatus: json['case_status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Zone {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;
  final String displayName;

  Zone(this.id, this.x, this.y, this.width, this.height)
      : displayName = id.replaceAll("_", " ").toUpperCase();
}

class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});

  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> with SingleTickerProviderStateMixin {
  bool loading = true;
  List<HeatmapReport> reports = [];
  String? selectedZone;
  String? hoveredZone;
  Offset? hoverPosition;

  // Filter states
  String selectedDateFilter = "ALL";
  String selectedSeverity = "ALL";
  String selectedCategory = "ALL";

  // Animation for selected zone
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Zone> zones = [
    Zone("sevens_ground", 351.61, 369.74, 182.78, 166.03),
    Zone("football_ground", 1012.97, 532.99, 101.85, 199.52),
    Zone("bus_garage", 210.68, 619.50, 188.36, 99.06),
    Zone("parking_space", 322.31, 90.69, 121.38, 103.25),
    Zone("bio_park", 459.04, 168.82, 129.76, 89.29),
    Zone("basketball_court2", 909.72, 592.99, 96.27, 136.73),
    Zone("basketball_court1", 400.44, 248.36, 138.13, 85.11),
    Zone("badminton_court", 253.94, 311.14, 79.53, 94.87),
    Zone("canteen", 792.51, 619.50, 113.01, 97.66),
    Zone("workshop", 223.24, 485.55, 121.38, 80.92),
    Zone("ad_block", 573.46, 269.28, 182.78, 133.94),
    Zone("cs_block", 1029.71, 135.34, 90.69, 97.66),
    Zone("new_block", 898.56, 113.01, 87.90, 55.81),
    Zone("library", 830.19, 171.61, 73.94, 43.25),
    Zone("reprographic_centre", 916.70, 196.73, 69.76, 39.06),
    Zone("zulu_hostel", 295.79, 1.39, 82.32, 53.02),
    Zone("mens_hostel", 623.69, 110.22, 101.85, 46.04),
    Zone("mens_hostel1", 245.56, 128.36, 62.78, 80.92),
    Zone("shahanas_hostel", 980.88, 439.51, 89.29, 73.94),
    Zone("mech_block", 639.03, 644.62, 103.25, 90.69),
    Zone("fab_lab", 548.34, 654.38, 76.74, 72.55),
    Zone("eee_block", 439.51, 629.27, 93.48, 94.87),
    Zone("civil_block", 113.01, 636.24, 80.92, 85.11),
    Zone("l_block", 22.32, 587.41, 75.34, 107.43),
    Zone("ec_block", 55.81, 449.28, 92.08, 79.53),
    Zone("union_corner", 517.64, 319.51, 48.83, 75.34),
    Zone("cooperative_society", 651.59, 410.21, 147.89, 57.20),
    Zone("electric_control_room", 745.08, 175.80, 62.78, 39.06),
    Zone("main_entrance", 466.02, 59.99, 103.25, 39.06),
    Zone("auditorium", 85.11, 189.75, 72.55, 59.99),
  ];

  @override
  void initState() {
    super.initState();
    fetchHeatmapReports();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchHeatmapReports() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://safespace-jauf.onrender.com/admin/heatmap-reports",
        ),
      );

      final data = jsonDecode(response.body);
      List list = data['reports'];

      setState(() {
        reports = list.map((e) => HeatmapReport.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      print("Heatmap fetch error: $e");
      setState(() {
        loading = false;
      });
    }
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void showReportSummary() {
    List<HeatmapReport> filtered = _getFilteredReports();
    final zoneReports = filtered.where((r) => r.location == selectedZone).toList();

    Map<String, int> categoryCount = {};
    Map<String, int> severityCount = {};

    for (var r in zoneReports) {
      categoryCount[r.category] = (categoryCount[r.category] ?? 0) + 1;
      severityCount[r.severity] = (severityCount[r.severity] ?? 0) + 1;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                selectedZone!.replaceAll("_", " ").toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${zoneReports.length} reports in this area',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),

              _buildSummaryCard(
                title: 'By Category',
                data: categoryCount,
                colorBuilder: (key) => _getCategoryColor(key),
              ),

              const SizedBox(height: 16),

              _buildSummaryCard(
                title: 'By Severity',
                data: severityCount,
                colorBuilder: (key) => getSeverityColor(key),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B81),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Map<String, int> data,
    required Color Function(String) colorBuilder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...data.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorBuilder(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Text(
                  e.value.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' (${((e.value / data.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Emergency':
        return Colors.red.shade400;
      case 'Mental Stress':
        return Colors.purple.shade400;
      case 'College Safety':
        return Colors.blue.shade400;
      case 'Ragging and Bullying':
        return Colors.orange.shade400;
      case 'Abuse and Harassment':
        return Colors.pink.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  Color getSeverityColor(String severity) {
    switch (severity) {
      case "LOW":
        return Colors.green.shade400;
      case "MEDIUM":
        return Colors.amber.shade600;
      case "HIGH":
        return Colors.orange.shade600;
      case "CRITICAL":
        return Colors.red.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  List<HeatmapReport> _getFilteredReports() {
    return reports.where((r) {
      if (selectedSeverity != "ALL" && r.severity != selectedSeverity) {
        return false;
      }
      if (selectedCategory != "ALL" && r.category != selectedCategory) {
        return false;
      }
      if (selectedDateFilter != "ALL") {
        DateTime now = DateTime.now();
        if (selectedDateFilter == "TODAY") {
          if (r.createdAt.day != now.day ||
              r.createdAt.month != now.month ||
              r.createdAt.year != now.year) {
            return false;
          }
        }
        if (selectedDateFilter == "7DAYS") {
          if (now.difference(r.createdAt).inDays > 7) return false;
        }
        if (selectedDateFilter == "30DAYS") {
          if (now.difference(r.createdAt).inDays > 30) return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required String label,
    IconData? icon,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
          items: items,
          onChanged: onChanged,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          hint: Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: Colors.grey.shade600),
              if (icon != null) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
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
    List<HeatmapReport> filteredReports = _getFilteredReports();
    final filteredCount = filteredReports.length;
    final totalReports = reports.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Campus Heatmap",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: loading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF6B81)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading heatmap data...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            // Filter Bar with Dropdowns
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$filteredCount of $totalReports reports',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFFFF6B81),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Row
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                        // Date Filter Dropdown
                            SizedBox(
                              width: 120,
                              child: _buildDropdown<String>(
                            value: selectedDateFilter,
                            icon: Icons.calendar_today,
                            label: 'Date Range',
                            items: const [
                              DropdownMenuItem(value: "ALL", child: Text("All Dates")),
                              DropdownMenuItem(value: "TODAY", child: Text("Today")),
                              DropdownMenuItem(value: "7DAYS", child: Text("Last 7 Days")),
                              DropdownMenuItem(value: "30DAYS", child: Text("Last 30 Days")),
                            ],
                            onChanged: (v) {
                              setState(() {
                                selectedDateFilter = v!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Severity Filter Dropdown
                            SizedBox(
                              width: 135,
                              child: _buildDropdown<String>(
                            value: selectedSeverity,
                            icon: Icons.warning,
                            label: 'Severity',
                            items: [
                              const DropdownMenuItem(value: "ALL", child: Text("All Severity")),
                              ...['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((sev) {
                                return DropdownMenuItem(
                                  value: sev,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: getSeverityColor(sev),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          sev,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (v) {
                              setState(() {
                                selectedSeverity = v!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Category Filter Dropdown
                            SizedBox(
                              width: 170,
                          child: _buildDropdown<String>(
                            value: selectedCategory,
                            icon: Icons.category,
                            label: 'Category',
                            items: [
                              const DropdownMenuItem(value: "ALL", child: Text("All Categories")),
                              DropdownMenuItem(
                                value: "Emergency",
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor("Emergency"),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Emergency",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "Mental Stress",
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor("Mental Stress"),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Mental Stress",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "College Safety",
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor("College Safety"),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "College Safety",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "Ragging and Bullying",
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor("Ragging and Bullying"),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Ragging and Bullying",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: "Abuse and Harassment",
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor("Abuse and Harassment"),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Abuse and Harassment",
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                selectedCategory = v!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),

                  // Clear Filters Button
                  if (selectedCategory != "ALL" || selectedSeverity != "ALL" || selectedDateFilter != "ALL")
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = "ALL";
                                selectedSeverity = "ALL";
                                selectedDateFilter = "ALL";
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Clear all filters',
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
                ],
              ),
            ),

            // Heatmap
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1118 / 737,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mapWidth = constraints.maxWidth;
                      final mapHeight = constraints.maxHeight;

                      return Stack(
                        children: [
                          // Base map
                          SvgPicture.asset(
                            'assets/map/lbs.svg',
                            width: mapWidth,
                            height: mapHeight,
                            fit: BoxFit.contain,
                          ),

                          // Report dots
                          ...filteredReports.map((report) {
                            final zone = zones.firstWhere(
                                  (z) => z.id == report.location,
                              orElse: () => Zone("", 0, 0, 0, 0),
                            );

                            if (zone.id == "") return const SizedBox();

                            double left = zone.x / 1118 * mapWidth;
                            double top = zone.y / 737 * mapHeight;
                            double width = zone.width / 1118 * mapWidth;
                            double height = zone.height / 737 * mapHeight;

                            // Add slight random offset to prevent overlapping
                            double x = left + width / 2 + (report.caseId.hashCode % 14 - 7);
                            double y = top + height / 2 + (report.caseId.hashCode % 14 - 7);

                            return Positioned(
                              left: x - 6,
                              top: y - 6,
                              child: IgnorePointer(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: getSeverityColor(report.severity),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: getSeverityColor(report.severity).withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          // Zone touch areas
                          ...zones.map((zone) {
                            double left = zone.x / 1118 * mapWidth;
                            double top = zone.y / 737 * mapHeight;
                            double width = zone.width / 1118 * mapWidth;
                            double height = zone.height / 737 * mapHeight;

                            final zoneReports = filteredReports
                                .where((r) => r.location == zone.id)
                                .toList();

                            final hasReports = zoneReports.isNotEmpty;
                            final isSelected = selectedZone == zone.id;

                            return Positioned(
                              left: left,
                              top: top,
                              child: MouseRegion(
                                onHover: (event) {
                                  setState(() {
                                    hoveredZone = zone.id;
                                    hoverPosition = event.localPosition;
                                  });
                                },
                                onExit: (_) {
                                  setState(() {
                                    hoveredZone = null;
                                    hoverPosition = null;
                                  });
                                },
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (selectedZone == zone.id) {
                                        selectedZone = null;
                                        _animationController.reverse();
                                      } else {
                                        selectedZone = zone.id;
                                        _animationController.forward();
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: width,
                                    height: height,
                                    decoration: hasReports
                                        ? BoxDecoration(
                                      border: isSelected
                                          ? Border.all(
                                        color: const Color(0xFFFF6B81),
                                        width: 2,
                                      )
                                          : Border.all(
                                        color: Colors.grey.shade400.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          // Tooltip on hover
                          if (hoveredZone != null)
                            Builder(
                              builder: (context) {
                                final zone = zones.firstWhere(
                                      (z) => z.id == hoveredZone,
                                  orElse: () => Zone("", 0, 0, 0, 0),
                                );

                                double left = zone.x / 1118 * mapWidth;
                                double top = zone.y / 737 * mapHeight;
                                double width = zone.width / 1118 * mapWidth;
                                double height = zone.height / 737 * mapHeight;

                                double tooltipX = left + width / 2;
                                double tooltipY = top - 40;

                                final zoneReports = filteredReports
                                    .where((r) => r.location == hoveredZone)
                                    .toList();

                                return Positioned(
                                  left: tooltipX - 75,
                                  top: tooltipY,
                                  child: Container(
                                    width: 150,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          zone.displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        if (zoneReports.isNotEmpty) ...[
                                          Text(
                                            "Reports: ${zoneReports.length}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (selectedSeverity != "ALL")
                                            Text(
                                              "$selectedSeverity: ${zoneReports.where((r) => r.severity == selectedSeverity).length}",
                                              style: TextStyle(
                                                color: getSeverityColor(selectedSeverity).withOpacity(0.9),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ] else
                                          const Text(
                                            "No reports",
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Selected zone details
            if (selectedZone != null)
              FadeTransition(
                opacity: _animation,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    zones.firstWhere((z) => z.id == selectedZone).displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${filteredReports.where((r) => r.location == selectedZone).length} reports',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4F6),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Color(0xFFFF6B81),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedZone = null;
                                    _animationController.reverse();
                                  });
                                },
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Reports list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredReports
                            .where((r) => r.location == selectedZone)
                            .length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final report = filteredReports
                              .where((r) => r.location == selectedZone)
                              .toList()[index];

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminReportDetailPage(
                                    caseId: report.caseId,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: getSeverityColor(report.severity).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: getSeverityColor(report.severity),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              report.severity,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: getSeverityColor(report.severity),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          report.caseId,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    report.reportText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(report.category).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          report.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getCategoryColor(report.category),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        formatDate(report.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // View summary button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: showReportSummary,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF6B81),
                              side: const BorderSide(color: Color(0xFFFF6B81)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('View Summary Report'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}