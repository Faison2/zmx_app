import 'package:flutter/material.dart';

class AuctionContent extends StatefulWidget {
  const AuctionContent({super.key});

  @override
  State<AuctionContent> createState() => _AuctionContentState();
}

class _AuctionContentState extends State<AuctionContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _auctions = [
    {
      'category': 'MAIZE · COMMODITY',
      'title': 'WHITE MAIZE',
      'issuer': 'ZMX',
      'status': 'ACTIVE',
      'totalVolume': '\$500',
      'minBid': '\$340',
      'maxBid': '\$400',
      'bidsReceived': '0',
      'couponRate': '1.00%',
      'subscription': '0.0% (\$0 / \$500)',
      'bidIncrement': '\$5',
      'type': 'COMMODITY',
      'securityType': 'Agricultural',
      'allocationMethod': 'DUTCH',
      'startDate': '20 Mar 2026 13:55',
      'endDate': '20 Mar 2026 14:05',
      'settlementDate': '20 Mar 2026',
      'maturity': '20 Mar 2026',
      'description': 'Premium white maize sourced from local farms.',
    },
    {
      'category': 'SOYABEANS LOT 2 · COMMODITY',
      'title': 'SOYABEANS',
      'issuer': 'ZMX',
      'status': 'ACTIVE',
      'totalVolume': '\$1,000',
      'minBid': '\$540',
      'maxBid': '\$650',
      'bidsReceived': '3',
      'couponRate': '1.00%',
      'subscription': '0.0% (\$0 / \$1,000)',
      'bidIncrement': '\$5',
      'type': 'COMMODITY',
      'securityType': 'Agricultural',
      'allocationMethod': 'DUTCH',
      'startDate': '20 Mar 2026 14:00',
      'endDate': '20 Mar 2026 15:00',
      'settlementDate': '20 Mar 2026',
      'maturity': '20 Mar 2026',
      'description': 'No description available',
    },
    {
      'category': 'WHEAT · COMMODITY',
      'title': 'HARD RED WHEAT',
      'issuer': 'ZMX',
      'status': 'CLOSED',
      'totalVolume': '\$750',
      'minBid': '\$280',
      'maxBid': '\$350',
      'bidsReceived': '7',
      'couponRate': '1.50%',
      'subscription': '85.0% (\$637 / \$750)',
      'bidIncrement': '\$5',
      'type': 'COMMODITY',
      'securityType': 'Agricultural',
      'allocationMethod': 'DUTCH',
      'startDate': '19 Mar 2026 09:00',
      'endDate': '19 Mar 2026 11:00',
      'settlementDate': '20 Mar 2026',
      'maturity': '20 Jun 2026',
      'description': 'Hard red wheat grade A quality.',
    },
    {
      'category': 'TOBACCO · COMMODITY',
      'title': 'FLUE CURED TOBACCO',
      'issuer': 'ZMX',
      'status': 'ACTIVE',
      'totalVolume': '\$2,500',
      'minBid': '\$800',
      'maxBid': '\$1,200',
      'bidsReceived': '12',
      'couponRate': '2.00%',
      'subscription': '40.0% (\$1,000 / \$2,500)',
      'bidIncrement': '\$10',
      'type': 'COMMODITY',
      'securityType': 'Agricultural',
      'allocationMethod': 'DUTCH',
      'startDate': '20 Mar 2026 10:00',
      'endDate': '20 Mar 2026 16:00',
      'settlementDate': '21 Mar 2026',
      'maturity': '20 Sep 2026',
      'description': 'Grade A flue cured tobacco bales.',
    },
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

  bool _isActive(String status) => status == 'ACTIVE';

  void _showPlaceBid(Map<String, dynamic> auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceBidSheet(auction: auction),
    );
  }

  void _showDetails(Map<String, dynamic> auction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AuctionDetailsScreen(auction: auction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.only(
          top: 4,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          _buildHeader(),
          ..._auctions.asMap().entries.map(
                (e) => _buildAuctionCard(e.value, e.key),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount =
        _auctions.where((a) => a['status'] == 'ACTIVE').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Auction',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2DB144).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF2DB144).withOpacity(0.35),
                  width: 1),
            ),
            child: Text(
              '$activeCount Active',
              style: const TextStyle(
                color: Color(0xFF2DB144),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionCard(Map<String, dynamic> auction, int index) {
    final active = _isActive(auction['status']);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child:
        Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0xFF2DB144).withOpacity(0.25)
                : Colors.grey.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    auction['category'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD4A017),
                      letterSpacing: 0.5,
                    ),
                  ),
                  _statusBadge(auction['status']),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                auction['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                auction['issuer'],
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            ),

            // ── Stats Row ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('TOTAL VOLUME', auction['totalVolume']),
                  _statDivider(),
                  _statItem('MIN BID', auction['minBid']),
                  _statDivider(),
                  _statItem('BIDS RECEIVED', auction['bidsReceived']),
                  _statDivider(),
                  _statItem('COUPON RATE', auction['couponRate']),
                ],
              ),
            ),

            // ── Subscription ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SUBSCRIPTION',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  Text(
                    auction['subscription'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: double.tryParse(
                      auction['subscription']
                          .toString()
                          .replaceAll('%', '')
                          .split('(')
                          .first
                          .trim()) !=
                      null
                      ? (double.parse(auction['subscription']
                      .toString()
                      .replaceAll('%', '')
                      .split('(')
                      .first
                      .trim()) /
                      100)
                      .clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    active
                        ? const Color(0xFF2DB144)
                        : Colors.grey.shade400,
                  ),
                  minHeight: 5,
                ),
              ),
            ),

            // ── Bottom Actions ────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF2DB144).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF2DB144).withOpacity(0.4)
                            : Colors.grey.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2DB144)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          auction['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: active
                                ? const Color(0xFF2DB144)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Details button
                  GestureDetector(
                    onTap: () => _showDetails(auction),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFD4A017).withOpacity(0.5),
                            width: 1.5),
                      ),
                      child: const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4A017),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Place Bid button
                  GestureDetector(
                    onTap: active ? () => _showPlaceBid(auction) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: active
                            ? const LinearGradient(
                          colors: [
                            Color(0xFF2DB144),
                            Color(0xFF1E8E32)
                          ],
                        )
                            : null,
                        color: active ? null : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: active
                            ? [
                          BoxShadow(
                            color: const Color(0xFF2DB144)
                                .withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                            : [],
                      ),
                      child: Text(
                        'PLACE BID',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? Colors.white
                              : Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
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

  Widget _statusBadge(String status) {
    final active = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2DB144).withOpacity(0.12)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? const Color(0xFF2DB144).withOpacity(0.4)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF2DB144) : Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
        width: 1, height: 28, color: Colors.grey.shade300);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE BID BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceBidSheet extends StatefulWidget {
  final Map<String, dynamic> auction;
  const _PlaceBidSheet({required this.auction});

  @override
  State<_PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends State<_PlaceBidSheet> {
  bool _isCompetitive = true;
  final _clientController = TextEditingController();
  final _bidPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  String get _bidAmount {
    final price = double.tryParse(_bidPriceController.text) ?? 0;
    final qty = double.tryParse(_quantityController.text) ?? 0;
    if (price > 0 && qty > 0) {
      return '\$${(price * qty).toStringAsFixed(2)}';
    }
    return 'Auto-calculated';
  }

  @override
  void dispose() {
    _clientController.dispose();
    _bidPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    final active = auction['status'] == 'ACTIVE';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            const Text(
              'Place Bid',
              style: TextStyle(
                color: Color(0xFFD4A017),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 14),

            // Auction summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFD4A017).withOpacity(0.25),
                    width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction['category'].toString().split('·').first.trim(),
                    style: const TextStyle(
                      color: Color(0xFFD4A017),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auction['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Min: ${auction['minBid']} | Max: ${auction['maxBid']} | Increment: ${auction['bidIncrement']}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.55)),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF2DB144).withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? const Color(0xFF2DB144).withOpacity(0.4)
                            : Colors.red.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      auction['status'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: active
                            ? const Color(0xFF2DB144)
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CLIENT
            _sectionLabel('CLIENT (ON BEHALF OF)'),
            const SizedBox(height: 8),
            _darkTextField(
              controller: _clientController,
              hint: 'Search client by name or CDS number...',
              suffixIcon: const Icon(Icons.search_rounded,
                  color: Colors.white38, size: 20),
            ),

            const SizedBox(height: 18),

            // BID TYPE
            _sectionLabel('BID TYPE'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Row(
                children: [
                  _bidTypeTab('Competitive', true),
                  _bidTypeTab('Non-Competitive', false),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // BID PRICE
            _sectionLabel('BID PRICE'),
            const SizedBox(height: 8),
            _darkTextField(
              controller: _bidPriceController,
              hint: 'Enter bid price',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 18),

            // QUANTITY
            _sectionLabel('QUANTITY'),
            const SizedBox(height: 8),
            _darkTextField(
              controller: _quantityController,
              hint: 'Enter quantity',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 18),

            // BID AMOUNT
            _sectionLabel('BID AMOUNT'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Text(
                _bidAmount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _bidAmount == 'Auto-calculated'
                      ? Colors.white38
                      : const Color(0xFF2DB144),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1),
                      ),
                      child: const Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: active ? () => Navigator.pop(context) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: active
                            ? const LinearGradient(colors: [
                          Color(0xFF2DB144),
                          Color(0xFF1E8E32)
                        ])
                            : null,
                        color: active ? null : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: active
                            ? [
                          BoxShadow(
                            color: const Color(0xFF2DB144)
                                .withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                            : [],
                      ),
                      child: const Text(
                        'Submit Bid',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border:
        Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 15),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _bidTypeTab(String label, bool isCompetitive) {
    final isSelected = _isCompetitive == isCompetitive;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isCompetitive = isCompetitive),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                colors: [Color(0xFF2DB144), Color(0xFF1E8E32)])
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF2DB144).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.45),
              fontSize: 14,
              fontWeight:
              isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUCTION DETAILS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _AuctionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> auction;
  const _AuctionDetailsScreen({required this.auction});

  @override
  Widget build(BuildContext context) {
    final active = auction['status'] == 'ACTIVE';
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      auction['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _statusBadge(auction['status']),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Row 1: Auction Info + Volume & Pricing
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _detailCard(
                          title: 'AUCTION INFORMATION',
                          rows: [
                            _detailRow('Title', auction['title']),
                            _detailRow('Type', auction['type']),
                            _detailRow('Security Type', auction['securityType']),
                            _detailRow('Issuer', auction['issuer']),
                            _detailRow('Allocation Method', auction['allocationMethod']),
                            _detailRow('Status', auction['status'],
                                valueColor: active
                                    ? const Color(0xFF2DB144)
                                    : Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailCard(
                          title: 'VOLUME & PRICING',
                          rows: [
                            _detailRow('Total Volume', auction['totalVolume']),
                            _detailRow('Min Bid', auction['minBid']),
                            _detailRow('Max Bid', auction['maxBid']),
                            _detailRow('Bid Increment', auction['bidIncrement']),
                            _detailRow('Coupon Rate', auction['couponRate']),
                            _detailRow('Maturity', auction['maturity']),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 2: Timeline + Description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _detailCard(
                          title: 'TIMELINE',
                          rows: [
                            _detailRow('Start Date', auction['startDate']),
                            _detailRow('End Date', auction['endDate']),
                            _detailRow('Settlement Date', auction['settlementDate']),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _detailCard(
                          title: 'DESCRIPTION',
                          rows: [],
                          extra: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              auction['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Place Bid button
                  if (active)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              _PlaceBidSheet(auction: auction),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2DB144),
                              Color(0xFF1E8E32)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2DB144)
                                  .withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Text(
                          'PLACE BID',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
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

  Widget _statusBadge(String status) {
    final active = status == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2DB144).withOpacity(0.15)
            : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? const Color(0xFF2DB144).withOpacity(0.4)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: active ? const Color(0xFF2DB144) : Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required List<Widget> rows,
    Widget? extra,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD4A017),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 10),
          ...rows,
          if (extra != null) extra,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}