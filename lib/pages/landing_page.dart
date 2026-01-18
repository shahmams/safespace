import 'package:flutter/material.dart';
import 'write_page.dart';
import 'admin_login_page.dart';
import 'reports_overview_page.dart';
import 'package:safespacee/utils/anon_id_storage.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool hasAnon = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkAnon();
  }

  Future<void> _checkAnon() async {
    final anonId = await AnonIdStorage.getOrCreateAnonId();
    if (!mounted) return;

    setState(() {
      hasAnon = anonId.isNotEmpty;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Changed to white like Admin page

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // HERO CARD - Updated to pink theme
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFFFF4F6), // Light pink background
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B81).withOpacity(0.15), // Pink shadow
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // APP ICON - Updated to pink gradient
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF6B81), // Pink
                              Color(0xFFFF8E9E), // Lighter pink
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B81).withOpacity(0.35), // Pink shadow
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'SafeSpace',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2B2B2B), // Darker text like Admin page
                          letterSpacing: -0.8,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Your safe place to speak freely\nwithout fear or judgement',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF7A7A7A), // Gray text like Admin page
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (hasAnon) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B81).withOpacity(0.1), // Pink background
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Color(0xFFFF6B81), // Pink icon
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Welcome back',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFFFF6B81), // Pink text
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // PRIMARY CTA - Updated to pink
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B81).withOpacity(0.35), // Pink shadow
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (hasAnon) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsOverviewPage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WritePage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B81), // Pink button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasAnon
                              ? Icons.insights_outlined
                              : Icons.edit_outlined,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          hasAnon ? 'Continue your journey' : 'Start your journey',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // DIVIDER
                SizedBox(
                  width: 380,
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ADMIN BUTTON - Updated to pink theme
                Container(
                  width: 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFFF6B81).withOpacity(0.3), // Pink border
                      width: 1.5,
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminLoginPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF6B81), // Pink text/icon
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 22,
                          color: Color(0xFFFF6B81), // Pink icon
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Admin / Counsellor Login',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFFFF6B81), // Pink text
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // TRUST FOOTER - Updated colors
                Container(
                  width: 380,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F6), // Light pink background
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 28,
                        children: [
                          Icon(Icons.lock_outline, size: 20, color: Color(0xFFFF6B81)), // Pink icons
                          Icon(Icons.verified_outlined, size: 20, color: Color(0xFFFF6B81)),
                          Icon(Icons.security_outlined, size: 20, color: Color(0xFFFF6B81)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Anonymous • Secure • Confidential',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF6B81).withOpacity(0.8), // Pink text
                          fontWeight: FontWeight.w500,
                        ),
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