import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class AuctionModel {
  final int auctionId;
  final String auctionCode;
  final String auctionTitle;
  final String auctionType;
  final String? securityType;
  final String? issuerName;
  final double totalVolume;
  final double minBidAmount;
  final double maxBidAmount;
  final double bidIncrement;
  final String startDate;
  final String endDate;

  // ── Raw DateTime fields for countdown calculations ──────────────────────
  final DateTime startDateRaw;
  final DateTime endDateRaw;

  final String? settlementDate;
  final String status;
  final String allocationMethod;
  final String? description;
  final double? couponRate;
  final String? maturityDate;
  final double? minimumYield;
  final double? maximumYield;
  final bool isCommodityAuction;
  final double? reservePrice;
  final String? lotNumber;
  final String? lastBidTime;
  final double? currentHighestBid;
  final String? currentHighestBidderCode;
  final String? currentHighestBidderName;
  final int totalExtensions;

  AuctionModel({
    required this.auctionId,
    required this.auctionCode,
    required this.auctionTitle,
    required this.auctionType,
    this.securityType,
    this.issuerName,
    required this.totalVolume,
    required this.minBidAmount,
    required this.maxBidAmount,
    required this.bidIncrement,
    required this.startDate,
    required this.endDate,
    required this.startDateRaw,
    required this.endDateRaw,
    this.settlementDate,
    required this.status,
    required this.allocationMethod,
    this.description,
    this.couponRate,
    this.maturityDate,
    this.minimumYield,
    this.maximumYield,
    required this.isCommodityAuction,
    this.reservePrice,
    this.lotNumber,
    this.lastBidTime,
    this.currentHighestBid,
    this.currentHighestBidderCode,
    this.currentHighestBidderName,
    required this.totalExtensions,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startDate'] as String;
    final rawEnd   = json['endDate']   as String;

    DateTime parsedStart;
    DateTime parsedEnd;
    try { parsedStart = DateTime.parse(rawStart); } catch (_) { parsedStart = DateTime.now(); }
    try { parsedEnd   = DateTime.parse(rawEnd);   } catch (_) { parsedEnd   = DateTime.now(); }

    return AuctionModel(
      auctionId:    json['auctionId'] as int,
      auctionCode:  json['auctionCode'] as String,
      auctionTitle: json['auctionTitle'] as String,
      auctionType:  json['auctionType'] as String,
      securityType: json['securityType'] as String?,
      issuerName:   json['issuerName'] as String?,
      totalVolume:  (json['totalVolume'] as num).toDouble(),
      minBidAmount: (json['minBidAmount'] as num).toDouble(),
      maxBidAmount: (json['maxBidAmount'] as num).toDouble(),
      bidIncrement: (json['bidIncrement'] as num).toDouble(),
      startDate:    _formatDateTime(rawStart),
      endDate:      _formatDateTime(rawEnd),
      startDateRaw: parsedStart,
      endDateRaw:   parsedEnd,
      settlementDate: json['settlementDate'] != null
          ? _formatDate(json['settlementDate'] as String) : null,
      status:           json['status'] as String,
      allocationMethod: json['allocationMethod'] as String,
      description:      json['description'] as String?,
      couponRate: json['couponRate'] != null
          ? (json['couponRate'] as num).toDouble() : null,
      maturityDate: json['maturityDate'] != null
          ? _formatDate(json['maturityDate'] as String) : null,
      minimumYield: json['minimumYield'] != null
          ? (json['minimumYield'] as num).toDouble() : null,
      maximumYield: json['maximumYield'] != null
          ? (json['maximumYield'] as num).toDouble() : null,
      isCommodityAuction:      json['isCommodityAuction'] as bool? ?? false,
      reservePrice: json['reservePrice'] != null
          ? (json['reservePrice'] as num).toDouble() : null,
      lotNumber:               json['lotNumber'] as String?,
      lastBidTime: json['lastBidTime'] != null
          ? _formatDateTime(json['lastBidTime'] as String) : null,
      currentHighestBid: json['currentHighestBid'] != null
          ? (json['currentHighestBid'] as num).toDouble() : null,
      currentHighestBidderCode: json['currentHighestBidderCode'] as String?,
      currentHighestBidderName: json['currentHighestBidderName'] as String?,
      totalExtensions: json['totalExtensions'] as int? ?? 0,
    );
  }

  static String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} $h:$m';
    } catch (_) { return iso; }
  }

  static String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso; }
  }

  String get category => lotNumber != null
      ? '$auctionCode · Lot $lotNumber'
      : '$auctionCode · $auctionType';

  String get formattedTotalVolume => isCommodityAuction
      ? '${totalVolume.toStringAsFixed(0)} T'
      : '\$${_compact(totalVolume)}';
  String get formattedMinBid       => '\$${_compact(minBidAmount)}';
  String get formattedMaxBid       => '\$${_compact(maxBidAmount)}';
  String get formattedBidIncrement => '\$${_compact(bidIncrement)}';
  String get formattedCouponRate   =>
      couponRate != null ? '${couponRate!.toStringAsFixed(2)}%' : 'N/A';
  String get formattedReservePrice =>
      reservePrice != null ? '\$${reservePrice!.toStringAsFixed(2)}' : 'N/A';
  String get formattedHighestBid   =>
      currentHighestBid != null ? '\$${currentHighestBid!.toStringAsFixed(2)}' : 'No bids yet';

  static String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(1)}K';
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
  }
}

// ── Auction Result Model ─────────────────────────────────────────────────────
class AuctionResultModel {
  final int resultId;
  final int auctionId;
  final int totalBidsReceived;
  final double totalBidAmount;
  final double totalAllocated;
  final double averageBidPrice;
  final double highestBidPrice;
  final double lowestBidPrice;
  final double cutoffPrice;
  final double averageYield;
  final double highestYield;
  final double lowestYield;
  final double? cutoffYield;
  final double allocationRatio;
  final double bidToCoverRatio;
  final double? uniformPrice;
  final bool resultPublished;
  final String? publishedDate;
  final bool settlementCompleted;
  final String? settlementDate;

  AuctionResultModel({
    required this.resultId,
    required this.auctionId,
    required this.totalBidsReceived,
    required this.totalBidAmount,
    required this.totalAllocated,
    required this.averageBidPrice,
    required this.highestBidPrice,
    required this.lowestBidPrice,
    required this.cutoffPrice,
    required this.averageYield,
    required this.highestYield,
    required this.lowestYield,
    this.cutoffYield,
    required this.allocationRatio,
    required this.bidToCoverRatio,
    this.uniformPrice,
    required this.resultPublished,
    this.publishedDate,
    required this.settlementCompleted,
    this.settlementDate,
  });

  factory AuctionResultModel.fromJson(Map<String, dynamic> json) {
    return AuctionResultModel(
      resultId:            json['resultId'] as int,
      auctionId:           json['auctionId'] as int,
      totalBidsReceived:   json['totalBidsReceived'] as int,
      totalBidAmount:      (json['totalBidAmount'] as num).toDouble(),
      totalAllocated:      (json['totalAllocated'] as num).toDouble(),
      averageBidPrice:     (json['averageBidPrice'] as num).toDouble(),
      highestBidPrice:     (json['highestBidPrice'] as num).toDouble(),
      lowestBidPrice:      (json['lowestBidPrice'] as num).toDouble(),
      cutoffPrice:         (json['cutoffPrice'] as num).toDouble(),
      averageYield:        (json['averageYield'] as num).toDouble(),
      highestYield:        (json['highestYield'] as num).toDouble(),
      lowestYield:         (json['lowestYield'] as num).toDouble(),
      cutoffYield:         json['cutoffYield'] != null ? (json['cutoffYield'] as num).toDouble() : null,
      allocationRatio:     (json['allocationRatio'] as num).toDouble(),
      bidToCoverRatio:     (json['bidToCoverRatio'] as num).toDouble(),
      uniformPrice:        json['uniformPrice'] != null ? (json['uniformPrice'] as num).toDouble() : null,
      resultPublished:     json['resultPublished'] as bool? ?? false,
      publishedDate:       json['publishedDate'] as String?,
      settlementCompleted: json['settlementCompleted'] as bool? ?? false,
      settlementDate:      json['settlementDate'] as String?,
    );
  }

  static String _fmt(double v) =>
      v >= 1000000 ? '\$${(v / 1000000).toStringAsFixed(2)}M'
          : v >= 1000  ? '\$${(v / 1000).toStringAsFixed(2)}K'
          : '\$${v.toStringAsFixed(2)}';

  String get fmtTotalBidAmount  => _fmt(totalBidAmount);
  String get fmtTotalAllocated  => _fmt(totalAllocated);
  String get fmtAverageBidPrice => '\$${averageBidPrice.toStringAsFixed(2)}';
  String get fmtHighestBidPrice => '\$${highestBidPrice.toStringAsFixed(2)}';
  String get fmtLowestBidPrice  => '\$${lowestBidPrice.toStringAsFixed(2)}';
  String get fmtCutoffPrice     => '\$${cutoffPrice.toStringAsFixed(2)}';
  String get fmtBidToCoverRatio => '${bidToCoverRatio.toStringAsFixed(2)}x';
  String get fmtAllocationRatio => '${allocationRatio.toStringAsFixed(2)}%';
  String get fmtUniformPrice    =>
      uniformPrice != null ? '\$${uniformPrice!.toStringAsFixed(2)}' : 'N/A';
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class AuctionService {
  static const String _baseUrl = 'https://ussd.zmx.co.zw';

  static Future<List<AuctionModel>> fetchAll() async {
    final uri = Uri.parse('$_baseUrl/v1/auction/all');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AuctionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load auctions (${response.statusCode})');
  }

  static Future<AuctionResultModel?> fetchResults(int auctionId) async {
    final uri = Uri.parse('$_baseUrl/v1/auction/$auctionId/results');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body == 'null' || body.isEmpty) return null;
      return AuctionResultModel.fromJson(jsonDecode(body));
    }
    if (response.statusCode == 404) return null;
    throw Exception('Failed to load results (${response.statusCode})');
  }

  static Future<void> placeBid({
    required String? lotNumber,
    required double bidPrice,
    required int bidQuantity,
    required String clientCode,
    required String clientName,
  }) async {
    final uri = Uri.parse('$_baseUrl/v1/auction/bids');
    final body = <String, dynamic>{
      'bidPrice':    bidPrice,
      'bidQuantity': bidQuantity,
      'clientCode':  clientCode,
      'clientName':  clientName,
      'submittedBy': 'mobile',
      if (lotNumber != null) 'lotNumber': lotNumber,
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to place bid (${response.statusCode}): ${response.body}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNTDOWN TIMER WIDGET
// Ticks every second; shows time remaining to endDate when ACTIVE,
// time until startDate when PENDING, and "Ended" when CLOSED.
// ─────────────────────────────────────────────────────────────────────────────
class _AuctionCountdown extends StatefulWidget {
  final AuctionModel auction;
  const _AuctionCountdown({required this.auction});

  @override
  State<_AuctionCountdown> createState() => _AuctionCountdownState();
}

class _AuctionCountdownState extends State<_AuctionCountdown> {
  late Timer _timer;
  late Duration _remaining;
  late _CountdownMode _mode;

  @override
  void initState() {
    super.initState();
    _compute();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_compute);
    });
  }

  void _compute() {
    final now   = DateTime.now();
    final start = widget.auction.startDateRaw;
    final end   = widget.auction.endDateRaw;

    if (now.isBefore(start)) {
      _mode      = _CountdownMode.pending;
      _remaining = start.difference(now);
    } else if (now.isBefore(end)) {
      _mode      = _CountdownMode.active;
      _remaining = end.difference(now);
    } else {
      _mode      = _CountdownMode.ended;
      _remaining = Duration.zero;
    }
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _label {
    switch (_mode) {
      case _CountdownMode.pending: return 'Starts in';
      case _CountdownMode.active:  return 'Ends in';
      case _CountdownMode.ended:   return 'Ended';
    }
  }

  Color get _color {
    switch (_mode) {
      case _CountdownMode.pending: return const Color(0xFFD4A017);
      case _CountdownMode.active:  return const Color(0xFF2DB144);
      case _CountdownMode.ended:   return Colors.redAccent;
    }
  }

  IconData get _icon {
    switch (_mode) {
      case _CountdownMode.pending: return Icons.schedule_rounded;
      case _CountdownMode.active:  return Icons.timer_outlined;
      case _CountdownMode.ended:   return Icons.timer_off_outlined;
    }
  }

  String get _timeString {
    if (_mode == _CountdownMode.ended) return '--:--:--';
    final d  = _remaining.inDays;
    final h  = _pad(_remaining.inHours.remainder(24));
    final m  = _pad(_remaining.inMinutes.remainder(60));
    final s  = _pad(_remaining.inSeconds.remainder(60));
    return d > 0 ? '${d}d $h:$m:$s' : '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(children: [
        Icon(_icon, size: 15, color: color),
        const SizedBox(width: 7),
        Text(_label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: color.withOpacity(0.75))),
        const Spacer(),
        Text(_timeString,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                color: color, letterSpacing: 0.5,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

enum _CountdownMode { pending, active, ended }

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
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'ACTIVE', 'PENDING', 'CLOSED'];

  List<AuctionModel> get _filteredAuctions => _selectedFilter == 'ALL'
      ? _auctions
      : _auctions.where((a) => a.status == _selectedFilter).toList();

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AuctionService.fetchAll();
      if (mounted) {
        setState(() { _auctions = data; _isLoading = false; });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  void dispose() { _fadeController.dispose(); super.dispose(); }

  void _showPlaceBid(AuctionModel auction) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceBidSheet(auction: auction),
  );

  void _showDetails(AuctionModel auction) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _AuctionDetailsScreen(auction: auction)),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.only(
            top: 4, bottom: MediaQuery.of(context).padding.bottom + 100),
        children: [
          _buildHeader(),
          _buildFilterBar(),
          if (_filteredAuctions.isEmpty) _buildEmpty(),
          ..._filteredAuctions.asMap().entries
              .map((e) => _buildAuctionCard(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: Color(0xFF2DB144)),
      SizedBox(height: 16),
      Text('Loading auctions...',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
    ]),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text('Failed to load auctions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 8),
        Text(_error ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _loadAuctions,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Retry',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildEmpty() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: Column(children: [
      Icon(Icons.gavel_rounded, size: 48, color: Colors.grey),
      SizedBox(height: 12),
      Text('No auctions found',
          style: TextStyle(color: Colors.grey, fontSize: 15,
              fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _buildHeader() {
    final activeCount = _auctions.where((a) => a.status == 'ACTIVE').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Auction',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A))),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2DB144).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF2DB144).withOpacity(0.35)),
              ),
              child: Text('$activeCount Active',
                  style: const TextStyle(color: Color(0xFF2DB144),
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
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
          ]),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter   = _filters[i];
          final selected = _selectedFilter == filter;
          final count    = filter == 'ALL'
              ? _auctions.length
              : _auctions.where((a) => a.status == filter).length;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                    colors: [Color(0xFF2DB144), Color(0xFF1E8E32)])
                    : null,
                color: selected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selected
                        ? const Color(0xFF2DB144)
                        : Colors.grey.shade300),
              ),
              child: Text('$filter ($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.grey.shade600,
                  )),
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':  return const Color(0xFF2DB144);
      case 'PENDING': return const Color(0xFFD4A017);
      case 'CLOSED':  return Colors.redAccent;
      default:        return Colors.grey;
    }
  }

  Widget _buildAuctionCard(AuctionModel auction, int index) {
    final isActive    = auction.status == 'ACTIVE';
    final isClosed    = auction.status == 'CLOSED';
    final statusColor = _statusColor(auction.status);

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
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07),
                blurRadius: 12, offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(auction.category,
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: Color(0xFFD4A017),
                          letterSpacing: 0.5),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                _statusBadge(auction.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Text(auction.auctionTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A))),
          ),
          if (auction.description != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(auction.description!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )
          else
            const SizedBox(height: 10),

          // ── COUNTDOWN TIMER ──────────────────────────────────────────────
          _AuctionCountdown(auction: auction),

          const SizedBox(height: 10),

          // Stats row
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem('VOLUME', auction.formattedTotalVolume),
                _statDivider(),
                _statItem('MIN BID', auction.formattedMinBid),
                _statDivider(),
                _statItem('MAX BID', auction.formattedMaxBid),
                _statDivider(),
                _statItem(
                  auction.isCommodityAuction ? 'RESERVE' : 'COUPON',
                  auction.isCommodityAuction
                      ? auction.formattedReservePrice
                      : auction.formattedCouponRate,
                ),
              ],
            ),
          ),

          // ── HIGHEST BID STRIP — bidder name intentionally hidden ─────────
          if (auction.isCommodityAuction && auction.currentHighestBid != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF2DB144).withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.trending_up_rounded, size: 16,
                      color: Color(0xFF2DB144)),
                  const SizedBox(width: 8),
                  Text('Highest Bid: ${auction.formattedHighestBid}',
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2DB144))),
                  // Bidder name removed intentionally
                ]),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BID RANGE',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                Text(
                  '${auction.formattedMinBid} – ${auction.formattedMaxBid}  ·  +${auction.formattedBidIncrement} step',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFD4A017),
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              const Spacer(),
              if (isClosed) ...[
                GestureDetector(
                  onTap: () => _showDetails(auction),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.4), width: 1.5),
                    ),
                    child: const Text('Results',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: Colors.redAccent)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
                  child: const Text('Details',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFFD4A017))),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isActive ? () => _showPlaceBid(auction) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                        colors: [Color(0xFF2DB144), Color(0xFF1E8E32)])
                        : null,
                    color: isActive ? null : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isActive
                        ? [BoxShadow(
                        color: const Color(0xFF2DB144).withOpacity(0.35),
                        blurRadius: 8, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Text('PLACE BID',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          color: isActive ? Colors.white : Colors.grey.shade500,
                          letterSpacing: 0.5)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: color, letterSpacing: 0.5)),
    );
  }

  Widget _statItem(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500,
              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A))),
    ],
  );

  Widget _statDivider() =>
      Container(width: 1, height: 28, color: Colors.grey.shade300);
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
  bool _isSubmitting  = false;
  bool _submitSuccess = false;
  String? _submitError;

  final _bidPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  String _clientCode = 'DEFAULT';
  String _clientName = 'Default Client';

  @override
  void initState() { super.initState(); _loadUserPrefs(); }

  Future<void> _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _clientCode = prefs.getString('user_cds')  ?? 'DEFAULT';
        _clientName = prefs.getString('user_name') ?? 'Default Client';
      });
    }
  }

  @override
  void dispose() {
    _bidPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  double get _price    => double.tryParse(_bidPriceController.text) ?? 0;
  double get _quantity => double.tryParse(_quantityController.text) ?? 0;
  double get _amount   => (_price > 0 && _quantity > 0) ? _price * _quantity : 0;
  String get _displayAmount =>
      _amount > 0 ? '\$${_amount.toStringAsFixed(2)}' : 'Auto-calculated';

  Future<void> _submitBid() async {
    if (_price <= 0) {
      setState(() => _submitError = 'Please enter a valid bid price.');
      return;
    }
    if (_quantity <= 0) {
      setState(() => _submitError = 'Please enter a valid quantity.');
      return;
    }
    setState(() { _isSubmitting = true; _submitError = null; });
    try {
      await AuctionService.placeBid(
        lotNumber:   widget.auction.lotNumber,
        bidPrice:    _price,
        bidQuantity: _quantity.toInt(),
        clientCode:  _clientCode,
        clientName:  _clientName,
      );
      if (mounted) setState(() { _isSubmitting = false; _submitSuccess = true; });
    } catch (e) {
      if (mounted) setState(() {
        _isSubmitting = false;
        _submitError  = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8, left: 20, right: 20,
      ),
      child: SingleChildScrollView(
        child: _submitSuccess
            ? _buildSuccess()
            : _buildForm(widget.auction),
      ),
    );
  }

  Widget _buildSuccess() => Column(mainAxisSize: MainAxisSize.min, children: [
    _handle(),
    const SizedBox(height: 30),
    Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(
            color: const Color(0xFF2DB144).withOpacity(0.4), blurRadius: 20)],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
    ),
    const SizedBox(height: 20),
    const Text('Bid Submitted!',
        style: TextStyle(color: Colors.white, fontSize: 24,
            fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    Text('Your bid has been placed for\n${widget.auction.auctionTitle}',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5)),
    const SizedBox(height: 30),
    GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('Done', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w900)),
      ),
    ),
    const SizedBox(height: 8),
  ]);

  Widget _buildForm(AuctionModel auction) {
    final isActive = auction.status == 'ACTIVE';
    return Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          _handle(),
          const Text('Place Bid',
              style: TextStyle(color: Color(0xFFD4A017), fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 14),

          // Auction summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(auction.auctionCode,
                  style: const TextStyle(color: Color(0xFFD4A017), fontSize: 12,
                      fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(auction.auctionTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Min: ${auction.formattedMinBid}  |  Max: ${auction.formattedMaxBid}  |  Step: ${auction.formattedBidIncrement}',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55)),
              ),
              if (auction.isCommodityAuction && auction.reservePrice != null) ...[
                const SizedBox(height: 4),
                Text('Reserve: ${auction.formattedReservePrice}  |  Volume: ${auction.formattedTotalVolume}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
              ],
              if (auction.lotNumber != null) ...[
                const SizedBox(height: 4),
                Text('Lot: ${auction.lotNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
              ],
              if (auction.currentHighestBid != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DB144).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2DB144).withOpacity(0.35)),
                  ),
                  child: Text('Current Highest: ${auction.formattedHighestBid}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                          color: Color(0xFF2DB144))),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // ── CLIENT — only code shown, name intentionally hidden ───────────
          _sectionLabel('CLIENT'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: _infoRow('Client Code', _clientCode),
          ),

          const SizedBox(height: 18),
          _sectionLabel('BID PRICE'),
          const SizedBox(height: 8),
          _darkTextField(
            controller: _bidPriceController,
            hint: 'Enter bid price',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 18),
          _sectionLabel(auction.isCommodityAuction ? 'QUANTITY (TONNES)' : 'QUANTITY'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(_displayAmount,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: _amount > 0
                        ? const Color(0xFF2DB144)
                        : Colors.white38)),
          ),

          if (_submitError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_submitError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 28),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text('Cancel', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: (isActive && !_isSubmitting) ? _submitBid : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                        colors: [Color(0xFF2DB144), Color(0xFF1E8E32)])
                        : null,
                    color: isActive ? null : Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isActive
                        ? [BoxShadow(color: const Color(0xFF2DB144).withOpacity(0.4),
                        blurRadius: 12, offset: const Offset(0, 4))]
                        : [],
                  ),
                  child: _isSubmitting
                      ? const Center(
                      child: SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)))
                      : const Text('Submit Bid', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
            ),
          ]),
        ]);
  }

  Widget _handle() => Center(
    child: Container(width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2)),
    ),
  );

  Widget _infoRow(String label, String value) => Row(children: [
    Text('$label:', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
    const SizedBox(width: 8),
    Expanded(child: Text(value.isNotEmpty ? value : '—',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
        overflow: TextOverflow.ellipsis)),
  ]);

  Widget _sectionLabel(String label) => Text(label,
      style: const TextStyle(color: Colors.white60, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.0));

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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

// ─────────────────────────────────────────────────────────────────────────────
// AUCTION DETAILS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _AuctionDetailsScreen extends StatefulWidget {
  final AuctionModel auction;
  const _AuctionDetailsScreen({required this.auction});

  @override
  State<_AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<_AuctionDetailsScreen>
    with SingleTickerProviderStateMixin {
  AuctionResultModel? _result;
  bool _loadingResult = false;
  String? _resultError;
  late TabController _tabController;

  bool get _isClosed  => widget.auction.status == 'CLOSED';
  bool get _isActive  => widget.auction.status == 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _isClosed ? 2 : 1, vsync: this);
    if (_isClosed) _loadResults();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadResults() async {
    setState(() { _loadingResult = true; _resultError = null; });
    try {
      final r = await AuctionService.fetchResults(widget.auction.auctionId);
      if (mounted) setState(() { _result = r; _loadingResult = false; });
    } catch (e) {
      if (mounted) setState(() {
        _resultError = e.toString().replaceFirst('Exception: ', '');
        _loadingResult = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE':  return const Color(0xFF2DB144);
      case 'PENDING': return const Color(0xFFD4A017);
      case 'CLOSED':  return Colors.redAccent;
      default:        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(auction.auctionTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 17,
                      fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              _statusBadge(auction.status),
            ]),
          ),

          if (_isClosed) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A6B2A), Color(0xFF0F4D1D)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF2DB144).withOpacity(0.3),
                        blurRadius: 8)],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      letterSpacing: 0.3),
                  tabs: const [
                    Tab(text: 'Information'),
                    Tab(text: 'Results'),
                  ],
                ),
              ),
            ),
          ] else
            const SizedBox(height: 14),

          Expanded(
            child: _isClosed
                ? TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(auction),
                _buildResultsTab(),
              ],
            )
                : _buildInfoTab(auction),
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoTab(AuctionModel auction) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _detailCard(
            title: 'AUCTION INFORMATION',
            rows: [
              _detailRow('Code', auction.auctionCode),
              _detailRow('Type', auction.auctionType),
              if (auction.lotNumber != null)    _detailRow('Lot', auction.lotNumber!),
              if (auction.securityType != null) _detailRow('Security', auction.securityType!),
              if (auction.issuerName != null)   _detailRow('Issuer', auction.issuerName!),
              _detailRow('Allocation', auction.allocationMethod),
              _detailRow('Status', auction.status,
                  valueColor: _statusColor(auction.status)),
            ],
          )),
          const SizedBox(width: 12),
          Expanded(child: _detailCard(
            title: 'VOLUME & PRICING',
            rows: [
              _detailRow('Total Volume', auction.formattedTotalVolume),
              _detailRow('Min Bid', auction.formattedMinBid),
              _detailRow('Max Bid', auction.formattedMaxBid),
              _detailRow('Bid Step', auction.formattedBidIncrement),
              if (auction.isCommodityAuction) ...[
                _detailRow('Reserve Price', auction.formattedReservePrice),
                _detailRow('Highest Bid', auction.formattedHighestBid,
                    valueColor: auction.currentHighestBid != null
                        ? const Color(0xFF2DB144) : null),
                // Top Bidder row removed intentionally
                _detailRow('Extensions', '${auction.totalExtensions}'),
              ] else ...[
                _detailRow('Coupon Rate', auction.formattedCouponRate),
                if (auction.minimumYield != null)
                  _detailRow('Min Yield', '${auction.minimumYield!.toStringAsFixed(2)}%'),
                if (auction.maximumYield != null)
                  _detailRow('Max Yield', '${auction.maximumYield!.toStringAsFixed(2)}%'),
              ],
            ],
          )),
        ]),

        const SizedBox(height: 12),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _detailCard(
            title: 'TIMELINE',
            rows: [
              _detailRow('Start', auction.startDate),
              _detailRow('End', auction.endDate),
              if (auction.settlementDate != null)
                _detailRow('Settlement', auction.settlementDate!),
              if (auction.maturityDate != null)
                _detailRow('Maturity', auction.maturityDate!),
              if (auction.lastBidTime != null)
                _detailRow('Last Bid', auction.lastBidTime!),
            ],
          )),
          const SizedBox(width: 12),
          Expanded(child: _detailCard(
            title: 'DESCRIPTION',
            rows: [],
            extra: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                auction.description?.isNotEmpty == true
                    ? auction.description!
                    : 'No description available.',
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.6), height: 1.5),
              ),
            ),
          )),
        ]),

        const SizedBox(height: 20),

        if (_isActive)
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF2DB144).withOpacity(0.4),
                    blurRadius: 14, offset: const Offset(0, 6))],
              ),
              child: const Text('PLACE BID', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsTab() {
    if (_loadingResult) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2DB144), strokeWidth: 2),
          SizedBox(height: 16),
          Text('Fetching results...', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ));
    }

    if (_resultError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.signal_wifi_off_rounded, color: Colors.redAccent, size: 44),
          const SizedBox(height: 16),
          const Text('Could not load results',
              style: TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_resultError!, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _loadResults,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Try Again',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ));
    }

    if (_result == null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Colors.white38, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Results not yet published',
              style: TextStyle(color: Colors.white54, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Check back later',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
        ],
      ));
    }

    final r = _result!;

    final priceRange = r.highestBidPrice - r.lowestBidPrice;
    final cutoffFraction = priceRange > 0
        ? ((r.cutoffPrice - r.lowestBidPrice) / priceRange).clamp(0.0, 1.0)
        : 0.5;
    final avgFraction = priceRange > 0
        ? ((r.averageBidPrice - r.lowestBidPrice) / priceRange).clamp(0.0, 1.0)
        : 0.5;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [

        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: r.resultPublished
                  ? const LinearGradient(
                  colors: [Color(0xFF1A6B2A), Color(0xFF0F4D1D)])
                  : null,
              color: r.resultPublished ? null : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: r.resultPublished
                    ? const Color(0xFF2DB144).withOpacity(0.5)
                    : Colors.white.withOpacity(0.12),
              ),
            ),
            child: Row(children: [
              Icon(r.resultPublished
                  ? Icons.verified_rounded
                  : Icons.pending_rounded,
                  size: 14,
                  color: r.resultPublished
                      ? const Color(0xFF2DB144)
                      : Colors.white38),
              const SizedBox(width: 6),
              Text(r.resultPublished ? 'Published' : 'Unpublished',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: r.resultPublished
                        ? const Color(0xFF2DB144)
                        : Colors.white38,
                  )),
            ]),
          ),
          if (r.publishedDate != null) ...[
            const SizedBox(width: 10),
            Text(_fmtDt(r.publishedDate!),
                style: TextStyle(fontSize: 11,
                    color: Colors.white.withOpacity(0.35))),
          ],
          const Spacer(),
          Text('Result #${r.resultId}',
              style: TextStyle(fontSize: 11,
                  color: Colors.white.withOpacity(0.25))),
        ]),

        const SizedBox(height: 18),

        Row(children: [
          _heroTile(
            label: 'TOTAL BIDS',
            value: '${r.totalBidsReceived}',
            icon: Icons.gavel_rounded,
            color: const Color(0xFFD4A017),
            flex: 1,
          ),
          const SizedBox(width: 10),
          _heroTile(
            label: 'TOTAL AMOUNT',
            value: r.fmtTotalBidAmount,
            icon: Icons.payments_outlined,
            color: const Color(0xFF2DB144),
            flex: 2,
          ),
        ]),

        const SizedBox(height: 10),

        Row(children: [
          _heroTile(
            label: 'ALLOCATED',
            value: r.fmtTotalAllocated,
            icon: Icons.pie_chart_outline_rounded,
            color: Colors.blueAccent,
            flex: 2,
          ),
          const SizedBox(width: 10),
          _heroTile(
            label: 'BID-TO-COVER',
            value: r.fmtBidToCoverRatio,
            icon: Icons.show_chart_rounded,
            color: Colors.purpleAccent,
            flex: 1,
          ),
        ]),

        const SizedBox(height: 22),

        _sectionHeader('PRICE RANGE ANALYSIS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _priceLabel('LOW', r.fmtLowestBidPrice, Colors.redAccent),
              _priceLabel('HIGH', r.fmtHighestBidPrice, const Color(0xFF2DB144),
                  alignRight: true),
            ]),
            const SizedBox(height: 10),

            LayoutBuilder(builder: (ctx, box) {
              final w = box.maxWidth;
              return Stack(clipBehavior: Clip.none, children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: w * cutoffFraction,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2DB144), Color(0xFFD4A017)]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Positioned(
                  left: (w * avgFraction) - 1,
                  top: -4,
                  child: Container(
                    width: 2, height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Positioned(
                  left: (w * cutoffFraction) - 7,
                  top: -6,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A017),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFFD4A017).withOpacity(0.5),
                          blurRadius: 6)],
                    ),
                  ),
                ),
              ]);
            }),
            const SizedBox(height: 16),
            Row(children: [
              _legendDot(const Color(0xFF2DB144)), const SizedBox(width: 5),
              Text('Fill', style: _legendStyle()),
              const SizedBox(width: 14),
              _legendDot(Colors.blueAccent), const SizedBox(width: 5),
              Text('Avg ${r.fmtAverageBidPrice}', style: _legendStyle()),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFFD4A017)), const SizedBox(width: 5),
              Text('Cutoff ${r.fmtCutoffPrice}', style: _legendStyle()),
            ]),

            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.07), height: 1),
            const SizedBox(height: 14),

            Row(children: [
              _priceColumn('AVERAGE', r.fmtAverageBidPrice, Colors.blueAccent),
              _priceColDivider(),
              _priceColumn('CUTOFF', r.fmtCutoffPrice, const Color(0xFFD4A017)),
              _priceColDivider(),
              _priceColumn('UNIFORM', r.fmtUniformPrice, Colors.purpleAccent),
            ]),
          ]),
        ),

        const SizedBox(height: 22),

        _sectionHeader('ALLOCATION'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statBox('Allocation Ratio', r.fmtAllocationRatio,
              const Color(0xFFD4A017))),
          const SizedBox(width: 10),
          Expanded(child: _statBox('Bid-to-Cover', r.fmtBidToCoverRatio,
              Colors.purpleAccent)),
        ]),

        const SizedBox(height: 22),

        _sectionHeader('SETTLEMENT'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: r.settlementCompleted
                ? const Color(0xFF0A2F12)
                : const Color(0xFF1C1200),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: r.settlementCompleted
                  ? const Color(0xFF2DB144).withOpacity(0.4)
                  : Colors.orange.withOpacity(0.35),
            ),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: r.settlementCompleted
                    ? const Color(0xFF2DB144).withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                r.settlementCompleted
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
                size: 22,
                color: r.settlementCompleted
                    ? const Color(0xFF2DB144)
                    : Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.settlementCompleted
                      ? 'Settlement Complete'
                      : 'Settlement Pending',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900,
                    color: r.settlementCompleted
                        ? const Color(0xFF2DB144)
                        : Colors.orange,
                  ),
                ),
                if (r.settlementDate != null) ...[
                  const SizedBox(height: 3),
                  Text(_fmtDt(r.settlementDate!),
                      style: TextStyle(fontSize: 12,
                          color: Colors.white.withOpacity(0.4))),
                ] else ...[
                  const SizedBox(height: 3),
                  Text('Date not yet confirmed',
                      style: TextStyle(fontSize: 12,
                          color: Colors.white.withOpacity(0.3))),
                ],
              ],
            )),
          ]),
        ),
      ],
    );
  }

  Widget _heroTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.7), letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String label) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(
            color: const Color(0xFF2DB144),
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11,
        fontWeight: FontWeight.w800, letterSpacing: 0.8)),
  ]);

  Widget _priceLabel(String label, String value, Color color,
      {bool alignRight = false}) =>
      Column(crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: color.withOpacity(0.7), letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                color: color)),
          ]);

  Widget _legendDot(Color c) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  TextStyle _legendStyle() =>
      TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w600);

  Widget _priceColumn(String label, String value, Color color) =>
      Expanded(child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.4), letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
            color: color), textAlign: TextAlign.center),
      ]));

  Widget _priceColDivider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.06),
          margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _statBox(String label, String value, Color accent) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent.withOpacity(0.2)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: accent.withOpacity(0.7), letterSpacing: 0.4)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
          color: Colors.white)),
    ]),
  );

  static String _fmtDt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour.toString().padLeft(2,'0');
      final m = dt.minute.toString().padLeft(2,'0');
      return '${dt.day} ${months[dt.month-1]} ${dt.year} $h:$m';
    } catch (_) { return iso; }
  }

  Widget _detailCard({
    required String title,
    required List<Widget> rows,
    Widget? extra,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: Color(0xFFD4A017), fontSize: 11,
                  fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 10),
          ...rows,
          if (extra != null) extra,
        ]),
      );

  Widget _detailRow(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label,
                style: TextStyle(fontSize: 11,
                    color: Colors.white.withOpacity(0.45)))),
            const SizedBox(width: 6),
            Flexible(child: Text(value, textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.white))),
          ],
        ),
      );

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
              color: color, letterSpacing: 0.5)),
    );
  }
}