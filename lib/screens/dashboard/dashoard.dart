import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cash/cash.dart';
import 'home.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    CashContent(),
    _PlaceholderPage(icon: Icons.pie_chart_rounded, label: 'Portfolio'),
    _PlaceholderPage(icon: Icons.local_shipping_rounded, label: 'Deliveries'),
    _PlaceholderPage(icon: Icons.gavel_rounded, label: 'Auction'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        extendBody: true,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFAF6EE), Color(0xFFEDE4D0)],
                ),
              ),
            ),

            // All pages - IndexedStack keeps state alive
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedNavIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),

            // Glass bottom nav always on top
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGlassNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared Top Bar ────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.menu_rounded,
                color: Color(0xFF1A1A1A), size: 22),
          ),
          Image.asset('assets/images/logo.png',
              height: 38, fit: BoxFit.contain),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2DB144), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2DB144).withOpacity(0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                color: const Color(0xFF2DB144).withOpacity(0.15),
                child: const Icon(Icons.person_rounded,
                    color: Color(0xFF2DB144), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Glass Bottom Nav ──────────────────────────────────────────────────
  Widget _buildGlassNavBar() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Cash'},
      {'icon': Icons.pie_chart_rounded, 'label': 'Portfolio'},
      {'icon': Icons.local_shipping_rounded, 'label': 'Deliveries'},
      {'icon': Icons.gavel_rounded, 'label': 'Auction'},
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            border: Border(
              top: BorderSide(
                  color: Colors.white.withOpacity(0.5), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = _selectedNavIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD4A017)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFFD4A017).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF888888),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index]['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF888888),
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Placeholder for unbuilt tabs ──────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderPage({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF2DB144).withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Coming soon',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}