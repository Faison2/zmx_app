import 'package:flutter/material.dart';

import '../profile/profile.dart';


class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png',
                        height: 40, fit: BoxFit.contain),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── User info ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push( // 👈 changed
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: const Color(0xFFD4A017).withOpacity(0.3),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF2DB144), width: 2),
                          ),
                          child: ClipOval(
                            child: Container(
                              color: const Color(0xFF2DB144).withOpacity(0.2),
                              child: const Icon(Icons.person_rounded,
                                  color: Color(0xFF2DB144), size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tafadzwa Moyo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '0/535411',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFFD4A017), size: 14),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                    color: Colors.white.withOpacity(0.1), height: 1),
              ),
              const SizedBox(height: 12),

              // ── Nav items ──────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  children: [
                    _drawerItem(context, icon: Icons.home_rounded, label: 'Home', index: 0),
                    _drawerItem(context, icon: Icons.account_balance_wallet_rounded, label: 'Cash', index: 1),
                    _drawerItem(context, icon: Icons.pie_chart_rounded, label: 'Portfolio', index: 2),
                    _drawerItem(context, icon: Icons.local_shipping_rounded, label: 'Deliveries', index: 3),
                    _drawerItem(context, icon: Icons.gavel_rounded, label: 'Auction', index: 4),

                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    const SizedBox(height: 12),

                    // Profile link
                    _drawerAction(
                      context,
                      icon: Icons.person_rounded,
                      label: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push( // 👈 changed
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    _drawerAction(
                      context,
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      onTap: () => Navigator.pop(context),
                    ),
                    _drawerAction(
                      context,
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // ── Logout ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil( // 👈 changed
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPlaceholder()),
                          (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.3), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.redAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required IconData icon,
        required String label,
        required int index}) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onNavTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4A017).withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(
              color: const Color(0xFFD4A017).withOpacity(0.4), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFFD4A017)
                    : Colors.white.withOpacity(0.55),
                size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFD4A017)
                    : Colors.white.withOpacity(0.75),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A017),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _drawerAction(BuildContext context,
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.55), size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary placeholder — replace with your actual LoginScreen import
class LoginPlaceholder extends StatelessWidget {
  const LoginPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Login Screen')),
  );
}