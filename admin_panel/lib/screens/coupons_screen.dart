import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../widgets/admin_form.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});
  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<dynamic> _coupons = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _coupons = await AdminApiService.getCoupons();
      _error = null;
    } catch (e) {
      _error = 'Could not load coupons: '
          '${e.toString().replaceFirst('ApiException: ', '')}';
    }
    setState(() => _isLoading = false);
  }

  void _showCreateDialog() {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final maxDiscountCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController();
    String type = 'percentage';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      backgroundColor: AdminColors.cardDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Coupon', style: TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field('Code (e.g. WELCOME10)', codeCtrl),
        Row(children: [
          Expanded(child: RadioListTile<String>(
            title: const Text('Percentage', style: TextStyle(color: AdminColors.textPrimary, fontSize: 12)),
            value: 'percentage', groupValue: type, activeColor: AdminColors.primary,
            onChanged: (v) => setDialogState(() => type = v!),
          )),
          Expanded(child: RadioListTile<String>(
            title: const Text('Fixed EGP', style: TextStyle(color: AdminColors.textPrimary, fontSize: 12)),
            value: 'fixed', groupValue: type, activeColor: AdminColors.primary,
            onChanged: (v) => setDialogState(() => type = v!),
          )),
        ]),
        _field(type == 'percentage' ? 'Discount %' : 'Discount (EGP)', valueCtrl),
        if (type == 'percentage') _field('Max Discount (EGP)', maxDiscountCtrl),
        _field('Max Uses (optional)', maxUsesCtrl),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          final now = DateTime.now();
          final data = {
            'code': codeCtrl.text.toUpperCase(),
            'type': type,
            'value': double.tryParse(valueCtrl.text) ?? 10,
            if (type == 'percentage' && maxDiscountCtrl.text.isNotEmpty) 'maxDiscountEgp': double.tryParse(maxDiscountCtrl.text),
            'validFrom': now.toIso8601String().substring(0, 10),
            'validTo': DateTime(now.year + 1, now.month, now.day).toIso8601String().substring(0, 10),
            if (maxUsesCtrl.text.isNotEmpty) 'maxUses': int.tryParse(maxUsesCtrl.text),
          };
          try {
            await AdminApiService.createCoupon(data);
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coupon created!'), backgroundColor: AdminColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black), child: const Text('Create')),
      ],
    )));
  }

  Widget _field(String l, TextEditingController c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
    controller: c, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
    decoration: InputDecoration(labelText: l, labelStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12), filled: true, fillColor: AdminColors.surfaceDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.primary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
  ));

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(28, 28, 28, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Coupons & Promotions', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4), const Text('Manage discount codes & marketing campaigns', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
        ]),
        Row(children: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
          const SizedBox(width: 8),
          ElevatedButton.icon(onPressed: _showCreateDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Create Coupon')),
        ]),
      ])),
      const SizedBox(height: 16), const Divider(color: AdminColors.border, height: 1),
      ErrorBanner(error: _error, onRetry: _load),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
        : _coupons.isEmpty ? const Center(child: Text('No coupons found.', style: TextStyle(color: AdminColors.textMuted)))
        : SingleChildScrollView(padding: const EdgeInsets.all(28), child: Container(
            width: double.infinity, decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            child: DataTable(columnSpacing: 20, columns: const [
              DataColumn(label: Text('CODE')), DataColumn(label: Text('TYPE')), DataColumn(label: Text('VALUE')),
              DataColumn(label: Text('USED')), DataColumn(label: Text('VALID TO')), DataColumn(label: Text('STATUS')), DataColumn(label: Text('ACTIONS')),
            ], rows: _coupons.map<DataRow>((c) {
              final isActive = c['isActive'] == true;
              final type = (c['type'] ?? 'percentage').toString();
              final validTo = c['validTo']?.toString().substring(0, 10) ?? '-';
              return DataRow(cells: [
                DataCell(Text(c['code'] ?? '-', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
                DataCell(Text(type == 'percentage' ? 'Percentage' : 'Fixed', style: const TextStyle(fontSize: 12))),
                DataCell(Text(type == 'percentage' ? '${c['value']}%' : '${c['value']} EGP', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${c['usedCount'] ?? 0}/${c['maxUses'] ?? '∞'}')),
                DataCell(Text(validTo, style: const TextStyle(fontSize: 12))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(
                  color: (isActive ? AdminColors.success : AdminColors.error).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: isActive ? AdminColors.success : AdminColors.error, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), onPressed: () async {
                  try { await AdminApiService.deleteCoupon(c['id']); _load(); } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                  }
                })),
              ]);
            }).toList()),
          )),
      ),
    ]);
  }
}
