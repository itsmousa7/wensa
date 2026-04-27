import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_tier.dart';
import 'package:future_riverpod/features/plans/presentation/providers/current_plan_provider.dart';
import 'package:future_riverpod/features/plans/presentation/widgets/feature_row.dart';
import 'package:future_riverpod/features/plans/presentation/widgets/plan_card.dart';
import 'package:url_launcher/url_launcher.dart';

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key, required this.merchantId});

  final String merchantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPlansAsync    = ref.watch(allPlansProvider);
    final currentPlanAsync = ref.watch(merchantPlanStateProvider(merchantId));
    final changerState     = ref.watch(planChangerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الباقات والأسعار'), centerTitle: true),
      body: allPlansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('خطأ: $e')),
        data: (plans) {
          final currentTier = currentPlanAsync.value?.tier ?? PlanTier.basic;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Plan cards ────────────────────────────────────────────────
              const Text('اختر باقتك',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('يمكنك الترقية أو التخفيض في أي وقت.',
                  style: TextStyle(color: Color(0xFF9E9E9E))),
              const SizedBox(height: 20),
              ...plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlanCard(
                    plan: plan,
                    isCurrentPlan: plan.tier == currentTier,
                    onSelectTap: changerState.isLoading
                        ? null
                        : () => _onSelectPlan(context, ref, plan, currentTier),
                  ),
                ),
              ),

              // ── Feature comparison ────────────────────────────────────────
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text('مقارنة الباقات',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _tableHeader(),
              const Divider(height: 1),
              ..._buildRows(plans),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ── Comparison table ───────────────────────────────────────────────────────
  Widget _tableHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: const [
            Expanded(flex: 3, child: SizedBox()),
            Expanded(child: Center(child: Text('أساسي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            Expanded(child: Center(child: Text('نمو',   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
            Expanded(child: Center(child: Text('برو',   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          ],
        ),
      );

  List<Widget> _buildRows(List<PlanModel> plans) {
    if (plans.length < 3) return [];
    final basic  = plans.firstWhere((p) => p.tier == PlanTier.basic,  orElse: () => plans[0]);
    final growth = plans.firstWhere((p) => p.tier == PlanTier.growth, orElse: () => plans[1]);
    final pro    = plans.firstWhere((p) => p.tier == PlanTier.pro,    orElse: () => plans[2]);

    String combinedLabel(PlanModel p) =>
        p.maxCombinedItems == null ? '∞' : '${p.maxCombinedItems}';

    String photoLabel(PlanModel p) =>
        p.maxAdditionalPhotos == null ? '∞' : '${p.maxAdditionalPhotos}';

    return [
      FeatureRow(
        label: 'أماكن + فعاليات (مجموع)',
        basic:  FeatureRow.fromText(combinedLabel(basic)),
        growth: FeatureRow.fromText(combinedLabel(growth)),
        pro:    FeatureRow.fromText(combinedLabel(pro)),
      ),
      FeatureRow(
        label: 'صور إضافية لكل مكان',
        basic:  FeatureRow.fromText(photoLabel(basic)),
        growth: FeatureRow.fromText(photoLabel(growth)),
        pro:    FeatureRow.fromText(photoLabel(pro)),
      ),
      FeatureRow(
        label: 'زر التواصل المباشر',
        basic: FeatureRow.fromBool(basic.hasDirectContact), growth: FeatureRow.fromBool(growth.hasDirectContact), pro: FeatureRow.fromBool(pro.hasDirectContact),
      ),
      FeatureRow(
        label: 'إحصائيات أساسية',
        basic: FeatureRow.fromBool(basic.hasBasicAnalytics), growth: FeatureRow.fromBool(growth.hasBasicAnalytics), pro: FeatureRow.fromBool(pro.hasBasicAnalytics),
      ),
      FeatureRow(
        label: 'إحصائيات متقدمة',
        basic: FeatureRow.fromBool(basic.hasAdvancedAnalytics), growth: FeatureRow.fromBool(growth.hasAdvancedAnalytics), pro: FeatureRow.fromBool(pro.hasAdvancedAnalytics),
      ),
      FeatureRow(
        label: 'أولوية في البحث',
        basic: FeatureRow.fromBool(basic.hasPriorityPlacement), growth: FeatureRow.fromBool(growth.hasPriorityPlacement), pro: FeatureRow.fromBool(pro.hasPriorityPlacement),
      ),
      FeatureRow(
        label: 'ترويج في الصفحة الرئيسية',
        basic: FeatureRow.fromBool(basic.hasHomeFeedPromotion), growth: FeatureRow.fromBool(growth.hasHomeFeedPromotion), pro: FeatureRow.fromBool(pro.hasHomeFeedPromotion),
      ),
      FeatureRow(
        label: 'شارة موثّق',
        basic: FeatureRow.fromBool(basic.hasVerifiedBadge), growth: FeatureRow.fromBool(growth.hasVerifiedBadge), pro: FeatureRow.fromBool(pro.hasVerifiedBadge),
      ),
      FeatureRow(
        label: 'إشعارات للمتابعين',
        basic: FeatureRow.fromBool(basic.hasPushToFollowers), growth: FeatureRow.fromBool(growth.hasPushToFollowers), pro: FeatureRow.fromBool(pro.hasPushToFollowers),
      ),
      FeatureRow(
        label: 'جدولة المنشورات',
        basic: FeatureRow.fromBool(basic.hasScheduledPosts), growth: FeatureRow.fromBool(growth.hasScheduledPosts), pro: FeatureRow.fromBool(pro.hasScheduledPosts),
      ),
      FeatureRow(
        label: 'حسابات موظفين (حتى 3)',
        basic: FeatureRow.fromBool(false), growth: FeatureRow.fromBool(false), pro: FeatureRow.fromBool(pro.hasMultiStaff),
      ),
      FeatureRow(
        label: 'تصدير CSV + API',
        basic: FeatureRow.fromBool(false), growth: FeatureRow.fromBool(false), pro: FeatureRow.fromBool(pro.hasCsvExport),
      ),
      FeatureRow(
        label: 'دعم على مدار الساعة',
        basic: FeatureRow.fromBool(false), growth: FeatureRow.fromBool(false), pro: FeatureRow.fromBool(pro.hasPrioritySupport),
      ),
      FeatureRow(
        label: 'بنرات مجانية/ربع سنة',
        basic:  FeatureRow.fromText('—'),
        growth: FeatureRow.fromText('3 أيام تجريبية'),
        pro:    FeatureRow.fromText('${pro.quarterlyBannerSlots} خانة/ربع'),
      ),
    ];
  }

  // ── Plan selection handler ────────────────────────────────────────────────
  Future<void> _onSelectPlan(
    BuildContext context,
    WidgetRef ref,
    PlanModel target,
    PlanTier currentTier,
  ) async {
    final isDowngrade = target.tier < currentTier;

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDowngrade ? 'تخفيض إلى ${target.name}?' : 'الترقية إلى ${target.name}؟'),
        content: isDowngrade
            ? const Text(
                'ستُخفى الأماكن والفعاليات الزائدة (لن تُحذف). '
                'تُعاد إظهارها فوراً عند الترقية مجدداً.',
              )
            : Text(
                'ستُفتح صفحة دفع آمنة عبر Wayl لإتمام الدفع.\n'
                'السعر: ${_fmtIqd(target.priceIqd)} د.ع / شهر.',
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isDowngrade ? 'تخفيض' : 'متابعة للدفع'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final changer = ref.read(planChangerProvider.notifier);
    final result  = await changer.changePlan(merchantId: merchantId, targetPlanId: target.id);

    if (!context.mounted) return;

    if (ref.read(planChangerProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${ref.read(planChangerProvider).error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Paid upgrade → open Wayl payment URL in browser
    if (result?.paymentUrl != null) {
      final uri = Uri.parse(result!.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('أكمل الدفع في المتصفح — ستُفعَّل الباقة تلقائياً.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذّر فتح رابط الدفع: ${result.paymentUrl}')),
          );
        }
      }
      return;
    }

    // Immediate (downgrade)
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تم التحويل إلى ${target.name}')));
  }

  static String _fmtIqd(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
