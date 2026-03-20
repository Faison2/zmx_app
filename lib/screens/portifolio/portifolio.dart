import 'package:flutter/material.dart';

class PortfolioContent extends StatefulWidget {
  const PortfolioContent({super.key});

  @override
  State<PortfolioContent> createState() => _PortfolioContentState();
}

class _PortfolioContentState extends State<PortfolioContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _holdings = [
    {'commodity': 'Beans/GMBA/USD', 'price': '23.43', 'quantity': '200', 'value': '4686.00'},
    {'commodity': 'Maize/GMBA/USD', 'price': '8.15', 'quantity': '500', 'value': '4075.00'},
    {'commodity': 'Wheat/GMBA/USD', 'price': '9.45', 'quantity': '350', 'value': '3307.50'},
    {'commodity': 'Soya/GMBA/USD', 'price': '15.25', 'quantity': '180', 'value': '2745.00'},
    {'commodity': 'Cotton/GMBA/USD', 'price': '7.35', 'quantity': '420', 'value': '3087.00'},
    {'commodity': 'Millet/GMBA/USD', 'price': '6.55', 'quantity': '310', 'value': '2030.50'},
    {'commodity': 'Tobacco/GMBA/USD', 'price': '22.15', 'quantity': '150', 'value': '3322.50'},
    {'commodity': 'Sugar Cane/USD', 'price': '4.85', 'quantity': '900', 'value': '4365.00'},
    {'commodity': 'Beans/GMBA/USD', 'price': '23.43', 'quantity': '200', 'value': '4686.00'},
    {'commodity': 'Maize/GMBA/USD', 'price': '8.15', 'quantity': '500', 'value': '4075.00'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 90,
        ),
        children: [
          _buildHeader(),
          _buildSummaryCard(),
          _buildHoldingsSection(),
        ],
      ),
    );
  }

  // ── Page Title ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Portfolio',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
              letterSpacing: 0.3,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2DB144).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF2DB144).withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: const [
                Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF2DB144), size: 16),
                SizedBox(width: 5),
                Text(
                  'Live',
                  style: TextStyle(
                    color: Color(0xFF2DB144),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ZiG / USD Summary Card ────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildSummaryColumn('ZiG', '-10.45', '-10.45', false)),
            VerticalDivider(
              color: const Color(0xFFD4A017),
              thickness: 1.5,
              indent: 16,
              endIndent: 16,
            ),
            Expanded(child: _buildSummaryColumn('USD', '+\$10.45', '+\$10.45', true)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(
      String currency, String gainLoss, String portfolioValue, bool isPositive) {
    final color = isPositive ? const Color(0xFF2DB144) : const Color(0xFFE53935);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currency,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          _summaryRow('Gain/Loss:', gainLoss, color),
          const SizedBox(height: 10),
          _summaryRow('Portfolio Value:', portfolioValue, color),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Holdings List ─────────────────────────────────────────────────────
  Widget _buildHoldingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
         colors: [Color(0xFFD4A017), Color(0xFFB8890F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
           color: const Color(0xFFD4A017).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: _holdings
                .asMap()
                .entries
                .map((e) => _buildHoldingCard(e.value, e.key))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingCard(Map<String, String> holding, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 60)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Commodity icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2DB144).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.grass_rounded,
                color: Color(0xFF2DB144),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Name + price
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding['commodity']!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money_rounded,
                          size: 12, color: Color(0xFF888888)),
                      Text(
                        'Price: \$${holding['price']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quantity + Value badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2DB144).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Quantity: ${holding['quantity']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Value: ${holding['value']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}