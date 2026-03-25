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
  // ── Default to Secondary Market ───────────────────────────────────────
  bool _isPrimaryMarket = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _userName = '';
  String _userCds  = '';

  // ── API data ──────────────────────────────────────────────────────────
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

  // ── API URLs ──────────────────────────────────────────────────────────
  static const _secondaryUrl =
      'https://system.zmx.co.zw/ZMX-API/Subscriber/MarketWatchByCategorySecondary?category=COMMODITY';
  static const _primaryUrl =
      'https://system.zmx.co.zw/ZMX-API/Subscriber/MarketWatchByCategoryPrimary?category=COMMODITY';

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

    // Fetch secondary first (it's the default view), then primary in background
    _fetchSecondary();
    _fetchPrimary();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _userCds  = prefs.getString('user_cds')  ?? '-';
    });
  }

  // ── Parse raw API list into commodity map ─────────────────────────────
  List<Map<String, dynamic>> _parseMarketData(List<dynamic> raw) {
    return raw.map((item) {
      final m = item as Map<String, dynamic>;

      // Extract commodity name from "MAIZE/B/HRE/USD" → "Maize"
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

      final String changeStr = perChange >= 0
          ? '+${perChange.toStringAsFixed(2)}%'
          : '${perChange.toStringAsFixed(2)}%';

      return {
        'name': name,
        'currency': m['currency'] ?? 'USD',
        'bid': bp.toStringAsFixed(4),
        'ask': ap.toStringAsFixed(4),
        'price': vwap.toStringAsFixed(4),
        'change': changeStr,
        'positive': perChange >= 0,
        'settlement': m['settlement_cycle'] ?? '',
        'details': m['market_company'] ?? '',
      };
    }).toList();
  }

  Future<void> _fetchSecondary() async {
    setState(() {
      _isLoadingSecondary = true;
      _secondaryError = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_secondaryUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _secondaryCommodities = _parseMarketData(data));
      } else {
        setState(() =>
        _secondaryError = 'Server error (${response.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _secondaryError = 'Failed to load data');
    } finally {
      if (mounted) setState(() => _isLoadingSecondary = false);
    }
  }

  Future<void> _fetchPrimary() async {
    setState(() {
      _isLoadingPrimary = true;
      _primaryError = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_primaryUrl))
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _primaryCommodities = _parseMarketData(data));
      } else {
        setState(
                () => _primaryError = 'Server error (${response.statusCode})');
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

  // ── Market body: loading / error / list ───────────────────────────────
  Widget _buildMarketBody() {
    if (_isLoadingCurrent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2DB144)),
        ),
      );
    }

    if (_currentError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded,
                color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(_currentError!,
                style:
                TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isPrimaryMarket ? _fetchPrimary : _fetchSecondary,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DB144),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
            offset: const Offset(0, 10),
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
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (_, child) =>
                            Transform.scale(scale: _pulseAnimation.value, child: child),
                        child: Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF2DB144), shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_getGreeting(),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3)),
                    ],
                  ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 6),
                  const Text('\$180.00',
                      style: TextStyle(
                          color: Color(0xFF2DB144),
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
                ],
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF2DB144).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(children: const [
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tag_rounded,
                    color: const Color(0xFFD4A017).withOpacity(0.8), size: 13),
                const SizedBox(width: 6),
                Text('Account: $_userCds',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                Container(
                    width: 1, height: 12, color: Colors.white.withOpacity(0.12)),
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
        child:
        const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _statCard(icon: Icons.trending_up_rounded, label: "Today's Gain", value: '+\$24.50', valueColor: const Color(0xFF2DB144), iconBg: const Color(0xFF2DB144))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(icon: Icons.swap_horiz_rounded, label: 'Open Orders', value: '3', valueColor: const Color(0xFFD4A017), iconBg: const Color(0xFFD4A017))),
        const SizedBox(width: 12),
        Expanded(child: _statCard(icon: Icons.local_shipping_rounded, label: 'Deliveries', value: '2', valueColor: const Color(0xFF5B8AF0), iconBg: const Color(0xFF5B8AF0))),
      ],
    );
  }

  Widget _statCard({required IconData icon, required String label, required String value, required Color valueColor, required Color iconBg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBg.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: iconBg, size: 17)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMarketToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        _marketTab('Secondary Market', false),
        _marketTab('Primary Market', true),
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
            gradient: isSelected ? const LinearGradient(colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]) : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF2DB144).withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF888888), fontSize: 13, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, letterSpacing: 0.2)),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2DB144), Color(0xFF1E8E32)]), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(_isPrimaryMarket ? 'Primary Market' : 'Secondary Market', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: 0.2)),
          ],
        ),
        if (!_isLoadingCurrent)
          Text('${_currentCommodities.length} commodities', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
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
          child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.055), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFF2DB144).withOpacity(0.1) : const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.grass_rounded,
                  color: isPositive ? const Color(0xFF2DB144) : const Color(0xFFE53935), size: 22),
            ),
            const SizedBox(width: 12),

            // Name + currency + settlement
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(commodity['name'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD4A017).withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                        child: Text(commodity['currency'], style: const TextStyle(fontSize: 9, color: Color(0xFFD4A017), fontWeight: FontWeight.w700)),
                      ),
                      if ((commodity['settlement'] as String).isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(commodity['settlement'],
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                      ],
                    ],
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
                  Row(children: [
                    Text('Bid  ', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                    Text(commodity['bid'], style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Ask  ', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
                    Text(commodity['ask'], style: const TextStyle(fontSize: 12, color: Color(0xFFD4A017), fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),

            // Price badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPositive
                        ? [const Color(0xFF2DB144), const Color(0xFF1E8E32)]
                        : [const Color(0xFFE53935), const Color(0xFFC62828)]),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [BoxShadow(color: (isPositive ? const Color(0xFF2DB144) : const Color(0xFFE53935)).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(commodity['price'],
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(commodity['change'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
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