import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Deliveries — currently a "Coming Soon" placeholder.
//
// The previous implementation hit a live GetDeliveries endpoint but the
// booking flow (warehouse/pickup options, submit) was entirely hardcoded
// with no real backend behind it. Rather than ship a half-working feature,
// this shows a placeholder until the booking API is ready.
// ─────────────────────────────────────────────────────────────────────────────
class DeliveriesContent extends StatelessWidget {
  const DeliveriesContent({super.key});

  static const _green = Color(0xFF2DB144);
  static const _gold  = Color(0xFFD4A017);
  static const _dark  = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: _gold, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deliveries',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _dark,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withOpacity(0.35), width: 1),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Booking and tracking deliveries will be available here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
