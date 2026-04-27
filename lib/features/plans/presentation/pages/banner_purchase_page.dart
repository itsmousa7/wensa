import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:future_riverpod/features/plans/domain/models/merchant_plan_state.dart';
import 'package:future_riverpod/features/plans/presentation/providers/current_plan_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BannerPurchasePage extends ConsumerStatefulWidget {
  const BannerPurchasePage({
    super.key,
    required this.merchantId,
    required this.placeId,
    required this.placeName,
  });

  final String merchantId;
  final String placeId;
  final String placeName;

  @override
  ConsumerState<BannerPurchasePage> createState() => _BannerPurchasePageState();
}

class _BannerPurchasePageState extends ConsumerState<BannerPurchasePage> {
  DateTime _startDate    = DateTime.now().add(const Duration(days: 1));
  int      _days         = 3;
  String   _paidVia      = 'paid'; // 'trial' | 'quarterly_slot' | 'paid'
  bool     _isSubmitting = false;

  static const int _pricePerDay = 5000; // IQD

  int get _cost => _paidVia == 'paid' ? _days * _pricePerDay : 0;

  @override
  Widget build(BuildContext context) {
    final planStateAsync = ref.watch(merchantPlanStateProvider(widget.merchantId));

    return Scaffold(
      appBar: AppBar(title: const Text('Promote Listing'), centerTitle: true),
      body: planStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (planState) => _buildForm(context, planState),
      ),
    );
  }

  Widget _buildForm(BuildContext context, MerchantPlanState planState) {
    final hasTrialDays   = planState.bannerTrialDaysRemaining > 0;
    final hasQuarterSlot = planState.plan.quarterlyBannerSlots > 0 &&
        planState.quarterlyBannerSlotsRemaining > 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Place being promoted ─────────────────────────────────────────
        Text('Promoting: ${widget.placeName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 24),

        // ── Payment method ───────────────────────────────────────────────
        const Text('Payment method', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (hasTrialDays)
          _radioTile(
            value: 'trial',
            title: 'Use free trial days',
            subtitle: '${planState.bannerTrialDaysRemaining} trial days remaining',
          ),
        if (hasQuarterSlot)
          _radioTile(
            value: 'quarterly_slot',
            title: 'Use quarterly slot',
            subtitle: '${planState.quarterlyBannerSlotsRemaining} slot(s) remaining this quarter',
          ),
        _radioTile(
          value: 'paid',
          title: 'Pay per day',
          subtitle: '5,000 IQD / day',
        ),

        const SizedBox(height: 24),

        // ── Start date picker ────────────────────────────────────────────
        const Text('Start date', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickStartDate,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(_fmtDate(_startDate)),
        ),

        const SizedBox(height: 24),

        // ── Duration ─────────────────────────────────────────────────────
        const Text('Duration (days)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _days > 1 ? () => setState(() => _days--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$_days', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() => _days++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_paidVia == 'trial')
          Text(
            'You have ${planState.bannerTrialDaysRemaining} trial days — '
            '${_days > planState.bannerTrialDaysRemaining ? "not enough" : "OK"}',
            style: TextStyle(
              color: _days > planState.bannerTrialDaysRemaining ? Colors.red : Colors.green,
              fontSize: 12,
            ),
          ),

        const SizedBox(height: 24),

        // ── Cost summary ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _summaryRow('Start date', _fmtDate(_startDate)),
              _summaryRow('End date',   _fmtDate(_startDate.add(Duration(days: _days - 1)))),
              _summaryRow('Duration',   '$_days days'),
              const Divider(),
              _summaryRow(
                'Total cost',
                _cost == 0 ? 'Free (using ${_paidVia == "trial" ? "trial" : "slot"})' : '${_fmtIqd(_cost)} IQD',
                bold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: _isSubmitting ? null : () => _submit(context, planState),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Activate Banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _radioTile({required String value, required String title, required String subtitle}) =>
      RadioListTile<String>(
        value:    value,
        groupValue: _paidVia,
        onChanged: (v) => setState(() => _paidVia = v!),
        title:    Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        contentPadding: EdgeInsets.zero,
        dense: true,
      );

  Widget _summaryRow(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF757575))),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      );

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit(BuildContext context, MerchantPlanState planState) async {
    if (_paidVia == 'trial' && _days > planState.bannerTrialDaysRemaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough trial days remaining'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'banner-activate',
        body: {
          'merchant_id': widget.merchantId,
          'place_id':    widget.placeId,
          'start_date':  _startDate.toIso8601String().substring(0, 10),
          'days':        _days,
          'paid_via':    _paidVia,
        },
      );
      final body = res.data as Map<String, dynamic>?;
      if (body?['success'] == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner activated!')),
        );
        Navigator.pop(context);
        // Invalidate plan state so banner counters update
        ref.invalidate(merchantPlanStateProvider(widget.merchantId));
      } else {
        throw Exception(body?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtIqd(int amount)  => amount.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
