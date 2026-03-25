import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CashContent extends StatefulWidget {
  const CashContent({super.key});

  @override
  State<CashContent> createState() => _CashContentState();
}

class _CashContentState extends State<CashContent>
    with SingleTickerProviderStateMixin {
  bool _showOrders = true;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // ── API orders state ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;
  String _cdsNumber = '';

  // ── Balance state (ZIG) ───────────────────────────────────────────────
  Map<String, dynamic>? _zigBalance;
  bool _isLoadingZig = false;

  // ── Balance state (USD) ───────────────────────────────────────────────
  Map<String, dynamic>? _usdBalance;
  bool _isLoadingUsd = false;

  // ── Currency switch ─────────────────────────────────────────────────
  bool _showZig = true;

  // ── API transactions state ───────────────────────────────────────────
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;
  String? _transactionsError;

  // ── Colours ───────────────────────────────────────────────────────────
  static const _green  = Color(0xFF2DB144);
  static const _gold   = Color(0xFFD4A017);
  static const _dark   = Color(0xFF1A1A1A);
  static const _red    = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();

    _loadCdsAndFetchOrders();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // ── Load CDS from prefs then hit all APIs ────────────────────────────
  Future<void> _loadCdsAndFetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final cds   = prefs.getString('user_cds') ?? '';
    setState(() => _cdsNumber = cds);
    await Future.wait([
      _fetchOrders(cds),
      _fetchZigBalance(cds),
      _fetchUsdBalance(cds),
      _fetchTransactions(cds),
    ]);
  }

  // ── ZIG balance ───────────────────────────────────────────────────────
  Future<void> _fetchZigBalance([String? cds]) async {
    final number = cds ?? _cdsNumber;
    if (number.isEmpty) return;
    setState(() => _isLoadingZig = true);
    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/getCashBalance'
            '?cdsNumber=$number',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() => _zigBalance = Map<String, dynamic>.from(data[0]));
        }
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoadingZig = false); }
  }

  // ── USD balance ───────────────────────────────────────────────────────
  Future<void> _fetchUsdBalance([String? cds]) async {
    final number = cds ?? _cdsNumber;
    if (number.isEmpty) return;
    setState(() => _isLoadingUsd = true);
    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/getCashBalanceForex'
            '?cdsNumber=$number',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() => _usdBalance = Map<String, dynamic>.from(data[0]));
        }
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _isLoadingUsd = false); }
  }

  Future<void> _fetchOrders([String? cds]) async {
    final number = cds ?? _cdsNumber;
    if (number.isEmpty) {
      setState(() => _ordersError = 'CDS number not found');
      return;
    }

    setState(() {
      _isLoadingOrders = true;
      _ordersError     = null;
    });

    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/GetOrdersByType'
            '?cds_number=$number&type=commodity',
      );

      final response =
      await http.get(uri).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);

        // API may return a List or a Map with a nested list
        List<dynamic> raw = [];
        if (body is List) {
          raw = body;
        } else if (body is Map && body.containsKey('data')) {
          raw = body['data'] as List<dynamic>;
        } else if (body is Map && body.containsKey('orders')) {
          raw = body['orders'] as List<dynamic>;
        }

        setState(() => _orders = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      } else {
        setState(
                () => _ordersError = 'Server error (${response.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _ordersError = 'Failed to load orders');
    } finally {
      if (mounted) setState(() => _isLoadingOrders = false);
    }
  }

  // ── Transactions ─────────────────────────────────────────────────────
  Future<void> _fetchTransactions([String? cds]) async {
    final number = cds ?? _cdsNumber;
    if (number.isEmpty) return;
    setState(() { _isLoadingTransactions = true; _transactionsError = null; });
    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/zmx_web/online.ctrade_php/getCashTransForex.php'
            '?cdsNumber=$number',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _transactions =
            data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else {
        setState(() => _transactionsError = 'Server error (\${response.statusCode})');
      }
    } catch (_) {
      if (mounted) setState(() => _transactionsError = 'Failed to load transactions');
    } finally {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  void _switchTab(bool showOrders) {
    if (_showOrders == showOrders) return;
    _slideController.reset();
    setState(() => _showOrders = showOrders);
    _slideController.forward();
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 90),
      children: [
        _buildBalanceSection(),
        _buildActionButtons(),
        _buildTabToggle(),
        _buildListSection(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Balance section ───────────────────────────────────────────────────
  Widget _buildBalanceSection() {
    final isLoading = _showZig ? _isLoadingZig : _isLoadingUsd;
    final data      = _showZig ? _zigBalance   : _usdBalance;
    final currency  = _showZig ? 'ZiG'         : 'USD';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Row(children: [
            Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text('Account Balance',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3)),
            const Spacer(),
            GestureDetector(
              onTap: () { _fetchZigBalance(); _fetchUsdBalance(); },
              child: Icon(Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.3), size: 16),
            ),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Currency toggle pill ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              _currencyTab('ZiG', true),
              _currencyTab('USD', false),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Single currency panel ─────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(currency),
            child: _buildBalancePanel(currency, data, isLoading),
          ),
        ),
        const SizedBox(height: 18),
      ]),
    );
  }

  Widget _currencyTab(String label, bool isZig) {
    final isSelected = _showZig == isZig;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showZig = isZig),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(colors: [_gold, Color(0xFFB8860B)])
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [BoxShadow(color: _gold.withOpacity(0.35),
                blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }

  // ── Helper: format a balance string, handle null/loading ─────────────
  String _fmt(String? raw, {bool withSign = false}) {
    if (raw == null) return '—';
    final d = double.tryParse(raw);
    if (d == null) return raw;
    final s = d.abs().toStringAsFixed(2);
    if (withSign && d < 0) return '-$s';
    return s;
  }

  Widget _buildBalancePanel(
      String currency, Map<String, dynamic>? data, bool loading) {
    final prevPotValue = data?['MyPrevPotValue']?.toString();
    final cashBal      = data?['CashBal']?.toString();
    final virtBal      = data?['VirtCashBal']?.toString();
    final actualBal    = data?['ActualCashBal']?.toString();
    final totalAcct    = data?['totalAccount']?.toString();
    final potValue     = data?['MyPotValue']?.toString();
    final profitLoss   = data?['MyProfitLoss']?.toString();

    final double? pl       = profitLoss != null ? double.tryParse(profitLoss) : null;
    final bool    plPositive = (pl ?? 0) >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: loading
          ? const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(color: _green, strokeWidth: 2)))
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Main figure: MyPrevPotValue ───────────────────────────
        Text('Cash Value',
            style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(_fmt(prevPotValue, withSign: true),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3)),
        const SizedBox(height: 10),

        // ── Compact data grid ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(children: [
            Row(children: [
              _miniBalCell('Cash Bal',   _fmt(cashBal, withSign: true)),
              _miniDivider(),
              _miniBalCell('Virtual',    _fmt(virtBal)),
              _miniDivider(),
              _miniBalCell('Actual',     _fmt(actualBal, withSign: true)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _miniBalCell('Portfolio',  _fmt(potValue)),
              _miniDivider(),
              _miniBalCell('Total Acct', _fmt(totalAcct, withSign: true)),
              _miniDivider(),
              Expanded(
                child: Column(children: [
                  Text('P / L',
                      style: TextStyle(fontSize: 9,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(
                    (pl ?? 0) >= 0
                        ? '+${_fmt(profitLoss)}'
                        : _fmt(profitLoss, withSign: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: plPositive ? _green : _red),
                  ),
                ]),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _miniBalCell(String label, String value) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: TextStyle(fontSize: 9,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _miniDivider() => Container(
      width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withOpacity(0.08));



  // ── Action buttons ────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(children: [
        _actionButton('+ Deposit',  _green,       Colors.white),
        const SizedBox(width: 10),
        _actionButton('- Withdraw', _gold,        Colors.white),
        const SizedBox(width: 10),
        _actionButton('Pledges',    Colors.white, _gold, borderColor: _gold),
      ]),
    );
  }

  Widget _actionButton(String label, Color bg, Color textColor,
      {Color? borderColor}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1.8)
                : null,
            boxShadow: [
              BoxShadow(
                  color: bg == Colors.white
                      ? Colors.black.withOpacity(0.08)
                      : bg.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3)),
        ),
      ),
    );
  }

  // ── Tab toggle ────────────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(children: [
          _tabButton('My Orders',    true),   // ← renamed
          _tabButton('Transactions', false),
        ]),
      ),
    );
  }

  Widget _tabButton(String label, bool isOrders) {
    final isSelected = _showOrders == isOrders;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(isOrders),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? _dark : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.25),
                blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
        ),
      ),
    );
  }

  // ── List container ────────────────────────────────────────────────────
  Widget _buildListSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gold, Color(0xFFB8890F)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _gold.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _showOrders ? _buildOrdersBody() : _buildTransactionsList(),
          ),
        ),
      ),
    );
  }

  // ── Orders body: loading / error / empty / list ───────────────────────
  Widget _buildOrdersBody() {
    if (_isLoadingOrders) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_ordersError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 10),
          Text(_ordersError!,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _fetchOrders(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      );
    }

    if (_orders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text('No orders found',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      );
    }

    return Column(children: _orders.map(_buildOrderCard).toList());
  }

  // ── Single order card built from API response ─────────────────────────
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final commodity   = order['fullname']?.toString()     ?? '—';
    final type        = (order['type']?.toString()        ?? '').toUpperCase();
    final volume      = order['volume']?.toString()       ?? '—';
    final price       = order['price']?.toString()        ?? '—';
    final orderNumber = order['ordernumber']?.toString()  ?? '—';
    final date        = order['date']?.toString()         ?? '';
    final status      = (order['status']?.toString()      ?? '').toUpperCase();
    final source      = order['source']?.toString()       ?? '';

    // Compute a display value (volume × price)
    final double vol  = double.tryParse(volume) ?? 0;
    final double prc  = double.tryParse(price)  ?? 0;
    final String value = (vol * prc).toStringAsFixed(2);

    final isBuy       = type == 'BUY';
    final isCancelled = status == 'CANCELLED';
    final isFilled    = status == 'FILLED';

    // Badge colour: green=FILLED, gold=OPEN, grey=CANCELLED
    final Color badgeColor = isFilled
        ? _green
        : isCancelled
        ? Colors.grey.shade500
        : _gold;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Row 1: commodity name + status badge ──────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(commodity,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _dark),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withOpacity(0.4))),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.4)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Row 2: type badge | order number | date ───────────────────
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isBuy ? _green.withOpacity(0.12) : _red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(type,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isBuy ? _green : _red)),
          ),
          const SizedBox(width: 8),
          Text(orderNumber,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          if (date.isNotEmpty)
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 10, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text(date,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ]),
        ]),
        const SizedBox(height: 10),

        // ── Row 3: volume | price | value ─────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            _orderStat('Volume', volume),
            _vDivider(),
            _orderStat('Price', '\$$price'),
            _vDivider(),
            _orderStat('Value', '\$$value', highlight: true),
            if (source.isNotEmpty) ...[
              _vDivider(),
              _orderStat('Source', source),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _orderStat(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: highlight ? _gold : _dark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _vDivider() => Container(
      width: 1, height: 28, margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.grey.shade200);

  // ── Transactions list ────────────────────────────────────────────────
  Widget _buildTransactionsList() {
    if (_isLoadingTransactions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    if (_transactionsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 40),
          const SizedBox(height: 10),
          Text(_transactionsError!,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _fetchTransactions(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      );
    }
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Text('No transactions found',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
        ),
      );
    }
    return Column(children: _transactions.map(_buildTransactionCard).toList());
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final type   = tx['type']?.toString()    ?? '';
    final desc   = tx['desc']?.toString()    ?? '';
    final date   = tx['date']?.toString()    ?? '';
    final rawAmt = tx['ammount']?.toString() ?? '0'; // API uses 'ammount' (typo)

    final double amount   = double.tryParse(rawAmt) ?? 0;
    final bool   isCredit = amount >= 0;
    final String amtDisplay = isCredit
        ? '+${amount.toStringAsFixed(2)}'
        : amount.toStringAsFixed(2);

    final Color   iconColor = isCredit ? _green : _red;
    final IconData icon     = isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        // Icon bubble
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),

        // Desc + type badge + date
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _dark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5)),
                child: Text(type,
                    style: const TextStyle(fontSize: 9, color: _gold,
                        fontWeight: FontWeight.w700)),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.calendar_today_rounded,
                    size: 9, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(date,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ]),
          ]),
        ),

        // Amount badge — green if credit, red if debit
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(
                color: iconColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2))],
          ),
          child: Text(amtDisplay,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}