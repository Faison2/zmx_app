import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with TickerProviderStateMixin {
  bool _isPrimaryMarket = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _userName = '';
  String _userCds  = '';

  // ── Wallet balances ───────────────────────────────────────────────────
  Map<String, dynamic>? _zigBalance;
  Map<String, dynamic>? _usdBalance;
  bool _isLoadingZig = false;
  bool _isLoadingUsd = false;

  List<Map<String, dynamic>> _primaryCommodities   = [];
  List<Map<String, dynamic>> _secondaryCommodities = [];
  bool _isLoadingPrimary   = false;
  bool _isLoadingSecondary = false;
  String? _primaryError;
  String? _secondaryError;

  List<Map<String, dynamic>> get _currentCommodities =>
      _isPrimaryMarket ? _primaryCommodities : _secondaryCommodities;

  bool get _isLoadingCurrent =>
      _isPrimaryMarket ? _isLoadingPrimary : _isLoadingSecondary;

  String? get _currentError =>
      _isPrimaryMarket ? _primaryError : _secondaryError;

  static const _secondaryUrl =
      'https://system.zmx.co.zw/ZMX-API/Subscriber/MarketWatchByCategorySecondary?category=COMMODITY';
  static const _primaryUrl =
      'https://system.zmx.co.zw/ZMX-API/Subscriber/MarketWatchByCategoryPrimary?category=COMMODITY';

  // ── Color constants ───────────────────────────────────────────────────
  static const _green     = Color(0xFF2DB144);
  static const _darkGreen = Color(0xFF1E8E32);
  static const _gold      = Color(0xFFD4A017);
  static const _dark      = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadUserData();

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

    _fetchSecondary();
    _fetchPrimary();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final cds = prefs.getString('user_cds') ?? '';
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userCds  = cds;
    });
    // Fetch both balances once we have the CDS
    await Future.wait([
      _fetchZigBalance(cds),
      _fetchUsdBalance(cds),
    ]);
  }

  // ── ZIG balance ───────────────────────────────────────────────────────
  Future<void> _fetchZigBalance([String? cds]) async {
    final number = cds ?? _userCds;
    if (number.isEmpty) return;
    setState(() => _isLoadingZig = true);
    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/getCashBalance'
            '?cdsNumber=$number',
      );
      final response =
      await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() => _zigBalance = Map<String, dynamic>.from(data[0]));
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingZig = false);
    }
  }

  // ── USD balance ───────────────────────────────────────────────────────
  Future<void> _fetchUsdBalance([String? cds]) async {
    final number = cds ?? _userCds;
    if (number.isEmpty) return;
    setState(() => _isLoadingUsd = true);
    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/getCashBalanceForex'
            '?cdsNumber=$number',
      );
      final response =
      await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() => _usdBalance = Map<String, dynamic>.from(data[0]));
        }
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingUsd = false);
    }
  }

  // ── Format a balance value safely ─────────────────────────────────────
  String _fmt(String? raw) {
    if (raw == null) return '—';
    final d = double.tryParse(raw);
    if (d == null) return raw;
    return d.toStringAsFixed(2);
  }

  // ── Parse raw API list ────────────────────────────────────────────────
  List<Map<String, dynamic>> _parseMarketData(List<dynamic> raw) {
    return raw.map((item) {
      final m = item as Map<String, dynamic>;

      final parts = (m['market_company'] as String? ?? '').split('/');
      final rawName = parts.isNotEmpty ? parts[0] : m['market_company'] ?? '';
      final name = rawName
          .split(' ')
          .map((w) => w.isEmpty
          ? ''
          : w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');

      final double perChange =
          double.tryParse(m['market_per_change']?.toString() ?? '0') ?? 0.0;
      final double bp =
          double.tryParse(m['market_bp']?.toString() ?? '0') ?? 0.0;
      final double ap =
          double.tryParse(m['market_ap']?.toString() ?? '0') ?? 0.0;
      final double vwap =
          double.tryParse(m['market_vwap']?.toString() ?? '0') ?? 0.0;
      final double high =
          double.tryParse(m['market_high']?.toString() ?? '0') ?? 0.0;
      final double low =
          double.tryParse(m['market_low']?.toString() ?? '0') ?? 0.0;
      final double open =
          double.tryParse(m['market_open']?.toString() ?? '0') ?? 0.0;
      final double change =
          double.tryParse(m['market_change']?.toString() ?? '0') ?? 0.0;
      final double turnover =
          double.tryParse(m['market_turnover']?.toString() ?? '0') ?? 0.0;
      final askVol  = m['market_ask_vol']?.toString() ?? '0';
      final lastVol = m['market_last_vol']?.toString() ?? '0';

      final String changeStr = perChange >= 0
          ? '+${perChange.toStringAsFixed(2)}%'
          : '${perChange.toStringAsFixed(2)}%';

      return {
        'name'       : name,
        'currency'   : m['currency'] ?? 'USD',
        'bid'        : bp.toStringAsFixed(4),
        'ask'        : ap.toStringAsFixed(4),
        'price'      : vwap.toStringAsFixed(4),
        'change'     : changeStr,
        'positive'   : perChange >= 0,
        'settlement' : m['settlement_cycle'] ?? 'T+3',
        'details'    : m['market_company'] ?? '',
        'rawChange'  : change.toStringAsFixed(2),
        'perChange'  : perChange.toStringAsFixed(2),
        'high'       : high.toStringAsFixed(2),
        'low'        : low.toStringAsFixed(2),
        'open'       : open.toStringAsFixed(2),
        'turnover'   : turnover.toStringAsFixed(2),
        'askVol'     : askVol,
        'lastVol'    : lastVol,
        'unit'       : 'KG',
      };
    }).toList();
  }

  Future<void> _fetchSecondary() async {
    setState(() { _isLoadingSecondary = true; _secondaryError = null; });
    try {
      final response = await http
          .get(Uri.parse(_secondaryUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _secondaryCommodities = _parseMarketData(data));
      } else {
        setState(() => _secondaryError = 'Server error (${response.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _secondaryError = 'Failed to load data');
    } finally {
      if (mounted) setState(() => _isLoadingSecondary = false);
    }
  }

  Future<void> _fetchPrimary() async {
    setState(() { _isLoadingPrimary = true; _primaryError = null; });
    try {
      final response = await http
          .get(Uri.parse(_primaryUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _primaryCommodities = _parseMarketData(data));
      } else {
        setState(() => _primaryError = 'Server error (${response.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _primaryError = 'Failed to load data');
    } finally {
      if (mounted) setState(() => _isLoadingPrimary = false);
    }
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

  // ══════════════════════════════════════════════════════════════════════
  //  DIALOG 1 — Product Details
  // ══════════════════════════════════════════════════════════════════════
  void _showProductDetailsDialog(Map<String, dynamic> commodity) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _ProductDetailsDialog(
        commodity: commodity,
        onBuy:  () { Navigator.pop(context); _showBuySellFormDialog(commodity, true);  },
        onSell: () { Navigator.pop(context); _showBuySellFormDialog(commodity, false); },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  DIALOG 2 — Buy / Sell Form
  // ══════════════════════════════════════════════════════════════════════
  void _showBuySellFormDialog(Map<String, dynamic> commodity, bool isBuy) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _BuySellFormDialog(
        commodity: commodity,
        isBuy: isBuy,
        onSubmit: (category, qty, price) {
          Navigator.pop(context);
          _showOrderConfirmationDialog(commodity, isBuy, category, qty, price);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  DIALOG 3 — Order Confirmation
  // ══════════════════════════════════════════════════════════════════════
  void _showOrderConfirmationDialog(
      Map<String, dynamic> commodity,
      bool isBuy,
      String category,
      double qty,
      double price,
      ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _OrderConfirmationDialog(
        commodity: commodity,
        isBuy: isBuy,
        category: category,
        quantity: qty,
        price: price,
        onPostOrder: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isBuy ? "Buy" : "Sell"} order posted successfully!'),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        _buildGreetingCard(),
        const SizedBox(height: 16),
        _buildQuickStats(),
        const SizedBox(height: 16),
        _buildMarketToggle(),
        const SizedBox(height: 14),
        _buildSectionLabel(),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: _fadeAnimation,
          child: _buildMarketBody(),
        ),
      ],
    );
  }

  Widget _buildMarketBody() {
    if (_isLoadingCurrent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    if (_currentError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          Icon(Icons.wifi_off_rounded, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(_currentError!, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isPrimaryMarket ? _fetchPrimary : _fetchSecondary,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      );
    }
    if (_currentCommodities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No commodities available',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }
    return Column(
      children: _currentCommodities
          .asMap()
          .entries
          .map((e) => _buildCommodityCard(e.value, e.key))
          .toList(),
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
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: greeting + sun icon ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, child) =>
                          Transform.scale(scale: _pulseAnimation.value, child: child),
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(_getGreeting(),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3)),
                  ]),
                  const SizedBox(height: 6),
                  Text(_userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2)),
                ],
              ),
              _buildSunIcon(),
            ],
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 20),

          // ── Wallet label + refresh ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white.withOpacity(0.4), size: 13),
                const SizedBox(width: 5),
                Text('Wallet Balance',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        letterSpacing: 0.3)),
              ]),
              GestureDetector(
                onTap: () {
                  _fetchZigBalance();
                  _fetchUsdBalance();
                },
                child: Icon(Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.3), size: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── ZIG + USD total account side by side ──────────────────
          Row(
            children: [
              Expanded(child: _buildBalancePill('ZiG', _zigBalance, _isLoadingZig)),
              const SizedBox(width: 10),
              Expanded(child: _buildBalancePill('USD', _usdBalance, _isLoadingUsd)),
            ],
          ),

          const SizedBox(height: 16),

          // ── Top Up button + CDS tag ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tag_rounded,
                      color: _gold.withOpacity(0.8), size: 13),
                  const SizedBox(width: 6),
                  Text('Account: $_userCds',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  Container(
                      width: 1, height: 12,
                      color: Colors.white.withOpacity(0.12)),
                  const SizedBox(width: 10),
                  Icon(Icons.copy_rounded,
                      color: Colors.white.withOpacity(0.3), size: 12),
                ]),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_green, _darkGreen]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: _green.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Row(children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text('Top Up',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Single balance pill (ZiG or USD) ──────────────────────────────────
  Widget _buildBalancePill(
      String currency, Map<String, dynamic>? data, bool loading) {
    final totalAcct = data?['totalAccount']?.toString();
    final isZig     = currency == 'ZiG';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(currency,
                style: const TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),

          // Value
          loading
              ? const SizedBox(
            height: 22,
            child: Center(
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    color: _green, strokeWidth: 2),
              ),
            ),
          )
              : Text(
            totalAcct != null
                ? '${isZig ? '' : '\$'}${_fmt(totalAcct)}'
                : '—',
            style: TextStyle(
                color: totalAcct != null ? _green : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3),
          ),

          const SizedBox(height: 3),
          Text('Total Account',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
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
        width: 58, height: 58,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
              colors: [Color(0xFFFFE066), Color(0xFFFFAA00)]),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFAA00).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 3)
          ],
        ),
        child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(children: [
      Expanded(child: _statCard(
          icon: Icons.trending_up_rounded,
          label: "Today's Gain",
          value: '+\$24.50',
          valueColor: _green,
          iconBg: _green)),
      const SizedBox(width: 12),
      Expanded(child: _statCard(
          icon: Icons.swap_horiz_rounded,
          label: 'Open Orders',
          value: '3',
          valueColor: _gold,
          iconBg: _gold)),
      const SizedBox(width: 12),
      Expanded(child: _statCard(
          icon: Icons.local_shipping_rounded,
          label: 'Deliveries',
          value: '2',
          valueColor: const Color(0xFF5B8AF0),
          iconBg: const Color(0xFF5B8AF0))),
    ]);
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
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: iconBg.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: iconBg, size: 17),
        ),
        const SizedBox(height: 10),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: valueColor)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        _marketTab('Secondary Market', false),
        _marketTab('Primary Market',   true),
      ]),
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
                ? const LinearGradient(colors: [_green, _darkGreen])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [BoxShadow(
                color: _green.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF888888),
                  fontSize: 13,
                  fontWeight:
                  isSelected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.2)),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_green, _darkGreen]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isPrimaryMarket ? 'Primary Market' : 'Secondary Market',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _dark,
                letterSpacing: 0.2),
          ),
        ]),
        if (!_isLoadingCurrent)
          Text('${_currentCommodities.length} commodities',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCommodityCard(Map<String, dynamic> commodity, int index) {
    final bool isPositive = commodity['positive'] as bool;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 200 + (index * 40).clamp(0, 600)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child)),
      child: GestureDetector(
        onTap: () => _showProductDetailsDialog(commodity),
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
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: isPositive
                      ? _green.withOpacity(0.1)
                      : const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.grass_rounded,
                  color: isPositive ? _green : const Color(0xFFE53935),
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(commodity['name'],
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: _dark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: _gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5)),
                    child: Text(commodity['currency'],
                        style: const TextStyle(
                            fontSize: 9, color: _gold, fontWeight: FontWeight.w700)),
                  ),
                  if ((commodity['settlement'] as String).isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(commodity['settlement'],
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500)),
                  ],
                ]),
              ]),
            ),
            Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Bid  ',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500)),
                  Text(commodity['bid'],
                      style: const TextStyle(
                          fontSize: 12,
                          color: _dark,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Ask  ',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500)),
                  Text(commodity['ask'],
                      style: const TextStyle(
                          fontSize: 12,
                          color: _gold,
                          fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPositive
                        ? [_green, _darkGreen]
                        : [
                      const Color(0xFFE53935),
                      const Color(0xFFC62828)
                    ]),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                      color: (isPositive
                          ? _green
                          : const Color(0xFFE53935))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(commodity['price'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      isPositive
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 10),
                  const SizedBox(width: 2),
                  Text(commodity['change'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ]),
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

// ══════════════════════════════════════════════════════════════════════════
//  DIALOG 1 — Product Details Sheet
// ══════════════════════════════════════════════════════════════════════════
class _ProductDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> commodity;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  const _ProductDetailsDialog({
    required this.commodity,
    required this.onBuy,
    required this.onSell,
  });

  static const _green = Color(0xFF2DB144);
  static const _gold  = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    final unit = commodity['unit'] as String? ?? 'KG';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)]),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child:
                    const Icon(Icons.close_rounded, color: _gold, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(commodity['details'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ),

            // Detail rows
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Column(children: [
                  _detailRow('Price',              '${commodity['price']}/$unit'),
                  _detailRow('Change',             commodity['rawChange']),
                  _detailRow('Percentage Change',  '${commodity['perChange']}%'),
                  _detailRow('Best Bid',           commodity['bid']),
                  _detailRow('Best Ask',           commodity['ask']),
                  _detailRow('Ask Volume',         commodity['askVol']),
                  _detailRow('High of the day',    '${commodity['high']}/$unit'),
                  _detailRow('Low of the day',     '${commodity['low']}/$unit'),
                  _detailRow('Last traded volume', '${commodity['lastVol']}$unit'),
                  _detailRow('Settlement Cycle',   commodity['settlement']),
                  _detailRow('Turnover',           commodity['turnover']),
                  _detailRow('Opening Price',      '${commodity['open']}/$unit', isLast: true),
                ]),
              ),
            ),

            // BUY / SELL buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onBuy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFD4A017), Color(0xFFB8860B)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: _gold.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                          child: Text('BUY',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onSell,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_green, Color(0xFF1E8E32)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: _green.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Center(
                          child: Text('SELL',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5))),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  DIALOG 2 — Buy / Sell Form
// ══════════════════════════════════════════════════════════════════════════
class _BuySellFormDialog extends StatefulWidget {
  final Map<String, dynamic> commodity;
  final bool isBuy;
  final void Function(String category, double qty, double price) onSubmit;

  const _BuySellFormDialog({
    required this.commodity,
    required this.isBuy,
    required this.onSubmit,
  });

  @override
  State<_BuySellFormDialog> createState() => _BuySellFormDialogState();
}

class _BuySellFormDialogState extends State<_BuySellFormDialog> {
  static const _green = Color(0xFF2DB144);
  static const _gold  = Color(0xFFD4A017);

  final _qtyController   = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;

  final _categories = ['Spot', 'Forward', 'Futures', 'Options'];

  void _submit() {
    final qty   = double.tryParse(_qtyController.text.trim());
    final price = double.tryParse(_priceController.text.trim());

    if (_selectedCategory == null ||
        qty == null ||
        price == null ||
        qty <= 0 ||
        price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all fields correctly.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    widget.onSubmit(_selectedCategory!, qty, price);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy    = widget.isBuy;
    final btnColor = isBuy ? _gold : _green;
    final btnLabel = isBuy ? 'BUY' : 'SELL';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(btnLabel,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 1)),
            ),
            const SizedBox(height: 24),

            _styledField(
              child: Text(widget.commodity['details'],
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A))),
            ),
            const SizedBox(height: 12),

            _styledField(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: const Text('Category',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _gold),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: const TextStyle(fontSize: 14))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _styledField(
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Quantity',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),

            _styledField(
              child: TextField(
                controller: _priceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Price',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isBuy
                        ? [const Color(0xFFD4A017), const Color(0xFF2DB144)]
                        : [const Color(0xFF2DB144), const Color(0xFFD4A017)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: btnColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: Center(
                  child: Text(btnLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledField({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold, width: 1.5),
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  DIALOG 3 — Order Confirmation
// ══════════════════════════════════════════════════════════════════════════
class _OrderConfirmationDialog extends StatelessWidget {
  final Map<String, dynamic> commodity;
  final bool isBuy;
  final String category;
  final double quantity;
  final double price;
  final VoidCallback onPostOrder;

  const _OrderConfirmationDialog({
    required this.commodity,
    required this.isBuy,
    required this.category,
    required this.quantity,
    required this.price,
    required this.onPostOrder,
  });

  static const _green = Color(0xFF2DB144);
  static const _gold  = Color(0xFFD4A017);

  @override
  Widget build(BuildContext context) {
    final unit        = commodity['unit'] as String? ?? 'KG';
    final total       = quantity * price;
    const platformFee = 0.75;
    const charges     = 0.75;
    final orderLabel  = isBuy ? 'BUY' : 'SELL';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Posting a $orderLabel order',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A))),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
                'You are posting a ${isBuy ? 'buy' : 'sell'} order for the following commodity:',
                style: TextStyle(
                    fontSize: 12.5, color: Colors.grey.shade500)),
            const SizedBox(height: 18),

            _confRow('Commodity', commodity['details']),
            _confRow('Quantity',  quantity.toStringAsFixed(0)),
            _confRow('Unit',      unit),
            _confRow('Price',     '${price.toStringAsFixed(2)}/$unit'),
            _confRow('Category',  category),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: _gold.withOpacity(0.4), thickness: 1),
            ),

            _confRow('Platform fee', platformFee.toStringAsFixed(2)),
            _confRow('Charges',      charges.toStringAsFixed(2)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A))),
                Text(total.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A1A))),
              ],
            ),

            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _gold, width: 1.5),
                    ),
                    child: const Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A)))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onPostOrder,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_green, Color(0xFF1E8E32)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: _green.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                        child: Text('Post Order',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white))),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _confRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}