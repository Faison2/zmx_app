import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AuctionModel {
  final int auctionId;
  final String auctionCode;
  final String auctionTitle;
  final String auctionType;
  final String? securityType;
  final String issuerName;
  final double totalVolume;
  final double minBidAmount;
  final double maxBidAmount;
  final double bidIncrement;
  final String startDate;
  final String endDate;
  final String settlementDate;
  final String status;
  final String allocationMethod;
  final String? description;
  final double couponRate;
  final String maturityDate;
  final double minimumYield;
  final double maximumYield;

  AuctionModel({
    required this.auctionId,
    required this.auctionCode,
    required this.auctionTitle,
    required this.auctionType,
    this.securityType,
    required this.issuerName,
    required this.totalVolume,
    required this.minBidAmount,
    required this.maxBidAmount,
    required this.bidIncrement,
    required this.startDate,
    required this.endDate,
    required this.settlementDate,
    required this.status,
    required this.allocationMethod,
    this.description,
    required this.couponRate,
    required this.maturityDate,
    required this.minimumYield,
    required this.maximumYield,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    return AuctionModel(
      auctionId: json['auctionId'] as int,
      auctionCode: json['auctionCode'] as String,
      auctionTitle: json['auctionTitle'] as String,
      auctionType: json['auctionType'] as String,
      securityType: json['securityType'] as String?,
      issuerName: json['issuerName'] as String,
      totalVolume: (json['totalVolume'] as num).toDouble(),
      minBidAmount: (json['minBidAmount'] as num).toDouble(),
      maxBidAmount: (json['maxBidAmount'] as num).toDouble(),
      bidIncrement: (json['bidIncrement'] as num).toDouble(),
      startDate: _formatDateTime(json['startDate'] as String),
      endDate: _formatDateTime(json['endDate'] as String),
      settlementDate: _formatDate(json['settlementDate'] as String),
      status: json['status'] as String,
      allocationMethod: json['allocationMethod'] as String,
      description: json['description'] as String?,
      couponRate: (json['couponRate'] as num).toDouble(),
      maturityDate: _formatDate(json['maturityDate'] as String),
      minimumYield: (json['minimumYield'] as num).toDouble(),
      maximumYield: (json['maximumYield'] as num).toDouble(),
    );
  }

  static String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} $h:$m';
    } catch (_) {
      return iso;
    }
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String get category => '$auctionCode · $auctionType';
  String get formattedTotalVolume => '\$${_compact(totalVolume)}';
  String get formattedMinBid => '\$${_compact(minBidAmount)}';
  String get formattedMaxBid => '\$${_compact(maxBidAmount)}';
  String get formattedBidIncrement => '\$${_compact(bidIncrement)}';
  String get formattedCouponRate => '${couponRate.toStringAsFixed(2)}%';

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class AuctionService {
  static const String _baseUrl = 'http://192.168.3.203:5049';

  static Future<List<AuctionModel>> fetchByStatus(String status) async {
    final uri = Uri.parse('$_baseUrl/v1/auction/status?status=$status');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AuctionModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load auctions (${response.statusCode})');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUCTION CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class AuctionContent extends StatefulWidget {
  const AuctionContent({super.key});

  @override
  State<AuctionContent> createState() => _AuctionContentState();
}

class _AuctionContentState extends State<AuctionContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<AuctionModel> _auctions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _loadAuctions();
  }

  Future<void> _loadAuctions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await AuctionService.fetchByStatus('ACTIVE');
      if (mounted) {
        setState(() {
          _auctions = data;
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showPlaceBid(AuctionModel auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceBidSheet(auction: auction),
    );
  }

  void _showDetails(AuctionModel auction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AuctionDetailsScreen(auction: auction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.only(
          top: 4,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          _buildHeader(),
          if (_auctions.isEmpty) _buildEmpty(),
          ..._auctions.asMap().entries.map(
                (e) => _buildAuctionCard(e.value, e.key),
          ),
        ],
      ),
    );
  }

  // ── Loading ──────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2DB144)),
          SizedBox(height: 16),
          Text(
            'Loading auctions...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Failed to load auctions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadAuctions,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ────────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.gavel_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No active auctions',
            style: TextStyle(
                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
          Row(
            children: [
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
                  '${_auctions.length} Active',
                  style: const TextStyle(
                    color: Color(0xFF2DB144),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              GestureDetector(
                onTap: _loadAuctions,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      size: 16, color: Color(0xFF1A1A1A)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Auction Card ─────────────────────────────────────────────────────────
  Widget _buildAuctionCard(AuctionModel auction, int index) {
    final active = auction.status == 'ACTIVE';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), child: child),
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      auction.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD4A017),
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(auction.status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                auction.auctionTitle,
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
                auction.issuerName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),

            // Stats Row
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statItem('TOTAL VOLUME', auction.formattedTotalVolume),
                  _statDivider(),
                  _statItem('MIN BID', auction.formattedMinBid),
                  _statDivider(),
                  _statItem('MAX BID', auction.formattedMaxBid),
                  _statDivider(),
                  _statItem('COUPON RATE', auction.formattedCouponRate),
                ],
              ),
            ),

            // Bid range pill
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BID RANGE',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5),
                  ),
                  Text(
                    '${auction.formattedMinBid} – ${auction.formattedMaxBid}  ·  +${auction.formattedBidIncrement} step',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFD4A017),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
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
                          auction.status,
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
                            color:
                            const Color(0xFFD4A017).withOpacity(0.5),
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
    return Container(width: 1, height: 28, color: Colors.grey.shade300);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE BID BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceBidSheet extends StatefulWidget {
  final AuctionModel auction;
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
    final active = auction.status == 'ACTIVE';

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
                    auction.auctionCode,
                    style: const TextStyle(
                      color: Color(0xFFD4A017),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auction.auctionTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Min: ${auction.formattedMinBid}  |  Max: ${auction.formattedMaxBid}  |  Step: ${auction.formattedBidIncrement}',
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
                      auction.status,
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

            _sectionLabel('CLIENT (ON BEHALF OF)'),
            const SizedBox(height: 8),
            _darkTextField(
              controller: _clientController,
              hint: 'Search client by name or CDS number...',
              suffixIcon: const Icon(Icons.search_rounded,
                  color: Colors.white38, size: 20),
            ),

            const SizedBox(height: 18),

            _sectionLabel('BID TYPE'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Row(
                children: [
                  _bidTypeTab('Competitive', true),
                  _bidTypeTab('Non-Competitive', false),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _sectionLabel('BID PRICE'),
            const SizedBox(height: 8),
            _darkTextField(
              controller: _bidPriceController,
              hint: 'Enter bid price',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 18),

            _sectionLabel('QUANTITY'),
            const SizedBox(height: 8),
            _darkTextField(
              controller: _quantityController,
              hint: 'Enter quantity',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 18),

            _sectionLabel('BID AMOUNT'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            color: Colors.white.withOpacity(0.15), width: 1),
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
                            color: const Color(0xFF2DB144).withOpacity(0.4),
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

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      color: Colors.white60,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
    ),
  );

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
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
              color:
              isSelected ? Colors.white : Colors.white.withOpacity(0.45),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
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
  final AuctionModel auction;
  const _AuctionDetailsScreen({required this.auction});

  @override
  Widget build(BuildContext context) {
    final active = auction.status == 'ACTIVE';
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      auction.auctionTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _statusBadge(auction.status),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // Row 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _detailCard(
                          title: 'AUCTION INFORMATION',
                          rows: [
                            _detailRow('Title', auction.auctionTitle),
                            _detailRow('Type', auction.auctionType),
                            _detailRow('Security Type',
                                auction.securityType ?? 'N/A'),
                            _detailRow('Issuer', auction.issuerName),
                            _detailRow(
                                'Allocation', auction.allocationMethod),
                            _detailRow('Status', auction.status,
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
                            _detailRow('Total Volume',
                                auction.formattedTotalVolume),
                            _detailRow('Min Bid', auction.formattedMinBid),
                            _detailRow('Max Bid', auction.formattedMaxBid),
                            _detailRow(
                                'Bid Step', auction.formattedBidIncrement),
                            _detailRow(
                                'Coupon Rate', auction.formattedCouponRate),
                            _detailRow('Min Yield',
                                '${auction.minimumYield.toStringAsFixed(2)}%'),
                            _detailRow('Max Yield',
                                '${auction.maximumYield.toStringAsFixed(2)}%'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Row 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _detailCard(
                          title: 'TIMELINE',
                          rows: [
                            _detailRow('Start', auction.startDate),
                            _detailRow('End', auction.endDate),
                            _detailRow(
                                'Settlement', auction.settlementDate),
                            _detailRow('Maturity', auction.maturityDate),
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
                              auction.description?.isNotEmpty == true
                                  ? auction.description!
                                  : 'No description available.',
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

                  if (active)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _PlaceBidSheet(auction: auction),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                              const Color(0xFF2DB144).withOpacity(0.4),
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
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
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
                  fontSize: 11, color: Colors.white.withOpacity(0.45)),
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