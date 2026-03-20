import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  bool _isPrimaryMarket = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _primaryCommodities = [
    {'name': 'Sugar Beans', 'currency': 'USD', 'bid': '12.30', 'ask': '11.45', 'price': '12.32', 'change': '+5.05%', 'positive': true},
    {'name': 'Maize', 'currency': 'USD', 'bid': '8.10', 'ask': '7.90', 'price': '8.15', 'change': '+2.30%', 'positive': true},
    {'name': 'Millet', 'currency': 'USD', 'bid': '6.50', 'ask': '6.20', 'price': '6.55', 'change': '-1.20%', 'positive': false},
    {'name': 'Sugar Cane', 'currency': 'USD', 'bid': '4.80', 'ask': '4.60', 'price': '4.85', 'change': '+3.10%', 'positive': true},
    {'name': 'Wheat', 'currency': 'USD', 'bid': '9.40', 'ask': '9.10', 'price': '9.45', 'change': '+1.75%', 'positive': true},
    {'name': 'Soya Beans', 'currency': 'USD', 'bid': '15.20', 'ask': '14.80', 'price': '15.25', 'change': '-0.85%', 'positive': false},
    {'name': 'Cotton', 'currency': 'USD', 'bid': '7.30', 'ask': '7.00', 'price': '7.35', 'change': '+4.20%', 'positive': true},
    {'name': 'Tobacco', 'currency': 'USD', 'bid': '22.10', 'ask': '21.50', 'price': '22.15', 'change': '+6.50%', 'positive': true},
  ];

  final List<Map<String, dynamic>> _secondaryCommodities = [
    {'name': 'Red Sorghum', 'currency': 'ZiG', 'bid': '5.20', 'ask': '4.90', 'price': '5.25', 'change': '+1.80%', 'positive': true},
    {'name': 'Groundnuts', 'currency': 'ZiG', 'bid': '18.40', 'ask': '17.80', 'price': '18.50', 'change': '-2.10%', 'positive': false},
    {'name': 'Sunflower', 'currency': 'ZiG', 'bid': '11.60', 'ask': '11.20', 'price': '11.65', 'change': '+3.40%', 'positive': true},
    {'name': 'Barley', 'currency': 'ZiG', 'bid': '7.80', 'ask': '7.50', 'price': '7.85', 'change': '+0.90%', 'positive': true},
    {'name': 'Cowpeas', 'currency': 'ZiG', 'bid': '9.10', 'ask': '8.80', 'price': '9.15', 'change': '-1.50%', 'positive': false},
    {'name': 'Sesame', 'currency': 'ZiG', 'bid': '24.30', 'ask': '23.80', 'price': '24.40', 'change': '+4.70%', 'positive': true},
  ];

  List<Map<String, dynamic>> get _currentCommodities =>
      _isPrimaryMarket ? _primaryCommodities : _secondaryCommodities;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _switchMarket(bool isPrimary) {
    if (_isPrimaryMarket == isPrimary) return;
    _fadeController.reset();
    setState(() => _isPrimaryMarket = isPrimary);
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        // ── These never fade ───────────────────────────────────────
        _buildGreetingCard(),
        const SizedBox(height: 16),
        _buildQuickStats(),
        const SizedBox(height: 16),
        _buildMarketToggle(),
        const SizedBox(height: 14),
        _buildSectionLabel(),
        const SizedBox(height: 10),

        // ── Only the list fades on market switch ───────────────────
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: _currentCommodities
                .asMap()
                .entries
                .map((e) => _buildCommodityCard(e.value, e.key))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Greeting Card ─────────────────────────────────────────────────────
  Widget _buildGreetingCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        ),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2DB144),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tafadzwa Moyo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              _buildSunIcon(),
            ],
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 20),

          // ── Wallet row ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white.withOpacity(0.4), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'Wallet Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '\$180.00',
                    style: TextStyle(
                      color: Color(0xFF2DB144),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DB144).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Top Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Account chip ──────────────────────────────────────
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded,
                    color: const Color(0xFFD4A017).withOpacity(0.8),
                    size: 13),
                const SizedBox(width: 6),
                Text(
                  'Account: 0/535411',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                    width: 1,
                    height: 12,
                    color: Colors.white.withOpacity(0.12)),
                const SizedBox(width: 10),
                Icon(Icons.copy_rounded,
                    color: Colors.white.withOpacity(0.3), size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 3),
      builder: (context, value, child) =>
          Transform.rotate(angle: value * 0.8, child: child),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [Color(0xFFFFE066), Color(0xFFFFAA00)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFAA00).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Icon(Icons.wb_sunny_rounded,
            color: Colors.white, size: 30),
      ),
    );
  }

  // ── Quick Stats ───────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.trending_up_rounded,
            label: "Today's Gain",
            value: '+\$24.50',
            valueColor: const Color(0xFF2DB144),
            iconBg: const Color(0xFF2DB144),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.swap_horiz_rounded,
            label: 'Open Orders',
            value: '3',
            valueColor: const Color(0xFFD4A017),
            iconBg: const Color(0xFFD4A017),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.local_shipping_rounded,
            label: 'Deliveries',
            value: '2',
            valueColor: const Color(0xFF5B8AF0),
            iconBg: const Color(0xFF5B8AF0),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconBg, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Market Toggle ─────────────────────────────────────────────────────
  Widget _buildMarketToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                colors: [Color(0xFF2DB144), Color(0xFF1E8E32)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF2DB144).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF888888),
              fontSize: 13,
              fontWeight:
              isSelected ? FontWeight.w800 : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────
  Widget _buildSectionLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isPrimaryMarket ? 'Primary Market' : 'Secondary Market',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        Text(
          '${_currentCommodities.length} commodities',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Commodity Card ────────────────────────────────────────────────────
  Widget _buildCommodityCard(Map<String, dynamic> commodity, int index) {
    final bool isPositive = commodity['positive'] as bool;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPositive
                    ? const Color(0xFF2DB144).withOpacity(0.1)
                    : const Color(0xFFE53935).withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.grass_rounded,
                color: isPositive
                    ? const Color(0xFF2DB144)
                    : const Color(0xFFE53935),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // Name + currency pill
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    commodity['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A017).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      commodity['currency'],
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFD4A017),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bid / Ask
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Bid  ',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500)),
                      Text(
                        '\$${commodity['bid']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Ask  ',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500)),
                      Text(
                        '\$${commodity['ask']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD4A017),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPositive
                      ? [const Color(0xFF2DB144), const Color(0xFF1E8E32)]
                      : [const Color(0xFFE53935), const Color(0xFFC62828)],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: (isPositive
                        ? const Color(0xFF2DB144)
                        : const Color(0xFFE53935))
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ZiG ${commodity['price']}/kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        commodity['change'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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