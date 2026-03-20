import 'dart:async';
import 'package:flutter/material.dart';

import '../auth/login/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Warehouse Receipts',
      'description':
      'Enables holders to deposit their commodity with a designated warehouse in exchange for a Warehouse Receipt.',
    },
    {
      'title': 'Spot Market Trading',
      'description':
      'ZMX provide an automated platform where commodities are traded for immediate delivery.',
    },
    {
      'title': 'Auction Results',
      'description':
      'Explore the power of simpler and beneficial results compiled by ZMX on a weekly basis.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Hero image section ─────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/splash.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // Dark gradient overlay — stronger at top & bottom
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                        stops: const [0.0, 0.25, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Logo at the top ──────────────────────────────────
                Positioned(
                  top: 52,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ── Scrollable text slides ───────────────────────────
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 160,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _slides[index]['title']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _slides[index]['description']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.88),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      height: 1.55,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Pagination dots ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                              (index) => Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildDot(isActive: index == _currentPage),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom section ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Get Started button
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black87, width: 2),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Get started',
                        style: TextStyle(
                          color: Color(0xFF2DB144),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '»',
                        style: TextStyle(
                          color: Color(0xFF2DB144),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Terms & Privacy
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'By clicking get started, you agree with our\n',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms & Privacy Policy.',
                        style: TextStyle(
                          color: Color(0xFF2DB144),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: isActive ? 28 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}