import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL BID RECORD  (persisted in SharedPreferences)
// ─────────────────────────────────────────────────────────────────────────────

/// Lightweight record saved locally after every successful bid submission.
class PlacedBidRecord {
  final int?   bidId;        // server-assigned ID (null when server omits it)
  final double bidPrice;
  final int    bidQuantity;
  final String submittedAt; // ISO-8601

  PlacedBidRecord({
    this.bidId,
    required this.bidPrice,
    required this.bidQuantity,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'bidId':       bidId,
    'bidPrice':    bidPrice,
    'bidQuantity': bidQuantity,
    'submittedAt': submittedAt,
  };

  factory PlacedBidRecord.fromJson(Map<String, dynamic> j) => PlacedBidRecord(
    bidId:       j['bidId'] as int?,
    bidPrice:    (j['bidPrice'] as num).toDouble(),
    bidQuantity: j['bidQuantity'] as int,
    submittedAt: j['submittedAt'] as String,
  );

  String get formattedPrice    => '\$${bidPrice.toStringAsFixed(2)}';
  String get formattedQuantity => bidQuantity.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// BID STORE  (SharedPreferences helper)
// Key pattern: "bid_<auctionId>"
// ─────────────────────────────────────────────────────────────────────────────
class BidStore {
  static String _key(int auctionId) => 'bid_$auctionId';

  static Future<void> save(int auctionId, PlacedBidRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(auctionId), jsonEncode(record.toJson()));
  }

  static Future<PlacedBidRecord?> load(int auctionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key(auctionId));
    if (raw == null) return null;
    try {
      return PlacedBidRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  static Future<Set<int>> loadAllAuctionIds() async {
    final prefs  = await SharedPreferences.getInstance();
    final result = <int>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('bid_')) {
        final id = int.tryParse(key.substring(4));
        if (id != null) result.add(id);
      }
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
class AuctionModel {
  final int    auctionId;
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
  final DateTime startDateRaw;
  final DateTime endDateRaw;
  final String? settlementDate;
  final String  status;
  final String  allocationMethod;
  final String? description;
  final double? couponRate;
  final String? maturityDate;
  final double? minimumYield;
  final double? maximumYield;
  final bool    isCommodityAuction;
  final double? reservePrice;
  final String? lotNumber;
  final String? lastBidTime;
  final double? currentHighestBid;
  final String? currentHighestBidderCode;
  final String? currentHighestBidderName;
  final int     totalExtensions;

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
    DateTime ps; try { ps = DateTime.parse(rawStart); } catch (_) { ps = DateTime.now(); }
    DateTime pe; try { pe = DateTime.parse(rawEnd);   } catch (_) { pe = DateTime.now(); }

    return AuctionModel(
      auctionId:    json['auctionId'] as int,
      auctionCode:  json['auctionCode'] as String,
      auctionTitle: json['auctionTitle'] as String,
      auctionType:  json['auctionType'] as String,
      securityType: json['securityType'] as String?,
      issuerName:   json['issuerName']   as String?,
      totalVolume:  (json['totalVolume'] as num).toDouble(),
      minBidAmount: (json['minBidAmount'] as num).toDouble(),
      maxBidAmount: (json['maxBidAmount'] as num).toDouble(),
      bidIncrement: (json['bidIncrement'] as num).toDouble(),
      startDate: _fmtDT(rawStart), endDate: _fmtDT(rawEnd),
      startDateRaw: ps, endDateRaw: pe,
      settlementDate: json['settlementDate'] != null
          ? _fmtD(json['settlementDate'] as String) : null,
      status:           json['status']           as String,
      allocationMethod: json['allocationMethod'] as String,
      description:      json['description']      as String?,
      couponRate: json['couponRate'] != null
          ? (json['couponRate'] as num).toDouble() : null,
      maturityDate: json['maturityDate'] != null
          ? _fmtD(json['maturityDate'] as String) : null,
      minimumYield: json['minimumYield'] != null
          ? (json['minimumYield'] as num).toDouble() : null,
      maximumYield: json['maximumYield'] != null
          ? (json['maximumYield'] as num).toDouble() : null,
      isCommodityAuction:       json['isCommodityAuction'] as bool? ?? false,
      reservePrice: json['reservePrice'] != null
          ? (json['reservePrice'] as num).toDouble() : null,
      lotNumber:                json['lotNumber']                as String?,
      lastBidTime: json['lastBidTime'] != null
          ? _fmtDT(json['lastBidTime'] as String) : null,
      currentHighestBid: json['currentHighestBid'] != null
          ? (json['currentHighestBid'] as num).toDouble() : null,
      currentHighestBidderCode: json['currentHighestBidderCode'] as String?,
      currentHighestBidderName: json['currentHighestBidderName'] as String?,
      totalExtensions:          json['totalExtensions'] as int? ?? 0,
    );
  }

  static String _fmtDT(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final m  = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year} '
          '${dt.hour.toString().padLeft(2,"0")}:'
          '${dt.minute.toString().padLeft(2,"0")}';
    } catch (_) { return iso; }
  }

  static String _fmtD(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final m  = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year}';
    } catch (_) { return iso; }
  }

  String get category => lotNumber != null
      ? '$auctionCode · Lot $lotNumber' : '$auctionCode · $auctionType';

  String get formattedTotalVolume => isCommodityAuction
      ? '${totalVolume.toStringAsFixed(0)} T' : '\$${_cmp(totalVolume)}';
  String get formattedMinBid       => '\$${_cmp(minBidAmount)}';
  String get formattedMaxBid       => '\$${_cmp(maxBidAmount)}';
  String get formattedBidIncrement => '\$${_cmp(bidIncrement)}';
  String get formattedCouponRate   =>
      couponRate != null ? '${couponRate!.toStringAsFixed(2)}%' : 'N/A';
  String get formattedReservePrice =>
      reservePrice != null ? '\$${reservePrice!.toStringAsFixed(2)}' : 'N/A';
  String get formattedHighestBid   => currentHighestBid != null
      ? '\$${currentHighestBid!.toStringAsFixed(2)}' : 'No bids yet';

  static String _cmp(double v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v/1000).toStringAsFixed(1)}K';
    return v%1==0 ? v.toInt().toString() : v.toStringAsFixed(2);
  }
}

// ── Auction Result Model ─────────────────────────────────────────────────────
class AuctionResultModel {
  final int    resultId, auctionId, totalBidsReceived;
  final double totalBidAmount, totalAllocated, averageBidPrice,
      highestBidPrice, lowestBidPrice, cutoffPrice,
      averageYield, highestYield, lowestYield,
      allocationRatio, bidToCoverRatio;
  final double? cutoffYield, uniformPrice;
  final bool    resultPublished, settlementCompleted;
  final String? publishedDate, settlementDate;

  AuctionResultModel({
    required this.resultId, required this.auctionId,
    required this.totalBidsReceived, required this.totalBidAmount,
    required this.totalAllocated, required this.averageBidPrice,
    required this.highestBidPrice, required this.lowestBidPrice,
    required this.cutoffPrice, required this.averageYield,
    required this.highestYield, required this.lowestYield,
    this.cutoffYield, required this.allocationRatio,
    required this.bidToCoverRatio, this.uniformPrice,
    required this.resultPublished, this.publishedDate,
    required this.settlementCompleted, this.settlementDate,
  });

  factory AuctionResultModel.fromJson(Map<String, dynamic> j) =>
      AuctionResultModel(
        resultId:            j['resultId']          as int,
        auctionId:           j['auctionId']         as int,
        totalBidsReceived:   j['totalBidsReceived'] as int,
        totalBidAmount:      (j['totalBidAmount']   as num).toDouble(),
        totalAllocated:      (j['totalAllocated']   as num).toDouble(),
        averageBidPrice:     (j['averageBidPrice']  as num).toDouble(),
        highestBidPrice:     (j['highestBidPrice']  as num).toDouble(),
        lowestBidPrice:      (j['lowestBidPrice']   as num).toDouble(),
        cutoffPrice:         (j['cutoffPrice']      as num).toDouble(),
        averageYield:        (j['averageYield']     as num).toDouble(),
        highestYield:        (j['highestYield']     as num).toDouble(),
        lowestYield:         (j['lowestYield']      as num).toDouble(),
        cutoffYield:  j['cutoffYield']  != null ? (j['cutoffYield']  as num).toDouble() : null,
        allocationRatio:     (j['allocationRatio']  as num).toDouble(),
        bidToCoverRatio:     (j['bidToCoverRatio']  as num).toDouble(),
        uniformPrice: j['uniformPrice'] != null ? (j['uniformPrice'] as num).toDouble() : null,
        resultPublished:     j['resultPublished']     as bool? ?? false,
        publishedDate:       j['publishedDate']       as String?,
        settlementCompleted: j['settlementCompleted'] as bool? ?? false,
        settlementDate:      j['settlementDate']      as String?,
      );

  static String _f(double v) =>
      v >= 1e6 ? '\$${(v/1e6).toStringAsFixed(2)}M'
          : v >= 1e3 ? '\$${(v/1e3).toStringAsFixed(2)}K'
          : '\$${v.toStringAsFixed(2)}';

  String get fmtTotalBidAmount  => _f(totalBidAmount);
  String get fmtTotalAllocated  => _f(totalAllocated);
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
  static const _base = 'https://ussd.zmx.co.zw';

  static Future<List<AuctionModel>> fetchAll() async {
    final res = await http.get(Uri.parse('$_base/v1/auction/all'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => AuctionModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load auctions (${res.statusCode})');
  }

  static Future<AuctionResultModel?> fetchResults(int auctionId) async {
    final res = await http.get(Uri.parse('$_base/v1/auction/$auctionId/results'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body == 'null' || body.isEmpty) return null;
      return AuctionResultModel.fromJson(jsonDecode(body));
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to load results (${res.statusCode})');
  }

  /// POST a new bid. Returns the server-assigned bidId when the response includes one.
  static Future<int?> placeBid({
    required String? lotNumber,
    required double  bidPrice,
    required int     bidQuantity,
    required String  clientCode,
    required String  clientName,
  }) async {
    final body = <String, dynamic>{
      'bidPrice': bidPrice, 'bidQuantity': bidQuantity,
      'clientCode': clientCode, 'clientName': clientName,
      'submittedBy': 'mobile',
      if (lotNumber != null) 'lotNumber': lotNumber,
    };
    final res = await http.post(
      Uri.parse('$_base/v1/auction/bids'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to place bid (${res.statusCode}): ${res.body}');
    }
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        return (decoded['bidId'] ?? decoded['id'] ?? decoded['bid_id']) as int?;
      }
      if (decoded is int) return decoded;
    } catch (_) {}
    return null;
  }

  /// PUT an update to an existing bid.
  static Future<void> editBid({
    required int?    bidId,
    required String? lotNumber,
    required double  bidPrice,
    required int     bidQuantity,
    required String  clientCode,
    required String  clientName,
  }) async {
    final path = bidId != null
        ? '$_base/v1/auction/bids/$bidId' : '$_base/v1/auction/bids';
    final body = <String, dynamic>{
      'bidPrice': bidPrice, 'bidQuantity': bidQuantity,
      'clientCode': clientCode, 'clientName': clientName,
      'submittedBy': 'mobile',
      if (lotNumber != null) 'lotNumber': lotNumber,
      if (bidId != null)     'bidId':     bidId,
    };
    final res = await http.put(
      Uri.parse(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to update bid (${res.statusCode}): ${res.body}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNTDOWN WIDGET
// ─────────────────────────────────────────────────────────────────────────────
enum _CMode { pending, active, ended }

class _AuctionCountdown extends StatefulWidget {
  final AuctionModel auction;
  const _AuctionCountdown({required this.auction});
  @override State<_AuctionCountdown> createState() => _AuctionCountdownState();
}

class _AuctionCountdownState extends State<_AuctionCountdown> {
  late Timer    _timer;
  late Duration _remaining;
  late _CMode   _mode;

  @override
  void initState() {
    super.initState();
    _compute();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) { if (mounted) setState(_compute); });
  }

  void _compute() {
    final now = DateTime.now();
    if (now.isBefore(widget.auction.startDateRaw)) {
      _mode = _CMode.pending;
      _remaining = widget.auction.startDateRaw.difference(now);
    } else if (now.isBefore(widget.auction.endDateRaw)) {
      _mode = _CMode.active;
      _remaining = widget.auction.endDateRaw.difference(now);
    } else {
      _mode = _CMode.ended; _remaining = Duration.zero;
    }
  }

  @override void dispose() { _timer.cancel(); super.dispose(); }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Color get _color => _mode == _CMode.active ? const Color(0xFF2DB144)
      : _mode == _CMode.pending ? const Color(0xFFD4A017)
      : Colors.redAccent;

  String get _label => _mode == _CMode.active ? 'Ends in'
      : _mode == _CMode.pending ? 'Starts in' : 'Ended';

  IconData get _icon => _mode == _CMode.active ? Icons.timer_outlined
      : _mode == _CMode.pending ? Icons.schedule_rounded
      : Icons.timer_off_outlined;

  String get _timeStr {
    if (_mode == _CMode.ended) return '--:--:--';
    final d = _remaining.inDays;
    final h = _pad(_remaining.inHours.remainder(24));
    final m = _pad(_remaining.inMinutes.remainder(60));
    final s = _pad(_remaining.inSeconds.remainder(60));
    return d > 0 ? '${d}d $h:$m:$s' : '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.28)),
      ),
      child: Row(children: [
        Icon(_icon, size: 15, color: c),
        const SizedBox(width: 7),
        Text(_label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: c.withOpacity(0.75))),
        const Spacer(),
        Text(_timeStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
            color: c, letterSpacing: 0.5,
            fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUCTION CONTENT  (main list)
// ─────────────────────────────────────────────────────────────────────────────
class AuctionContent extends StatefulWidget {
  const AuctionContent({super.key});
  @override State<AuctionContent> createState() => _AuctionContentState();
}

class _AuctionContentState extends State<AuctionContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fc;
  late Animation<double>   _fa;

  List<AuctionModel> _auctions  = [];
  Set<int>           _biddedIds = {};   // auctionIds with a placed bid
  bool               _loading   = true;
  String?            _error;
  String             _filter    = 'ALL';
  final _filters = ['ALL', 'ACTIVE', 'PENDING', 'CLOSED'];

  List<AuctionModel> get _filtered => _filter == 'ALL'
      ? _auctions : _auctions.where((a) => a.status == _filter).toList();

  @override
  void initState() {
    super.initState();
    _fc = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fa = CurvedAnimation(parent: _fc, curve: Curves.easeInOut);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        AuctionService.fetchAll(),
        BidStore.loadAllAuctionIds(),
      ]);
      if (mounted) {
        setState(() {
          _auctions  = res[0] as List<AuctionModel>;
          _biddedIds = res[1] as Set<int>;
          _loading   = false;
        });
        _fc.forward(from: 0);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override void dispose() { _fc.dispose(); super.dispose(); }

  /// Opens bid sheet then refreshes the bidded-IDs so the card button updates.
  void _openBidSheet(AuctionModel auction) async {
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlaceBidSheet(auction: auction),
    );
    if (mounted) {
      final ids = await BidStore.loadAllAuctionIds();
      setState(() => _biddedIds = ids);
    }
  }

  void _showDetails(AuctionModel a) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => _AuctionDetailsScreen(auction: a)));

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    return FadeTransition(
      opacity: _fa,
      child: ListView(
        padding: EdgeInsets.only(
            top: 4, bottom: MediaQuery.of(context).padding.bottom + 100),
        children: [
          _buildHeader(), _buildFilterBar(),
          if (_filtered.isEmpty) _buildEmpty(),
          ..._filtered.asMap().entries.map((e) => _buildCard(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    CircularProgressIndicator(color: Color(0xFF2DB144)), SizedBox(height: 16),
    Text('Loading auctions...', style: TextStyle(color: Colors.grey, fontSize: 14)),
  ]));

  Widget _buildError() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.redAccent),
      const SizedBox(height: 16),
      const Text('Failed to load auctions', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      const SizedBox(height: 8),
      Text(_error ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GestureDetector(onTap: _load, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
            borderRadius: BorderRadius.circular(12)),
        child: const Text('Retry', style: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      )),
    ]),
  ));

  Widget _buildEmpty() => const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Icon(Icons.gavel_rounded, size: 48, color: Colors.grey), SizedBox(height: 12),
        Text('No auctions found', style: TextStyle(
            color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600)),
      ]));

  Widget _buildHeader() {
    final active = _auctions.where((a) => a.status == 'ACTIVE').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Auction', style: TextStyle(
            fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFF2DB144).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2DB144).withOpacity(0.35))),
            child: Text('$active Active', style: const TextStyle(
                color: Color(0xFF2DB144), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          GestureDetector(onTap: _load, child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200)),
            child: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1A1A1A)),
          )),
        ]),
      ]),
    );
  }

  Widget _buildFilterBar() => SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final f   = _filters[i];
        final sel = _filter == f;
        final cnt = f == 'ALL' ? _auctions.length
            : _auctions.where((a) => a.status == f).length;
        return GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(
                    colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]) : null,
                color: sel ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: sel ? const Color(0xFF2DB144) : Colors.grey.shade300)),
            child: Text('$f ($cnt)', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : Colors.grey.shade600)),
          ),
        );
      },
    ),
  );

  Color _statusColor(String s) => s == 'ACTIVE'
      ? const Color(0xFF2DB144) : s == 'PENDING'
      ? const Color(0xFFD4A017) : s == 'CLOSED'
      ? Colors.redAccent : Colors.grey;

  Widget _buildCard(AuctionModel a, int idx) {
    final isActive     = a.status == 'ACTIVE';
    final isClosed     = a.status == 'CLOSED';
    final sc           = _statusColor(a.status);
    final hasPlacedBid = _biddedIds.contains(a.auctionId);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + idx * 80),
      curve: Curves.easeOut,
      builder: (ctx, v, child) => Opacity(opacity: v,
          child: Transform.translate(offset: Offset(0, 20*(1-v)), child: child)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sc.withOpacity(0.25), width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(a.category, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: Color(0xFFD4A017), letterSpacing: 0.5))),
              const SizedBox(width: 8),
              // "BID PLACED" chip
              if (hasPlacedBid && isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.4))),
                  child: const Row(children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 10, color: Colors.blueAccent),
                    SizedBox(width: 3),
                    Text('BID PLACED', style: TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w800, color: Colors.blueAccent,
                        letterSpacing: 0.4)),
                  ]),
                ),
                const SizedBox(width: 6),
              ],
              _statusBadge(a.status),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Text(a.auctionTitle, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          ),
          if (a.description != null)
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(a.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)))
          else const SizedBox(height: 10),

          // ── Countdown ────────────────────────────────────────────────────
          _AuctionCountdown(auction: a),
          const SizedBox(height: 10),

          // ── Stats ────────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _statItem('VOLUME', a.formattedTotalVolume), _statDiv(),
              _statItem('MIN BID', a.formattedMinBid), _statDiv(),
              _statItem('MAX BID', a.formattedMaxBid), _statDiv(),
              _statItem(a.isCommodityAuction ? 'RESERVE' : 'COUPON',
                  a.isCommodityAuction ? a.formattedReservePrice : a.formattedCouponRate),
            ]),
          ),

          // ── Highest bid (name hidden) ────────────────────────────────────
          if (a.isCommodityAuction && a.currentHighestBid != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2DB144).withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.trending_up_rounded, size: 16,
                      color: Color(0xFF2DB144)),
                  const SizedBox(width: 8),
                  Text('Highest Bid: ${a.formattedHighestBid}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          color: Color(0xFF2DB144))),
                ]),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('BID RANGE', style: TextStyle(fontSize: 10,
                  color: Colors.grey.shade500, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
              Text('${a.formattedMinBid} – ${a.formattedMaxBid}  ·  +${a.formattedBidIncrement} step',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFD4A017),
                      fontWeight: FontWeight.w700)),
            ]),
          ),

          const SizedBox(height: 12),

          // ── Action buttons ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              const Spacer(),
              if (isClosed) ...[
                GestureDetector(onTap: () => _showDetails(a), child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5)),
                  child: const Text('Results', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                )),
                const SizedBox(width: 8),
              ],
              GestureDetector(onTap: () => _showDetails(a), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFD4A017).withOpacity(0.5), width: 1.5)),
                child: const Text('Details', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD4A017))),
              )),
              const SizedBox(width: 10),

              // PLACE BID / EDIT BID button
              GestureDetector(
                onTap: isActive ? () => _openBidSheet(a) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isActive && !hasPlacedBid
                        ? const LinearGradient(
                        colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]) : null,
                    color: isActive && hasPlacedBid
                        ? Colors.blueAccent.withOpacity(0.10)
                        : (!isActive ? Colors.grey.shade300 : null),
                    borderRadius: BorderRadius.circular(10),
                    border: isActive && hasPlacedBid
                        ? Border.all(color: Colors.blueAccent.withOpacity(0.6), width: 1.5) : null,
                    boxShadow: isActive && !hasPlacedBid ? [BoxShadow(
                        color: const Color(0xFF2DB144).withOpacity(0.35),
                        blurRadius: 8, offset: const Offset(0, 3))] : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isActive && hasPlacedBid) ...[
                      const Icon(Icons.edit_rounded, size: 13, color: Colors.blueAccent),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      isActive ? (hasPlacedBid ? 'EDIT BID' : 'PLACE BID') : 'PLACE BID',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isActive
                              ? (hasPlacedBid ? Colors.blueAccent : Colors.white)
                              : Colors.grey.shade500),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String s) {
    final c = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.withOpacity(0.4))),
      child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
          color: c, letterSpacing: 0.5)),
    );
  }

  Widget _statItem(String l, String v) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: TextStyle(fontSize: 9, color: Colors.grey.shade500,
        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
        color: Color(0xFF1A1A1A))),
  ]);

  Widget _statDiv() => Container(width: 1, height: 28, color: Colors.grey.shade300);
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACE / EDIT BID BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceBidSheet extends StatefulWidget {
  final AuctionModel auction;
  const _PlaceBidSheet({required this.auction});
  @override State<_PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends State<_PlaceBidSheet> {
  bool             _loading      = true;
  bool             _submitting   = false;
  bool             _success      = false;
  String?          _error;
  PlacedBidRecord? _existing;
  bool get         _editMode     => _existing != null;

  final _priceCtrl = TextEditingController();
  final _qtyCtrl   = TextEditingController();
  String _clientCode = 'DEFAULT';
  String _clientName = 'Default Client';

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final prefs    = await SharedPreferences.getInstance();
    final existing = await BidStore.load(widget.auction.auctionId);
    if (!mounted) return;
    setState(() {
      _clientCode = prefs.getString('user_cds')  ?? 'DEFAULT';
      _clientName = prefs.getString('user_name') ?? 'Default Client';
      _existing   = existing;
      if (existing != null) {
        _priceCtrl.text = existing.bidPrice.toStringAsFixed(2);
        _qtyCtrl.text   = existing.bidQuantity.toString();
      }
      _loading = false;
    });
  }

  @override
  void dispose() { _priceCtrl.dispose(); _qtyCtrl.dispose(); super.dispose(); }

  double get _price  => double.tryParse(_priceCtrl.text) ?? 0;
  double get _qty    => double.tryParse(_qtyCtrl.text)   ?? 0;
  double get _amount => (_price > 0 && _qty > 0) ? _price * _qty : 0;
  String get _dispAmt =>
      _amount > 0 ? '\$${_amount.toStringAsFixed(2)}' : 'Auto-calculated';

  Future<void> _submit() async {
    if (_price <= 0) { setState(() => _error = 'Enter a valid bid price.'); return; }
    if (_qty   <= 0) { setState(() => _error = 'Enter a valid quantity.');  return; }
    setState(() { _submitting = true; _error = null; });
    try {
      if (_editMode) {
        await AuctionService.editBid(
          bidId: _existing!.bidId, lotNumber: widget.auction.lotNumber,
          bidPrice: _price, bidQuantity: _qty.toInt(),
          clientCode: _clientCode, clientName: _clientName,
        );
        await BidStore.save(widget.auction.auctionId, PlacedBidRecord(
          bidId: _existing!.bidId, bidPrice: _price, bidQuantity: _qty.toInt(),
          submittedAt: DateTime.now().toIso8601String(),
        ));
      } else {
        final bidId = await AuctionService.placeBid(
          lotNumber: widget.auction.lotNumber, bidPrice: _price,
          bidQuantity: _qty.toInt(), clientCode: _clientCode, clientName: _clientName,
        );
        await BidStore.save(widget.auction.auctionId, PlacedBidRecord(
          bidId: bidId, bidPrice: _price, bidQuantity: _qty.toInt(),
          submittedAt: DateTime.now().toIso8601String(),
        ));
      }
      if (mounted) setState(() { _submitting = false; _success = true; });
    } catch (e) {
      if (mounted) setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8, left: 20, right: 20),
    child: SingleChildScrollView(
      child: _loading ? _sheetLoading()
          : _success  ? _buildSuccess()
          : _buildForm(),
    ),
  );

  Widget _sheetLoading() => SizedBox(height: 180, child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    _handle(), const SizedBox(height: 28),
    const CircularProgressIndicator(color: Color(0xFF2DB144), strokeWidth: 2),
  ]));

  Widget _buildSuccess() => Column(mainAxisSize: MainAxisSize.min, children: [
    _handle(), const SizedBox(height: 30),
    Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: _editMode
                ? [Colors.blueAccent, Colors.blue.shade700]
                : [const Color(0xFF2DB144), const Color(0xFF1E8E32)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
                color: (_editMode ? Colors.blueAccent : const Color(0xFF2DB144)).withOpacity(0.4),
                blurRadius: 20)]),
        child: Icon(_editMode ? Icons.edit_rounded : Icons.check_rounded,
            color: Colors.white, size: 34)),
    const SizedBox(height: 20),
    Text(_editMode ? 'Bid Updated!' : 'Bid Submitted!',
        style: const TextStyle(color: Colors.white, fontSize: 24,
            fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    Text(
        _editMode
            ? 'Your bid has been updated for\n${widget.auction.auctionTitle}'
            : 'Your bid has been placed for\n${widget.auction.auctionTitle}',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14, height: 1.5)),
    const SizedBox(height: 30),
    GestureDetector(onTap: () => Navigator.pop(context), child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: _editMode
              ? [Colors.blueAccent, Colors.blue.shade700]
              : [const Color(0xFF2DB144), const Color(0xFF1E8E32)]),
          borderRadius: BorderRadius.circular(14)),
      child: const Text('Done', textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
    )),
    const SizedBox(height: 8),
  ]);

  Widget _buildForm() {
    final a = widget.auction;
    final isActive = a.status == 'ACTIVE';
    final titleColor = _editMode ? Colors.blueAccent : const Color(0xFFD4A017);

    return Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [

          _handle(),

          // Title + edit badge
          Row(children: [
            Text(_editMode ? 'Edit Bid' : 'Place Bid',
                style: TextStyle(color: titleColor, fontSize: 22,
                    fontWeight: FontWeight.w900)),
            if (_editMode) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4))),
                child: const Text('UPDATING EXISTING BID', style: TextStyle(fontSize: 9,
                    fontWeight: FontWeight.w800, color: Colors.blueAccent, letterSpacing: 0.5)),
              ),
            ],
          ]),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 14),

          // Previous bid summary (edit only)
          if (_editMode) ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.history_rounded, size: 13, color: Colors.blueAccent),
                  const SizedBox(width: 6),
                  const Text('YOUR PREVIOUS BID', style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w800, color: Colors.blueAccent, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _prevStat('PRICE', _existing!.formattedPrice)),
                  Container(width: 1, height: 28,
                      color: Colors.white.withOpacity(0.08),
                      margin: const EdgeInsets.symmetric(horizontal: 12)),
                  Expanded(child: _prevStat('QUANTITY', _existing!.formattedQuantity)),
                ]),
              ]),
            ),
          ],

          // Auction info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.auctionCode, style: const TextStyle(color: Color(0xFFD4A017),
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(a.auctionTitle, style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Min: ${a.formattedMinBid}  |  Max: ${a.formattedMaxBid}  |  Step: ${a.formattedBidIncrement}',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
              if (a.isCommodityAuction && a.reservePrice != null) ...[
                const SizedBox(height: 4),
                Text('Reserve: ${a.formattedReservePrice}  |  Volume: ${a.formattedTotalVolume}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
              ],
              if (a.lotNumber != null) ...[
                const SizedBox(height: 4),
                Text('Lot: ${a.lotNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.55))),
              ],
              if (a.currentHighestBid != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFF2DB144).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2DB144).withOpacity(0.35))),
                  child: Text('Current Highest: ${a.formattedHighestBid}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                          color: Color(0xFF2DB144))),
                ),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // Client code (name hidden)
          _secLabel('CLIENT'), const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: _infoRow('Client Code', _clientCode),
          ),

          const SizedBox(height: 18),
          _secLabel('BID PRICE'), const SizedBox(height: 8),
          _field(controller: _priceCtrl, hint: 'Enter bid price',
              type: const TextInputType.numberWithOptions(decimal: true),
              onChange: (_) => setState(() {})),

          const SizedBox(height: 18),
          _secLabel(a.isCommodityAuction ? 'QUANTITY (TONNES)' : 'QUANTITY'),
          const SizedBox(height: 8),
          _field(controller: _qtyCtrl, hint: 'Enter quantity',
              type: TextInputType.number, onChange: (_) => setState(() {})),

          const SizedBox(height: 18),
          _secLabel('BID AMOUNT'), const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Text(_dispAmt, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                color: _amount > 0 ? const Color(0xFF2DB144) : Colors.white38)),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!, style: const TextStyle(
                    color: Colors.redAccent, fontSize: 13))),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          // Buttons
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.15))),
                  child: const Text('Cancel', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ))),
            const SizedBox(width: 12),
            Expanded(flex: 2,
                child: GestureDetector(
                  onTap: (isActive && !_submitting) ? _submit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                        gradient: isActive ? LinearGradient(colors: _editMode
                            ? [Colors.blueAccent, Colors.blue.shade700]
                            : [const Color(0xFF2DB144), const Color(0xFF1E8E32)]) : null,
                        color: isActive ? null : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isActive ? [BoxShadow(
                            color: (_editMode ? Colors.blueAccent : const Color(0xFF2DB144))
                                .withOpacity(0.4),
                            blurRadius: 12, offset: const Offset(0, 4))] : []),
                    child: _submitting
                        ? const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (_editMode) ...[
                        const Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                      ],
                      Text(_editMode ? 'Update Bid' : 'Submit Bid',
                          style: const TextStyle(color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ]),
                  ),
                )),
          ]),
        ]);
  }

  Widget _handle() => Center(child: Container(
      width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2))));

  Widget _prevStat(String l, String v) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: Colors.blueAccent.withOpacity(0.65), letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
            color: Colors.white)),
      ]);

  Widget _infoRow(String l, String v) => Row(children: [
    Text('$l:', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45))),
    const SizedBox(width: 8),
    Expanded(child: Text(v.isNotEmpty ? v : '—', overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
            color: Colors.white))),
  ]);

  Widget _secLabel(String l) => Text(l, style: const TextStyle(
      color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0));

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
    ValueChanged<String>? onChange,
  }) => Container(
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1))),
    child: TextField(
      controller: controller, keyboardType: type, onChanged: onChange,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
          hintText: hint, border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AUCTION DETAILS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _AuctionDetailsScreen extends StatefulWidget {
  final AuctionModel auction;
  const _AuctionDetailsScreen({required this.auction});
  @override State<_AuctionDetailsScreen> createState() =>
      _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<_AuctionDetailsScreen>
    with SingleTickerProviderStateMixin {
  AuctionResultModel? _result;
  bool    _loadingResult = false;
  String? _resultError;
  late TabController _tab;

  bool get _isClosed => widget.auction.status == 'CLOSED';
  bool get _isActive => widget.auction.status == 'ACTIVE';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _isClosed ? 2 : 1, vsync: this);
    if (_isClosed) _loadResults();
  }

  @override void dispose() { _tab.dispose(); super.dispose(); }

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

  Color _sc(String s) => s == 'ACTIVE' ? const Color(0xFF2DB144)
      : s == 'PENDING' ? const Color(0xFFD4A017)
      : s == 'CLOSED'  ? Colors.redAccent : Colors.grey;

  @override
  Widget build(BuildContext context) {
    final a = widget.auction;
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18))),
            const SizedBox(width: 14),
            Expanded(child: Text(a.auctionTitle, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w900))),
            const SizedBox(width: 8),
            _statusBadge(a.status),
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
                  border: Border.all(color: Colors.white.withOpacity(0.08))),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF1A6B2A), Color(0xFF0F4D1D)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFF2DB144).withOpacity(0.3), blurRadius: 8)]),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    letterSpacing: 0.3),
                tabs: const [Tab(text: 'Information'), Tab(text: 'Results')],
              ),
            ),
          ),
        ] else const SizedBox(height: 14),

        Expanded(child: _isClosed
            ? TabBarView(controller: _tab, children: [
          _buildInfoTab(a), _buildResultsTab()])
            : _buildInfoTab(a)),
      ])),
    );
  }

  Widget _buildInfoTab(AuctionModel a) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _card('AUCTION INFORMATION', [
          _row('Code', a.auctionCode), _row('Type', a.auctionType),
          if (a.lotNumber    != null) _row('Lot',      a.lotNumber!),
          if (a.securityType != null) _row('Security', a.securityType!),
          if (a.issuerName   != null) _row('Issuer',   a.issuerName!),
          _row('Allocation', a.allocationMethod),
          _row('Status', a.status, vc: _sc(a.status)),
        ])),
        const SizedBox(width: 12),
        Expanded(child: _card('VOLUME & PRICING', [
          _row('Total Volume', a.formattedTotalVolume),
          _row('Min Bid', a.formattedMinBid),
          _row('Max Bid', a.formattedMaxBid),
          _row('Bid Step', a.formattedBidIncrement),
          if (a.isCommodityAuction) ...[
            _row('Reserve Price', a.formattedReservePrice),
            _row('Highest Bid', a.formattedHighestBid,
                vc: a.currentHighestBid != null ? const Color(0xFF2DB144) : null),
            _row('Extensions', '${a.totalExtensions}'),
          ] else ...[
            _row('Coupon Rate', a.formattedCouponRate),
            if (a.minimumYield != null)
              _row('Min Yield', '${a.minimumYield!.toStringAsFixed(2)}%'),
            if (a.maximumYield != null)
              _row('Max Yield', '${a.maximumYield!.toStringAsFixed(2)}%'),
          ],
        ])),
      ]),
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _card('TIMELINE', [
          _row('Start', a.startDate), _row('End', a.endDate),
          if (a.settlementDate != null) _row('Settlement', a.settlementDate!),
          if (a.maturityDate   != null) _row('Maturity',   a.maturityDate!),
          if (a.lastBidTime    != null) _row('Last Bid',   a.lastBidTime!),
        ])),
        const SizedBox(width: 12),
        Expanded(child: _card('DESCRIPTION', [],
            extra: Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(
                    a.description?.isNotEmpty == true
                        ? a.description! : 'No description available.',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white.withOpacity(0.6), height: 1.5))))),
      ]),
      const SizedBox(height: 20),
      if (_isActive)
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            showModalBottomSheet(context: context, isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _PlaceBidSheet(auction: a));
          },
          child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF2DB144).withOpacity(0.4),
                      blurRadius: 14, offset: const Offset(0, 6))]),
              child: const Text('PLACE BID', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w900, letterSpacing: 1))),
        ),
    ],
  );

  Widget _buildResultsTab() {
    if (_loadingResult) return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: Color(0xFF2DB144), strokeWidth: 2),
      SizedBox(height: 16),
      Text('Fetching results...', style: TextStyle(color: Colors.white38, fontSize: 14)),
    ]));

    if (_resultError != null) return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.signal_wifi_off_rounded, color: Colors.redAccent, size: 44),
          const SizedBox(height: 16),
          const Text('Could not load results', style: TextStyle(color: Colors.white,
              fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(_resultError!, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          const SizedBox(height: 24),
          GestureDetector(onTap: _loadResults, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('Try Again', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)))),
        ])));

    if (_result == null) return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: const Icon(Icons.hourglass_top_rounded, color: Colors.white38, size: 28)),
      const SizedBox(height: 16),
      const Text('Results not yet published', style: TextStyle(color: Colors.white54,
          fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('Check back later',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
    ]));

    final r = _result!;
    final pr  = r.highestBidPrice - r.lowestBidPrice;
    final cf  = pr > 0 ? ((r.cutoffPrice   - r.lowestBidPrice) / pr).clamp(0.0, 1.0) : 0.5;
    final af  = pr > 0 ? ((r.averageBidPrice - r.lowestBidPrice) / pr).clamp(0.0, 1.0) : 0.5;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
      Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                gradient: r.resultPublished ? const LinearGradient(
                    colors: [Color(0xFF1A6B2A), Color(0xFF0F4D1D)]) : null,
                color: r.resultPublished ? null : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: r.resultPublished
                    ? const Color(0xFF2DB144).withOpacity(0.5)
                    : Colors.white.withOpacity(0.12))),
            child: Row(children: [
              Icon(r.resultPublished ? Icons.verified_rounded : Icons.pending_rounded,
                  size: 14,
                  color: r.resultPublished ? const Color(0xFF2DB144) : Colors.white38),
              const SizedBox(width: 6),
              Text(r.resultPublished ? 'Published' : 'Unpublished',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: r.resultPublished
                          ? const Color(0xFF2DB144) : Colors.white38)),
            ])),
        if (r.publishedDate != null) ...[
          const SizedBox(width: 10),
          Text(_fDT(r.publishedDate!),
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35))),
        ],
        const Spacer(),
        Text('Result #${r.resultId}',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.25))),
      ]),

      const SizedBox(height: 18),
      Row(children: [
        _hero('TOTAL BIDS', '${r.totalBidsReceived}',
            Icons.gavel_rounded, const Color(0xFFD4A017), 1),
        const SizedBox(width: 10),
        _hero('TOTAL AMOUNT', r.fmtTotalBidAmount,
            Icons.payments_outlined, const Color(0xFF2DB144), 2),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _hero('ALLOCATED', r.fmtTotalAllocated,
            Icons.pie_chart_outline_rounded, Colors.blueAccent, 2),
        const SizedBox(width: 10),
        _hero('BID-TO-COVER', r.fmtBidToCoverRatio,
            Icons.show_chart_rounded, Colors.purpleAccent, 1),
      ]),

      const SizedBox(height: 22),
      _secHdr('PRICE RANGE ANALYSIS'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _pLabel('LOW', r.fmtLowestBidPrice, Colors.redAccent),
            _pLabel('HIGH', r.fmtHighestBidPrice, const Color(0xFF2DB144), right: true),
          ]),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            return Stack(clipBehavior: Clip.none, children: [
              Container(height: 8, decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(4))),
              Container(height: 8, width: w * cf,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2DB144), Color(0xFFD4A017)]),
                      borderRadius: BorderRadius.circular(4))),
              Positioned(left: (w * af) - 1, top: -4,
                  child: Container(width: 2, height: 16,
                      decoration: BoxDecoration(color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(1)))),
              Positioned(left: (w * cf) - 7, top: -6,
                  child: Container(width: 14, height: 14,
                      decoration: BoxDecoration(
                          color: const Color(0xFFD4A017), shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                          boxShadow: [BoxShadow(
                              color: const Color(0xFFD4A017).withOpacity(0.5),
                              blurRadius: 6)]))),
            ]);
          }),
          const SizedBox(height: 16),
          Row(children: [
            _dot(const Color(0xFF2DB144)), const SizedBox(width: 5),
            Text('Fill', style: _ls()),
            const SizedBox(width: 14),
            _dot(Colors.blueAccent), const SizedBox(width: 5),
            Text('Avg ${r.fmtAverageBidPrice}', style: _ls()),
            const SizedBox(width: 14),
            _dot(const Color(0xFFD4A017)), const SizedBox(width: 5),
            Text('Cutoff ${r.fmtCutoffPrice}', style: _ls()),
          ]),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.07), height: 1),
          const SizedBox(height: 14),
          Row(children: [
            _pCol('AVERAGE', r.fmtAverageBidPrice, Colors.blueAccent),
            _pColDiv(),
            _pCol('CUTOFF', r.fmtCutoffPrice, const Color(0xFFD4A017)),
            _pColDiv(),
            _pCol('UNIFORM', r.fmtUniformPrice, Colors.purpleAccent),
          ]),
        ]),
      ),

      const SizedBox(height: 22),
      _secHdr('ALLOCATION'), const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _sBox('Allocation Ratio', r.fmtAllocationRatio,
            const Color(0xFFD4A017))),
        const SizedBox(width: 10),
        Expanded(child: _sBox('Bid-to-Cover', r.fmtBidToCoverRatio,
            Colors.purpleAccent)),
      ]),

      const SizedBox(height: 22),
      _secHdr('SETTLEMENT'), const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: r.settlementCompleted
                ? const Color(0xFF0A2F12) : const Color(0xFF1C1200),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: r.settlementCompleted
                ? const Color(0xFF2DB144).withOpacity(0.4)
                : Colors.orange.withOpacity(0.35))),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: r.settlementCompleted
                      ? const Color(0xFF2DB144).withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Icon(r.settlementCompleted
                  ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
                  size: 22,
                  color: r.settlementCompleted
                      ? const Color(0xFF2DB144) : Colors.orange)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.settlementCompleted
                    ? 'Settlement Complete' : 'Settlement Pending',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                        color: r.settlementCompleted
                            ? const Color(0xFF2DB144) : Colors.orange)),
                const SizedBox(height: 3),
                Text(r.settlementDate != null
                    ? _fDT(r.settlementDate!) : 'Date not yet confirmed',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
              ])),
        ]),
      ),
    ]);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Widget _statusBadge(String s) {
    final c = _sc(s);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: c.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.4))),
        child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
            color: c, letterSpacing: 0.5)));
  }

  Widget _card(String title, List<Widget> rows, {Widget? extra}) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFFD4A017), fontSize: 11,
            fontWeight: FontWeight.w800, letterSpacing: 0.8)),
        const SizedBox(height: 12),
        Divider(color: Colors.white.withOpacity(0.08), height: 1),
        const SizedBox(height: 10),
        ...rows,
        if (extra != null) extra,
      ]));

  Widget _row(String l, String v, {Color? vc}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(l, style: TextStyle(fontSize: 11,
                color: Colors.white.withOpacity(0.45)))),
            const SizedBox(width: 6),
            Flexible(child: Text(v, textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: vc ?? Colors.white))),
          ]));

  Widget _hero(String l, String v, IconData icon, Color c, int flex) =>
      Expanded(flex: flex, child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.withOpacity(0.25))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 14, color: c.withOpacity(0.8)), const SizedBox(width: 6),
              Text(l, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: c.withOpacity(0.7), letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 8),
            Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                color: Colors.white), overflow: TextOverflow.ellipsis),
          ])));

  Widget _secHdr(String l) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(color: const Color(0xFF2DB144),
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(l, style: const TextStyle(color: Colors.white54, fontSize: 11,
        fontWeight: FontWeight.w800, letterSpacing: 0.8)),
  ]);

  Widget _pLabel(String l, String v, Color c, {bool right = false}) =>
      Column(crossAxisAlignment: right
          ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Text(l, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: c.withOpacity(0.7), letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: c)),
      ]);

  Widget _dot(Color c) => Container(width: 8, height: 8,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  TextStyle _ls() => TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45),
      fontWeight: FontWeight.w600);

  Widget _pCol(String l, String v, Color c) =>
      Expanded(child: Column(children: [
        Text(l, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.4), letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: c),
            textAlign: TextAlign.center),
      ]));

  Widget _pColDiv() => Container(width: 1, height: 36,
      color: Colors.white.withOpacity(0.06),
      margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _sBox(String l, String v, Color c) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: c.withOpacity(0.7), letterSpacing: 0.4)),
        const SizedBox(height: 8),
        Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
            color: Colors.white)),
      ]));

  static String _fDT(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final m  = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]} ${dt.year} '
          '${dt.hour.toString().padLeft(2,"0")}:'
          '${dt.minute.toString().padLeft(2,"0")}';
    } catch (_) { return iso; }
  }
}