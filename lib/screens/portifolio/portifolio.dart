import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────
class CommodityHolding {
  final String company;
  final String lastAcDate;
  final int totAllShares;
  final int prevdayQuantity;
  final double currePrice;
  final double prevPrice;
  final int uncleared;
  final int net;
  final String unitOfMeasure;

  CommodityHolding({
    required this.company,
    required this.lastAcDate,
    required this.totAllShares,
    required this.prevdayQuantity,
    required this.currePrice,
    required this.prevPrice,
    required this.uncleared,
    required this.net,
    required this.unitOfMeasure,
  });

  factory CommodityHolding.fromJson(Map<String, dynamic> json) {
    return CommodityHolding(
      company:         json['Company']          as String? ?? '',
      lastAcDate:      json['LastAcDate']        as String? ?? '',
      totAllShares:    _parseInt(json['totAllShares']),
      prevdayQuantity: _parseInt(json['prevdayQuantity']),
      currePrice:      _parseDouble(json['currePrice']),
      prevPrice:       _parseDouble(json['PrevPrice']),
      uncleared:       _parseInt(json['Uncleared']),
      net:             _parseInt(json['Net']),
      unitOfMeasure:   json['unit_of_measure']   as String? ?? '',
    );
  }

  // Safe parsers — handle int, double, String or null from the API
  static int    _parseInt(dynamic v)    => int.tryParse(v.toString())    ?? 0;
  static double _parseDouble(dynamic v) => double.tryParse(v.toString()) ?? 0.0;

  double get currentValue => currePrice * net;
  double get prevValue    => prevPrice  * prevdayQuantity;
  double get gainLoss     => currentValue - prevValue;
  bool   get isGain       => gainLoss >= 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class PortfolioContent extends StatefulWidget {
  const PortfolioContent({super.key});

  @override
  State<PortfolioContent> createState() => _PortfolioContentState();
}

class _PortfolioContentState extends State<PortfolioContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnimation;

  List<CommodityHolding> _holdings     = [];
  bool                   _isLoading    = true;
  String?                _errorMessage;
  String                 _cdsNumber    = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _loadPortfolio();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Data Fetching ─────────────────────────────────────────────────────────
  Future<void> _loadPortfolio() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final prefs     = await SharedPreferences.getInstance();
      final cdsNumber = prefs.getString('user_cds') ?? '';

      if (cdsNumber.isEmpty) {
        setState(() {
          _errorMessage = 'CDS account not found. Please log in again.';
          _isLoading    = false;
        });
        return;
      }

      _cdsNumber = cdsNumber;

      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/GetCommodityPortfolio'
            '?cds_Number=$cdsNumber',
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // ── SAFE JSON PARSING ──────────────────────────────────────────────
        // The API might return:
        //   • A plain array  → [ {...}, {...} ]
        //   • A wrapped obj  → { "data": [...] }
        //   • A single obj   → { "Company": "..." }
        //   • null / empty
        final decoded = jsonDecode(response.body);

        List<dynamic> rawList;

        if (decoded is List) {
          // Happy path — array of holdings
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          // Wrapped: look for any value that is a List
          final listEntry = decoded.values
              .whereType<List>()
              .firstOrNull;
          if (listEntry != null) {
            rawList = listEntry;
          } else {
            // Single object — treat as one-element list
            rawList = [decoded];
          }
        } else {
          // Unexpected shape (int, null, etc.)
          rawList = [];
        }

        final holdings = rawList
            .whereType<Map<String, dynamic>>()   // skip any non-map entries
            .map(CommodityHolding.fromJson)
            .toList();

        setState(() { _holdings = holdings; _isLoading = false; });
        _fadeController.forward(from: 0);
      } else {
        setState(() {
          _errorMessage =
          'Server error ${response.statusCode}. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.\n${e.toString()}';
        _isLoading    = false;
      });
    }
  }

  // ── Computed totals ───────────────────────────────────────────────────────
  double get _totalCurrentValue =>
      _holdings.fold(0, (s, h) => s + h.currentValue);
  double get _totalGainLoss =>
      _holdings.fold(0, (s, h) => s + h.gainLoss);
  bool get _isOverallGain => _totalGainLoss >= 0;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoader();
    if (_errorMessage != null) return _buildError();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 90),
        children: [
          _buildHeader(),
          _buildSummaryCard(),
          if (_holdings.isEmpty) _buildEmpty(),
          if (_holdings.isNotEmpty) _buildHoldingsSection(),
        ],
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────
  Widget _buildLoader() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: Color(0xFF2DB144)),
      SizedBox(height: 16),
      Text('Loading portfolio…',
          style: TextStyle(color: Color(0xFF888888))),
    ]),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFE53935)),
        const SizedBox(height: 16),
        Text(_errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF555555), fontSize: 14)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadPortfolio,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2DB144),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildEmpty() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
      SizedBox(height: 12),
      Text('No holdings found',
          style: TextStyle(
              color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w600)),
    ]),
  );

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Portfolio',
            style: TextStyle(
                fontSize: 30, fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A), letterSpacing: 0.3)),
        Row(children: [
          GestureDetector(
            onTap: _loadPortfolio,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF888888), size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2DB144).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF2DB144).withOpacity(0.3), width: 1),
            ),
            child: Row(children: const [
              Icon(Icons.bar_chart_rounded, color: Color(0xFF2DB144), size: 16),
              SizedBox(width: 5),
              Text('Live',
                  style: TextStyle(color: Color(0xFF2DB144),
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ],
    ),
  );

  // ── Summary Card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final gainLossFormatted =
        '${_isOverallGain ? '+' : ''}\$${_totalGainLoss.toStringAsFixed(2)}';
    final totalValueFormatted = '\$${_totalCurrentValue.toStringAsFixed(2)}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Portfolio Overview',
                  style: TextStyle(color: Colors.white.withOpacity(0.55),
                      fontSize: 12, fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DB144).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF2DB144).withOpacity(0.35)),
                ),
                child: Row(children: [
                  Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF2DB144), shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  const Text('LIVE',
                      style: TextStyle(color: Color(0xFF2DB144), fontSize: 10,
                          fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                ]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Divider(color: Colors.white.withOpacity(0.08), height: 1),
        ),
        IntrinsicHeight(
          child: Row(children: [
            Expanded(child: _buildSummaryColumn(
                label: 'Gain / Loss', value: gainLossFormatted,
                isPositive: _isOverallGain, showArrow: true)),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent,
                      const Color(0xFFD4A017).withOpacity(0.6),
                      Colors.transparent]),
              ),
            ),
            Expanded(child: _buildSummaryColumn(
                label: 'Portfolio Value', value: totalValueFormatted,
                isPositive: true, showArrow: false)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CDS: $_cdsNumber',
                  style: TextStyle(color: Colors.white.withOpacity(0.5),
                      fontSize: 12, fontWeight: FontWeight.w500)),
              Row(children: [
                const Icon(Icons.trending_up_rounded,
                    color: Color(0xFF2DB144), size: 16),
                const SizedBox(width: 6),
                Text('${_holdings.length} Assets',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSummaryColumn({
    required String label,
    required String value,
    required bool isPositive,
    required bool showArrow,
  }) {
    final color   = isPositive ? const Color(0xFF2DB144) : const Color(0xFFE53935);
    final bgColor = isPositive
        ? const Color(0xFF2DB144).withOpacity(0.08)
        : const Color(0xFFE53935).withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6)),
          child: const Text('USD',
              style: TextStyle(color: Color(0xFFD4A017), fontSize: 11,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: bgColor,
              borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(color: Colors.white.withOpacity(0.45),
                    fontSize: 10, fontWeight: FontWeight.w500,
                    letterSpacing: 0.3)),
            const SizedBox(height: 4),
            Row(children: [
              if (showArrow) ...[
                Icon(isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                    color: color, size: 14),
                const SizedBox(width: 4),
              ],
              Flexible(child: Text(value,
                  style: TextStyle(color: color, fontSize: 15,
                      fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Holdings List ─────────────────────────────────────────────────────────
  Widget _buildHoldingsSection() => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFD4A017), Color(0xFFB8890F)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: const Color(0xFFD4A017).withOpacity(0.3),
          blurRadius: 16, offset: const Offset(0, 6))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: _holdings.asMap().entries
              .map((e) => _buildHoldingCard(e.value, e.key))
              .toList(),
        ),
      ),
    ),
  );

  Widget _buildHoldingCard(CommodityHolding holding, int index) {
    final valueFormatted = '\$${holding.currentValue.toStringAsFixed(2)}';
    final gainFormatted  =
        '${holding.isGain ? '+' : ''}\$${holding.gainLoss.toStringAsFixed(2)}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 20 * (1 - v)),
              child: child)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFF2DB144).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.grass_rounded,
                color: Color(0xFF2DB144), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(holding.company,
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.attach_money_rounded,
                        size: 12, color: Color(0xFF888888)),
                    Text('Price: \$${holding.currePrice.toStringAsFixed(4)}',
                        style: TextStyle(fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (holding.isGain
                          ? const Color(0xFF2DB144)
                          : const Color(0xFFE53935)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(gainFormatted,
                        style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: holding.isGain
                                ? const Color(0xFF2DB144)
                                : const Color(0xFFE53935))),
                  ),
                ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF2DB144).withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${holding.net} ${holding.unitOfMeasure}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(valueFormatted,
                  style: TextStyle(color: Colors.white.withOpacity(0.9),
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }
}