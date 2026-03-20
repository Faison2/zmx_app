import 'package:flutter/material.dart';

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

  final List<Map<String, String>> _orders = [
    {'commodity': 'Maize/GMBA/USD', 'type': 'BUY', 'volume': '9500', 'price': '0.393', 'value': '3733.50', 'status': 'OPEN'},
    {'commodity': 'Wheat/GMBA/USD', 'type': 'BUY', 'volume': '7200', 'price': '0.512', 'value': '3686.40', 'status': 'OPEN'},
    {'commodity': 'Soya/GMBA/USD', 'type': 'SELL', 'volume': '4800', 'price': '1.120', 'value': '5376.00', 'status': 'OPEN'},
    {'commodity': 'Maize/GMBA/USD', 'type': 'BUY', 'volume': '9500', 'price': '0.393', 'value': '3733.50', 'status': 'FILLED'},
    {'commodity': 'Cotton/GMBA/USD', 'type': 'SELL', 'volume': '3100', 'price': '2.340', 'value': '7254.00', 'status': 'OPEN'},
    {'commodity': 'Millet/GMBA/USD', 'type': 'BUY', 'volume': '6600', 'price': '0.621', 'value': '4098.60', 'status': 'OPEN'},
    {'commodity': 'Tobacco/GMBA/USD', 'type': 'SELL', 'volume': '2200', 'price': '4.810', 'value': '10582.00', 'status': 'FILLED'},
  ];

  final List<Map<String, String>> _transactions = [
    {'type': 'Sell', 'desc': 'SELL ORDER', 'amount': '3733.50'},
    {'type': 'Buy', 'desc': 'BUY ORDER', 'amount': '1820.00'},
    {'type': 'Sell', 'desc': 'SELL ORDER', 'amount': '5376.00'},
    {'type': 'Deposit', 'desc': 'WALLET DEPOSIT', 'amount': '500.00'},
    {'type': 'Sell', 'desc': 'SELL ORDER', 'amount': '3733.50'},
    {'type': 'Withdraw', 'desc': 'WITHDRAWAL', 'amount': '200.00'},
    {'type': 'Buy', 'desc': 'BUY ORDER', 'amount': '4098.60'},
    {'type': 'Deposit', 'desc': 'WALLET DEPOSIT', 'amount': '1000.00'},
  ];

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
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _switchTab(bool showOrders) {
    if (_showOrders == showOrders) return;
    _slideController.reset();
    setState(() => _showOrders = showOrders);
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 90,
      ),
      children: [
        _buildBalanceSection(),
        _buildActionButtons(),
        _buildTabToggle(),
        _buildListSection(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBalanceSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _buildBalanceColumn('ZiG', '1500.00', '1700.00', '2300.00')),
            VerticalDivider(
                color: Colors.grey.shade300,
                thickness: 1,
                indent: 16,
                endIndent: 16),
            Expanded(child: _buildBalanceColumn('USD', '150.00', '180.00', '220.00')),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceColumn(
      String currency, String cleared, String uncleared, String total) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cleared Cash:',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('$currency $cleared',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 12),
          _balanceRow('Uncleared Cash:', '$currency $uncleared'),
          const SizedBox(height: 6),
          _balanceRow('Total Account:', '$currency $total'),
        ],
      ),
    );
  }

  Widget _balanceRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          _actionButton('+ Deposit', const Color(0xFF2DB144), Colors.white),
          const SizedBox(width: 10),
          _actionButton('- Withdraw', const Color(0xFFD4A017), Colors.white),
          const SizedBox(width: 10),
          _actionButton('Pledges', Colors.white, const Color(0xFFD4A017),
              borderColor: const Color(0xFFD4A017)),
        ],
      ),
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
        child: Row(
          children: [
            _tabButton('Orders', true),
            _tabButton('Transactions', false),
          ],
        ),
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
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
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

  Widget _buildListSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: _showOrders
                  ? _orders.map(_buildOrderCard).toList()
                  : _transactions.map(_buildTransactionCard).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, String> order) {
    final isBuy = order['type'] == 'BUY';
    final isFilled = order['status'] == 'FILLED';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['commodity']!,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isBuy
                        ? const Color(0xFF2DB144).withOpacity(0.12)
                        : const Color(0xFFE53935).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Type: ${order['type']}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isBuy
                              ? const Color(0xFF2DB144)
                              : const Color(0xFFE53935))),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Volume: ${order['volume']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(height: 3),
                Text('Price: ${order['price']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isFilled ? const Color(0xFF1A1A1A) : const Color(0xFFD4A017),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Value: ${order['value']}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('Status: ${order['status']}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, String> tx) {
    final isCredit = tx['type'] == 'Sell' || tx['type'] == 'Deposit';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFF2DB144).withOpacity(0.1)
                  : const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFF2DB144) : const Color(0xFFE53935),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${tx['type']}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Text('Desc: ${tx['desc']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFD4A017).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Text('Amount: ${tx['amount']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
