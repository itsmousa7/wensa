import 'package:flutter/material.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_tier.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.plan,
    required this.isCurrentPlan,
    this.onSelectTap,
  });

  final PlanModel     plan;
  final bool          isCurrentPlan;
  final VoidCallback? onSelectTap;

  @override
  Widget build(BuildContext context) {
    final isPro       = plan.tier == PlanTier.pro;
    final accentColor = isPro ? const Color(0xFF7C3AED) : const Color(0xFF2196F3);
    final bgColor     = isCurrentPlan ? accentColor.withOpacity(0.08) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: isCurrentPlan ? accentColor : const Color(0xFFE0E0E0),
          width: isCurrentPlan ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPro)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Most Popular',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          Text(plan.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 6),
          _buildPrice(),
          const SizedBox(height: 16),
          if (isCurrentPlan)
            _pill('Current plan', accentColor)
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelectTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(plan.isFree ? 'Downgrade to Free' : 'Upgrade — ${_fmtIqd(plan.priceIqd)} IQD/mo'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrice() {
    if (plan.priceIqd == 0) {
      return const Text('Free', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
    }
    return Text(
      '${_fmtIqd(plan.priceIqd)} IQD / شهر',
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      );

  static String _fmtIqd(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
