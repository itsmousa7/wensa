import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/plans/domain/feature_gate.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_model.dart';
import 'package:future_riverpod/features/plans/domain/models/plan_tier.dart';
import 'package:future_riverpod/features/plans/presentation/providers/current_plan_provider.dart';
import 'package:future_riverpod/features/plans/presentation/pages/plans_page.dart';

/// Context passed to PaywallPage so the copy is specific to the blocked action.
enum PaywallContext {
  places,
  events,
  photos,
  directContact,
  basicAnalytics,
  advancedAnalytics,
  priorityPlacement,
  homeFeedPromotion,
  verifiedBadge,
  pushToFollowers,
  scheduledPosts,
  multiStaff,
  csvExport,
  apiAccess,
  prioritySupport,
}

extension PaywallContextX on PaywallContext {
  String get featureKey => switch (this) {
        PaywallContext.places             => 'places',
        PaywallContext.events             => 'events',
        PaywallContext.photos             => 'photos',
        PaywallContext.directContact      => 'directContact',
        PaywallContext.basicAnalytics     => 'basicAnalytics',
        PaywallContext.advancedAnalytics  => 'advancedAnalytics',
        PaywallContext.priorityPlacement  => 'priorityPlacement',
        PaywallContext.homeFeedPromotion  => 'homeFeedPromotion',
        PaywallContext.verifiedBadge      => 'verifiedBadge',
        PaywallContext.pushToFollowers    => 'pushToFollowers',
        PaywallContext.scheduledPosts     => 'scheduledPosts',
        PaywallContext.multiStaff         => 'multiStaff',
        PaywallContext.csvExport          => 'csvExport',
        PaywallContext.apiAccess          => 'apiAccess',
        PaywallContext.prioritySupport    => 'prioritySupport',
      };

  String get title => switch (this) {
        PaywallContext.places            => 'إضافة المزيد من الأماكن أو الفعاليات',
        PaywallContext.events            => 'إنشاء المزيد من الفعاليات',
        PaywallContext.photos            => 'إضافة المزيد من الصور',
        PaywallContext.directContact     => 'زر التواصل المباشر',
        PaywallContext.basicAnalytics    => 'لوحة الإحصائيات',
        PaywallContext.advancedAnalytics => 'إحصائيات متقدمة',
        PaywallContext.priorityPlacement => 'الأولوية في نتائج البحث',
        PaywallContext.homeFeedPromotion => 'الترويج في الصفحة الرئيسية',
        PaywallContext.verifiedBadge     => 'شارة موثّق',
        PaywallContext.pushToFollowers   => 'إشعارات للمتابعين',
        PaywallContext.scheduledPosts    => 'جدولة المنشورات',
        PaywallContext.multiStaff        => 'حسابات الموظفين',
        PaywallContext.csvExport         => 'تصدير CSV + وصول API',
        PaywallContext.apiAccess         => 'وصول API',
        PaywallContext.prioritySupport   => 'دعم على مدار الساعة',
      };

  String get description => switch (this) {
        PaywallContext.places            => 'الباقة الأساسية تتيح إجمالي عنصرَين فقط (أماكن + فعاليات). رقّ للحصول على المزيد.',
        PaywallContext.events            => 'الباقة الأساسية تتيح إجمالي عنصرَين فقط. رقّ لإنشاء فعاليات غير محدودة.',
        PaywallContext.photos            => 'الباقة الأساسية تتيح 3 صور إضافية لكل مكان. رقّ لإضافة صور غير محدودة.',
        PaywallContext.directContact     => 'أتِح للعملاء التواصل معك مباشرةً من قائمتك.',
        PaywallContext.basicAnalytics    => 'اطّلع على بيانات المشاهدات والحفظ والنقرات لقوائمك.',
        PaywallContext.advancedAnalytics => 'التركيبة السكانية وخرائط الحرارة ومقارنة المنافسين.',
        PaywallContext.priorityPlacement => 'تظهر قوائمك قبل غيرها في نفس الفئة عند التساوي في الصلة.',
        PaywallContext.homeFeedPromotion => 'اعرض مكانك في قسم "المميّز" أعلى تصنيفات الصفحة الرئيسية.',
        PaywallContext.verifiedBadge     => 'أضف علامة التحقق الزرقاء على جميع قوائمك.',
        PaywallContext.pushToFollowers   => 'أرسل إشعارات للمستخدمين الذين حفظوا مكانك.',
        PaywallContext.scheduledPosts    => 'خطّط وجدوِل الفعاليات والعروض مسبقاً.',
        PaywallContext.multiStaff        => 'امنح حتى 3 أعضاء من فريقك صلاحية الدخول للوحة التاجر.',
        PaywallContext.csvExport         => 'صدّر بياناتك وتكامل عبر API.',
        PaywallContext.apiAccess         => 'وصول برمجي لبيانات حسابك التجاري.',
        PaywallContext.prioritySupport   => 'احصل على دعم متخصص على مدار الساعة.',
      };
}

class PaywallPage extends ConsumerWidget {
  const PaywallPage({
    super.key,
    required this.merchantId,
    required this.context,
  });

  final String         merchantId;
  final PaywallContext context;

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final allPlansAsync = ref.watch(allPlansProvider);
    final requiredPlanId = FeatureGate.cheapestPlanForFeature(context.featureKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Feature'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
      body: allPlansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (plans) {
          final targetPlan = plans.firstWhere(
            (p) => p.id == requiredPlanId,
            orElse: () => PlanModel.fallbackBasic,
          );

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Feature highlight ─────────────────────────────────────
                const Icon(Icons.lock_open, size: 56, color: Color(0xFF2196F3)),
                const SizedBox(height: 16),
                Text(
                  context.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  context.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF757575), height: 1.5),
                ),
                const SizedBox(height: 32),

                // ── Required plan callout ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFF1565C0), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'متاح في باقة ${targetPlan.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              targetPlan.priceIqd == 0
                                  ? 'مجاني'
                                  : '${_fmtIqd(targetPlan.priceIqd)} د.ع / شهر',
                              style: const TextStyle(color: Color(0xFF1565C0), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── CTA ───────────────────────────────────────────────────
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => PlansPage(merchantId: merchantId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('ترقية إلى ${targetPlan.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ربما لاحقاً', style: TextStyle(color: Color(0xFF9E9E9E))),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmtIqd(int amount) => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
