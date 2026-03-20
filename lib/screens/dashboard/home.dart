import 'dart:async';
import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  bool _isPrimaryMarket = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _commodities = [
    {'name': 'Sugar Beans', 'currency': 'USD', 'bid': '12.30', 'ask': '11.45', 'price': '12.32', 'change': '+5.05%', 'positive': true},
    {'name': 'Maize', 'currency': 'USD', 'bid': '8.10', 'ask': '7.90', 'price': '8.15', 'change': '+2.30%', 'positive': true},
    {'name': 'Millet', 'currency': 'USD', 'bid': '6.50', 'ask': '6.20', 'price': '6.55', 'change': '-1.20%', 'positive': false},
    {'name': 'Sugar Cane', 'currency': 'USD', 'bid': '4.80', 'ask': '4.60', 'price': '4.85', 'change': '+3.10%', 'positive': true},
    {'name': 'Wheat', 'currency': 'USD', 'bid': '9.40', 'ask': '9.10', 'price': '9.45', 'change': '+1.75%', 'positive': true},
    {'name': 'Soya Beans', 'currency': 'USD', 'bid': '15.20', 'ask': '14.80', 'price': '15.25', 'change': '-0.85%', 'positive': false},
    {'name': 'Cotton', 'currency': 'USD', 'bid': '7.30', 'ask': '7.00', 'price': '7.35', 'change': '+4.20%', 'positive': true},
    {'name': 'Tobacco', 'currency': 'USD', 'bid': '22.10', 'ask': '21.50', 'price': '22.15', 'change': '+6.50%', 'positive': true},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _switchMarket(bool isPrimary) {
    _fadeController.reset();
    setState(() => _isPrimaryMarket = isPrimary);
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          _buildGreetingCard(),
          const SizedBox(height: 20),
          _buildMarketToggle(),
          const SizedBox(height: 16),
          ..._commodities.map((c) => _buildCommodityCard(c)),
        ],
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14,
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  const Text('Username',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              _buildSunIcon(),
            ],
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallet Balance',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text('\$180.00',
                      style: TextStyle(
                          color: Color(0xFF2DB144),
                          fontSize: 34,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DB144).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2DB144).withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF2DB144), size: 16),
                    SizedBox(width: 6),
                    Text('Top Up',
                        style: TextStyle(
                            color: Color(0xFF2DB144),
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) =>
          Transform.rotate(angle: value * 0.5, child: child),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
              colors: [Color(0xFFFFD84D), Color(0xFFFFAA00)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFAA00).withOpacity(0.45),
                blurRadius: 16,
                spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.wb_sunny_rounded,
            color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildMarketToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _marketTab('Primary Market', true),
          _marketTab('Secondary Market', false),
        ],
      ),
    );
  }

  Widget _marketTab(String label, bool isPrimary) {
    final isSelected = _isPrimaryMarket == isPrimary;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMarket(isPrimary),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2DB144) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                  color: const Color(0xFF2DB144).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildCommodityCard(Map<String, dynamic> commodity) {
    final bool isPositive = commodity['positive'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(commodity['name'],
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text('Currency: ${commodity['currency']}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Bid: \$${commodity['bid']}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF444444))),
                const SizedBox(height: 3),
                Text('Best Ask: \$${commodity['ask']}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD4A017),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPositive
                    ? [const Color(0xFF2DB144), const Color(0xFF1E8E32)]
                    : [const Color(0xFFE53935), const Color(0xFFC62828)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: (isPositive
                        ? const Color(0xFF2DB144)
                        : const Color(0xFFE53935))
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Text('ZiG ${commodity['price']}/kg',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(commodity['change'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}