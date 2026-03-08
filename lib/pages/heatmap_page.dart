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

  Zone(this.id, this.x, this.y, this.width, this.height);
}

class HeatmapPage extends StatefulWidget {
  const HeatmapPage({super.key});

  @override
  State<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends State<HeatmapPage> {
  bool loading = true;
  List<HeatmapReport> reports = [];
  String? selectedZone;
  String? hoveredZone;
  Offset? hoverPosition;
  String selectedDateFilter = "ALL";
  String selectedSeverity = "ALL";
  String selectedCategory = "ALL";

  final List<Zone> zones = [

    Zone("sevens_ground",351.61,369.74,182.78,166.03),
    Zone("football_ground",1012.97,532.99,101.85,199.52),
    Zone("bus_garage",210.68,619.50,188.36,99.06),
    Zone("parking_space",322.31,90.69,121.38,103.25),
    Zone("bio_park",459.04,168.82,129.76,89.29),

    Zone("basketball_court2",909.72,592.99,96.27,136.73),
    Zone("basketball_court1",400.44,248.36,138.13,85.11),
    Zone("badminton_court",253.94,311.14,79.53,94.87),
    Zone("canteen",792.51,619.50,113.01,97.66),
    Zone("workshop",223.24,485.55,121.38,80.92),

    Zone("ad_block",573.46,269.28,182.78,133.94),
    Zone("cs_block",1029.71,135.34,90.69,97.66),
    Zone("new_block",898.56,113.01,87.90,55.81),
    Zone("library",830.19,171.61,73.94,43.25),
    Zone("reprographic_centre",916.70,196.73,69.76,39.06),

    Zone("zulu_hostel",295.79,1.39,82.32,53.02),
    Zone("mens_hostel",623.69,110.22,101.85,46.04),
    Zone("mens_hostel1",245.56,128.36,62.78,80.92),
    Zone("shahanas_hostel",980.88,439.51,89.29,73.94),

    Zone("mech_block",639.03,644.62,103.25,90.69),
    Zone("fab_lab",548.34,654.38,76.74,72.55),
    Zone("eee_block",439.51,629.27,93.48,94.87),
    Zone("civil_block",113.01,636.24,80.92,85.11),
    Zone("l_block",22.32,587.41,75.34,107.43),
    Zone("ec_block",55.81,449.28,92.08,79.53),

    Zone("union_corner",517.64,319.51,48.83,75.34),
    Zone("cooperative_society",651.59,410.21,147.89,57.20),
    Zone("electric_control_room",745.08,175.80,62.78,39.06),
    Zone("main_entrance",466.02,59.99,103.25,39.06),
    Zone("auditorium",85.11,189.75,72.55,59.99),

  ];

  @override
  void initState() {
    super.initState();
    fetchHeatmapReports();
  }

  Future<void> fetchHeatmapReports() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://safespace-backend-z4d6.onrender.com/admin/heatmap-reports",
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
    return "${date.day}/${date.month}/${date.year}";
  }
  void showReportSummary() {

    List<HeatmapReport> filtered = reports.where((r) {

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
          if (now.difference(r.createdAt).inDays > 7) {
            return false;
          }
        }

        if (selectedDateFilter == "30DAYS") {
          if (now.difference(r.createdAt).inDays > 30) {
            return false;
          }
        }
      }

      return true;

    }).toList();

    final zoneReports =
    filtered.where((r) => r.location == selectedZone).toList();

    Map<String, int> categoryCount = {};
    Map<String, int> severityCount = {};

    for (var r in zoneReports) {
      categoryCount[r.category] = (categoryCount[r.category] ?? 0) + 1;
      severityCount[r.severity] = (severityCount[r.severity] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            selectedZone!.replaceAll("_", " ").toUpperCase(),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text("Reports: ${zoneReports.length}"),

                const SizedBox(height: 10),

                const Text(
                  "By Category",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                ...categoryCount.entries.map(
                      (e) => Text("${e.key}: ${e.value}"),
                ),

                const SizedBox(height: 10),

                const Text(
                  "By Severity",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                ...severityCount.entries.map(
                      (e) => Text("${e.key}: ${e.value}"),
                ),

              ],
            ),
          ),
        );
      },
    );
  }
  Color getSeverityColor(String severity) {
    switch (severity) {
      case "LOW":
        return Colors.green;
      case "MEDIUM":
        return Colors.yellow;
      case "HIGH":
        return Colors.orange;
      case "CRITICAL":
        return Colors.red;
      default:
        return Colors.white;
    }
  }
  @override
  Widget build(BuildContext context) {
    List<HeatmapReport> filteredReports = reports.where((r) {

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
          if (now.difference(r.createdAt).inDays > 7) {
            return false;
          }
        }

        if (selectedDateFilter == "30DAYS") {
          if (now.difference(r.createdAt).inDays > 30) {
            return false;
          }
        }
      }

      return true;

    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Heatmap"),
      ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
              children: [

                DropdownButton<String>(
                  value: selectedDateFilter,
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

                DropdownButton<String>(
                  value: selectedSeverity,
                  items: const [
                    DropdownMenuItem(value: "ALL", child: Text("All Severity")),
                    DropdownMenuItem(value: "LOW", child: Text("LOW")),
                    DropdownMenuItem(value: "MEDIUM", child: Text("MEDIUM")),
                    DropdownMenuItem(value: "HIGH", child: Text("HIGH")),
                    DropdownMenuItem(value: "CRITICAL", child: Text("CRITICAL")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedSeverity = v!;
                    });
                  },
                ),

                DropdownButton<String>(
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(value: "ALL", child: Text("All Category")),
                    DropdownMenuItem(value: "Emergency", child: Text("Emergency")),
                    DropdownMenuItem(value: "Mental Stress", child: Text("Mental Stress")),
                    DropdownMenuItem(value: "College Safety", child: Text("College Safety")),
                    DropdownMenuItem(value: "Ragging and Bullying", child: Text("Ragging")),
                    DropdownMenuItem(value: "Abuse and Harassment", child: Text("Abuse and Harassment")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedCategory = v!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
          AspectRatio(
            aspectRatio: 1118 / 737,
            child: LayoutBuilder(
              builder: (context, constraints) {

                final mapWidth = constraints.maxWidth;
                final mapHeight = constraints.maxHeight;

                return Stack(
                  children: [

                    SvgPicture.asset(
                      'assets/map/lbs.svg',
                      width: mapWidth,
                      height: mapHeight,
                      fit: BoxFit.contain,
                    ),

                    ...filteredReports.map((report) {

                      final zone = zones.firstWhere(
                            (z) => z.id == report.location,
                        orElse: () => Zone("",0,0,0,0),
                      );

                      if (zone.id == "") return const SizedBox();

                      double left = zone.x / 1118 * mapWidth;
                      double top = zone.y / 737 * mapHeight;
                      double width = zone.width / 1118 * mapWidth;
                      double height = zone.height / 737 * mapHeight;

                      double x = left + width / 2 + (report.caseId.hashCode % 14 - 7);
                      double y = top + height / 2 + (report.caseId.hashCode % 14 - 7);

                      return Positioned(
                        left: x - 4,
                        top: y - 4,
                        child: IgnorePointer(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: getSeverityColor(report.severity),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );

                    }).toList(),

                    ...zones.map((zone) {

                      double left = zone.x / 1118 * mapWidth;
                      double top = zone.y / 737 * mapHeight;
                      double width = zone.width / 1118 * mapWidth;
                      double height = zone.height / 737 * mapHeight;

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
                                selectedZone = zone.id;
                              });
                            },
                            child: Container(
                              width: width,
                              height: height,
                              color: Colors.transparent,
                            ),
                          ),
                        ),
                      );

                    }).toList(),
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

                          int total = zoneReports.length;

                          int categoryCount = zoneReports
                              .where((r) => r.category == selectedCategory)
                              .length;

                          int severityCount = zoneReports
                              .where((r) => r.severity == selectedSeverity)
                              .length;

                          return Positioned(
                            left: tooltipX,
                            top: tooltipY,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    hoveredZone!.replaceAll("_", " ").toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),

                                  if (total > 0)
                                    Text(
                                      "Reports: $total",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),

                                  if (total > 0 &&
                                      selectedCategory != "ALL" &&
                                      selectedSeverity == "ALL")
                                    Text(
                                      "$selectedCategory: $categoryCount",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),

                                  if (total > 0 &&
                                      selectedSeverity != "ALL" &&
                                      selectedCategory == "ALL")
                                    Text(
                                      "$selectedSeverity: $severityCount",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
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
        if (selectedZone != null)
               Column(
                children: [

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          "${selectedZone!.replaceAll("_", " ").toUpperCase()} "
                              "(${filteredReports.where((r) => r.location == selectedZone).length} cases)",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 10),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 30),
                          ),
                          onPressed: () {
                            showReportSummary();
                          },
                          child: const Text(
                            "View Reports",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),

                      ],
                    ),
                  ),

    ListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: filteredReports
                          .where((r) => r.location == selectedZone)
        .map((r) => InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminReportDetailPage(
              caseId: r.caseId,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                r.caseId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(r.reportText),

              const SizedBox(height: 8),

              Row(
                children: [

                  Text(
                    r.category,
                    style: const TextStyle(fontSize: 12),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    r.severity,
                    style: const TextStyle(fontSize: 12),
                  ),

                  const Spacer(),

                  Text(
                    formatDate(r.createdAt),
                    style: const TextStyle(fontSize: 12),
                  ),

                ],
              )

            ],
          ),
        ),
      ),
    ))
        .toList(),
                    ),
                ],
              ),

        ],
      ),
        ),
    );
  }
}