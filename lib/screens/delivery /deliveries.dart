import 'package:flutter/material.dart';

class DeliveriesContent extends StatefulWidget {
  const DeliveriesContent({super.key});

  @override
  State<DeliveriesContent> createState() => _DeliveriesContentState();
}

class _DeliveriesContentState extends State<DeliveriesContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _deliveries = [
    {'name': 'Red Sorghum', 'quantity': '100', 'unit': 'KG', 'status': 'Pending'},
    {'name': 'Maize', 'quantity': '250', 'unit': 'KG', 'status': 'In Transit'},
    {'name': 'Wheat', 'quantity': '180', 'unit': 'KG', 'status': 'Delivered'},
    {'name': 'Red Sorghum', 'quantity': '100', 'unit': 'KG', 'status': 'Pending'},
    {'name': 'Soya Beans', 'quantity': '320', 'unit': 'KG', 'status': 'In Transit'},
    {'name': 'Red Sorghum', 'quantity': '100', 'unit': 'KG', 'status': 'Pending'},
    {'name': 'Cotton', 'quantity': '90', 'unit': 'KG', 'status': 'Delivered'},
    {'name': 'Red Sorghum', 'quantity': '100', 'unit': 'KG', 'status': 'Pending'},
    {'name': 'Millet', 'quantity': '210', 'unit': 'KG', 'status': 'Pending'},
    {'name': 'Red Sorghum', 'quantity': '100', 'unit': 'KG', 'status': 'In Transit'},
    {'name': 'Red Sorghum', 'quantity': '100', 'unit': 'KG', 'status': 'Pending'},
    {'name': 'Tobacco', 'quantity': '75', 'unit': 'KG', 'status': 'Delivered'},
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return const Color(0xFF2DB144);
      case 'In Transit':
        return const Color(0xFFD4A017);
      default:
        return const Color(0xFF888888);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle_rounded;
      case 'In Transit':
        return Icons.local_shipping_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  void _showBookDeliverySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BookDeliverySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // ── List ──────────────────────────────────────────────────
          ListView(
            padding: EdgeInsets.only(
              top: 4,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            children: [
              _buildHeader(),
              _buildDeliveriesContainer(),
            ],
          ),

          // ── FAB ───────────────────────────────────────────────────
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 90,
            right: 20,
            child: _buildFAB(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Deliveries',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFD4A017).withOpacity(0.35), width: 1),
            ),
            child: Text(
              '${_deliveries.length} Items',
              style: const TextStyle(
                color: Color(0xFFD4A017),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesContainer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
            children: _deliveries
                .asMap()
                .entries
                .map((e) => _buildDeliveryCard(e.value, e.key))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, String> item, int index) {
    final status = item['status']!;
    final statusColor = _statusColor(status);
    final statusIcon = _statusIcon(status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)), child: child),
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
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quantity + Unit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Quantity: ${item['quantity']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unit: ${item['unit']}',
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
    );
  }

  // ── Floating Action Button ─────────────────────────────────────────────
  Widget _buildFAB() {
    return GestureDetector(
      onTap: _showBookDeliverySheet,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2DB144).withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

// ── Book Delivery Bottom Sheet ─────────────────────────────────────────────
class _BookDeliverySheet extends StatefulWidget {
  const _BookDeliverySheet();

  @override
  State<_BookDeliverySheet> createState() => _BookDeliverySheetState();
}

class _BookDeliverySheetState extends State<_BookDeliverySheet> {
  final _commodityController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedWarehouse;
  String? _selectedPickUp;

  final List<String> _warehouses = [
    'Harare Warehouse',
    'Bulawayo Warehouse',
    'Mutare Warehouse',
    'Gweru Warehouse',
  ];

  final List<String> _pickUpOptions = [
    'Self Pick Up',
    'Door Delivery',
    'Depot Collection',
  ];

  @override
  void dispose() {
    _commodityController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 8,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            const Text(
              'Book A Delivery',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 24),

            // Commodity
            _buildTextField(
              controller: _commodityController,
              hint: 'Commodity',
              icon: Icons.grass_rounded,
            ),
            const SizedBox(height: 14),

            // Quantity
            _buildTextField(
              controller: _quantityController,
              hint: 'Quantity',
              icon: Icons.scale_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            // Warehouse dropdown
            _buildDropdown(
              hint: 'Warehouse',
              icon: Icons.warehouse_rounded,
              value: _selectedWarehouse,
              items: _warehouses,
              onChanged: (v) => setState(() => _selectedWarehouse = v),
            ),
            const SizedBox(height: 14),

            // Delivery Pick Up dropdown
            _buildDropdown(
              hint: 'Delivery Pick Up',
              icon: Icons.local_shipping_rounded,
              value: _selectedPickUp,
              items: _pickUpOptions,
              onChanged: (v) => setState(() => _selectedPickUp = v),
            ),
            const SizedBox(height: 14),

            // Pick Up Location
            _buildTextField(
              controller: _locationController,
              hint: 'Pick Up Location',
              icon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 28),

            // Book Delivery Button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                // TODO: submit booking
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2DB144), Color(0xFF1E8E32)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2DB144).withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Book Delivery',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.5), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
            fontSize: 15, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFFD4A017), size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.5), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, color: const Color(0xFFD4A017), size: 20),
              const SizedBox(width: 12),
              Text(hint,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            ],
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF1A1A1A)),
          ),
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(e,
                  style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500)),
            ),
          ))
              .toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}