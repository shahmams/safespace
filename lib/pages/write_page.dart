import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'reports_overview_page.dart';
import 'package:safespacee/utils/anon_id_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Zone {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;

  Zone(this.id, this.x, this.y, this.width, this.height);
}
class WritePage extends StatefulWidget {
  const WritePage({super.key});

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> {
  bool wantCounsellor = false;
  bool isLoading = false;
  String? selectedLocation;
  double? labelX;
  double? labelY;
  bool showMap = false;
  final TextEditingController reportController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final List<Zone> zones = [

    // VERY LARGE AREAS FIRST
    Zone("sevens_ground",351.61,369.74,182.78,166.03),
    Zone("football_ground",1012.97,532.99,101.85,199.52),
    Zone("bus_garage",210.68,619.50,188.36,99.06),
    Zone("parking_space",322.31,90.69,121.38,103.25),
    Zone("bio_park",459.04,168.82,129.76,89.29),

    // MEDIUM AREAS
    Zone("basketball_court2",909.72,592.99,96.27,136.73),
    Zone("basketball_court1",400.44,248.36,138.13,85.11),
    Zone("badminton_court",253.94,311.14,79.53,94.87),
    Zone("canteen",792.51,619.50,113.01,97.66),
    Zone("workshop",223.24,485.55,121.38,80.92),

    // BUILDINGS
    Zone("ad_block",573.46,269.28,182.78,133.94),
    Zone("cs_block",1029.71,135.34,90.69,97.66),
    Zone("new_block",898.56,113.01,87.90,55.81),
    Zone("library",830.19,171.61,73.94,43.25),
    Zone("reprographic_centre",916.70,196.73,69.76,39.06),

    // HOSTELS
    Zone("zulu_hostel",295.79,1.39,82.32,53.02),
    Zone("mens_hostel",623.69,110.22,101.85,46.04),
    Zone("mens_hostel1",245.56,128.36,62.78,80.92),
    Zone("shahanas_hostel",980.88,439.51,89.29,73.94),

    // BLOCKS
    Zone("mech_block",639.03,644.62,103.25,90.69),
    Zone("fab_lab",548.34,654.38,76.74,72.55),
    Zone("eee_block",439.51,629.27,93.48,94.87),
    Zone("civil_block",113.01,636.24,80.92,85.11),
    Zone("l_block",22.32,587.41,75.34,107.43),
    Zone("ec_block",55.81,449.28,92.08,79.53),

    // SMALL AREAS LAST (TOP LAYER)
    Zone("union_corner",517.64,319.51,48.83,75.34),
    Zone("cooperative_society",651.59,410.21,147.89,57.20),
    Zone("electric_control_room",745.08,175.80,62.78,39.06),
    Zone("main_entrance",466.02,59.99,103.25,39.06),
    Zone("auditorium",85.11,189.75,72.55,59.99),

  ];
  void selectZone(String zone) {
    setState(() {
      selectedLocation = zone;
    });
  }
  @override
  void dispose() {
    reportController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> submitReport() async {
    if (reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write something before submitting'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (reportController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please write a bit more details (minimum 10 characters)'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Get or create anon_id
      final anonId = await AnonIdStorage.getOrCreateAnonId();

      // Send report to backend
      final response = await http.post(
        Uri.parse(
          'https://safespace-backend-z4d6.onrender.com/report',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'anon_id': anonId,
          'report_text': reportController.text.trim(),
          'support_requested': wantCounsellor,
          'location_zone': selectedLocation,
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final caseId = data['case_id'];

        // Success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 32,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Report Submitted!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your case reference ID:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B81).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      caseId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF6B81),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your report has been saved securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A7A),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        reportController.clear();
                        wantCounsellor = false;
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsOverviewPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B81),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View My Reports',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Submission failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
        title: const Text(
          "Write Your Report",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF6B81).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B81),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'SafeSpace',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B2B2B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This is your safe place to speak freely. Write as much or as little as you want. Everything you share is confidential and anonymous.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7A7A7A),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Text Input Section
            const Text(
              'Your Thoughts',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share what\'s on your mind',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: reportController,
                focusNode: _textFocusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Start typing here...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2B2B2B),
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${reportController.text.length} characters',
                  style: TextStyle(
                    fontSize: 12,
                    color: reportController.text.length < 10
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
// ---------------- MAP PREVIEW ----------------

            const Text(
              'Campus Location (Optional)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  showMap = !showMap;
                });
              },
              icon: const Icon(Icons.map),
              label: Text(showMap ? "Hide Map" : "Select Location on Map"),
            ),

            const SizedBox(height: 12),

            Text(
              'Select location from campus map if relevant',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 12),

            if (showMap)
              LayoutBuilder(
                builder: (context, constraints) {

                double mapWidth = constraints.maxWidth;
                double mapHeight = mapWidth * (737 / 1118);

                return SizedBox(
                  height: mapHeight,
                  child: Stack(
                    children: [

                      SvgPicture.asset(
                        'assets/map/lbs.svg',
                        width: mapWidth,
                        height: mapHeight,
                        fit: BoxFit.fill,
                      ),

                      ...zones.map((zone) {

                        double left = zone.x / 1118 * mapWidth;
                        double top = zone.y / 737 * mapHeight;
                        double width = zone.width / 1118 * mapWidth;
                        double height = zone.height / 737 * mapHeight;

                        return Positioned(
                          left: left,
                          top: top,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLocation = zone.id;

                                labelX = left + width / 2;
                                labelY = top - 30;
                              });
                            },
                            child: Container(
                              width: width,
                              height: height,
                              color: selectedLocation == zone.id
                                  ? Colors.red.withOpacity(0.35)
                                  : Colors.transparent,
                            ),
                          ),
                        );

                      }).toList(),
                      if (selectedLocation != null && labelX != null && labelY != null)
                        Positioned(
                          left: labelX! - 50,
                          top: labelY!,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selectedLocation!.replaceAll("_", " ").toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            if (selectedLocation != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Color(0xFFFF6B81),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      selectedLocation!.replaceAll("_", " ").toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 10),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLocation = null;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),


            const SizedBox(height: 24),
            // Counsellor Section
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 22,
                            color: wantCounsellor
                                ? const Color(0xFFFF6B81)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Connect with a Counsellor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: wantCounsellor,
                          onChanged: (value) {
                            setState(() {
                              wantCounsellor = value;
                            });
                          },
                          activeColor: const Color(0xFFFF6B81),
                          activeTrackColor: const Color(0xFFFF6B81).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Text(
                      wantCounsellor
                          ? 'A counsellor will review your report and reach out to provide support.'
                          : 'You can always request counselling later from your report details.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Privacy Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F6).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: const Color(0xFFFF6B81),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your identity is protected. All reports are completely anonymous and secure.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B81),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: const Color(0xFFFF6B81).withOpacity(0.3),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}