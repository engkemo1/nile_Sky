import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../widgets/operator_picker.dart';
import '../widgets/admin_form.dart';

class BalloonsScreen extends StatefulWidget {
  const BalloonsScreen({super.key});
  @override
  State<BalloonsScreen> createState() => _BalloonsScreenState();
}

class _BalloonsScreenState extends State<BalloonsScreen> {
  List<dynamic> _balloons = [];
  List<dynamic> _operators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _balloons = await AdminApiService.getBalloons();
      _error = null;
    } catch (e) {
      _error = 'Could not load balloons: '
          '${e.toString().replaceFirst('ApiException: ', '')}';
    }
    try {
      _operators = await AdminApiService.getOperators();
    } catch (e) {
      // Secondary lookup: the picker degrades but the list still renders.
      debugPrint('operators lookup failed: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showEditDialog([Map<String, dynamic>? b]) {
    final regCtrl = TextEditingController(text: b?['registrationCode'] ?? '');
    final nameCtrl = TextEditingController(text: b?['name'] ?? '');
    final capCtrl = TextEditingController(text: (b?['capacity'] ?? 16).toString());
    String? selectedOperatorId = b?['operatorId']?.toString() ??
        (_operators.isNotEmpty ? _operators.first['id']?.toString() : null);
    final isEdit = b != null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit ${b['name']}' : 'Add Balloon', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        StatefulBuilder(
          builder: (_, setLocal) => OperatorPicker(
            operators: _operators,
            value: selectedOperatorId,
            onChanged: (v) => setLocal(() => selectedOperatorId = v),
          ),
        ),
        _field('Registration Code', regCtrl),
        _field('Name', nameCtrl),
        _field('Capacity', capCtrl),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
        ElevatedButton(
          onPressed: () async {
            if (selectedOperatorId == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an operator first')));
            return;
          }
          Navigator.pop(ctx);
            final data = {'registrationCode': regCtrl.text, 'name': nameCtrl.text, 'capacity': int.tryParse(capCtrl.text) ?? 16, 'operatorId': selectedOperatorId};
            try {
              if (isEdit) { await AdminApiService.updateBalloon(b['id'], data); }
              else { await AdminApiService.createBalloon(data); }
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Updated' : 'Created'), backgroundColor: AdminColors.success));
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error)); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black),
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    ));
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
      Padding(padding: const EdgeInsets.fromLTRB(28, 28, 28, 0), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fleet Management', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 4),
            const Text('Manage balloon fleet & inspections', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
          ]),
          Row(children: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Balloon')),
          ]),
        ],
      )),
      const SizedBox(height: 16), const Divider(color: AdminColors.border, height: 1),
      ErrorBanner(error: _error, onRetry: _load),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
        : _balloons.isEmpty ? const Center(child: Text('No balloons found.', style: TextStyle(color: AdminColors.textMuted)))
        : SingleChildScrollView(padding: const EdgeInsets.all(28), child: Container(
            width: double.infinity, decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            child: DataTable(columnSpacing: 20, columns: const [
              DataColumn(label: Text('REG CODE')), DataColumn(label: Text('NAME')), DataColumn(label: Text('OPERATOR')),
              DataColumn(label: Text('CAPACITY')), DataColumn(label: Text('STATUS')), DataColumn(label: Text('ACTIONS')),
            ], rows: _balloons.map<DataRow>((b) {
              final status = (b['status'] ?? 'available').toString();
              final statusColor = status == 'available' ? AdminColors.success : status == 'in_flight' ? AdminColors.info : status == 'maintenance' ? AdminColors.warning : AdminColors.error;
              return DataRow(cells: [
                DataCell(Text(b['registrationCode'] ?? '-', style: const TextStyle(color: AdminColors.secondary, fontWeight: FontWeight.w600, fontSize: 12))),
                DataCell(Text(b['name'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(b['operator']?['nameEn'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${b['capacity'] ?? 0} pax', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), tooltip: 'Edit', onPressed: () => _showEditDialog(b)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), tooltip: 'Delete', onPressed: () async {
                    try { await AdminApiService.deleteBalloon(b['id']); _load(); } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                    }
                  }),
                ])),
              ]);
            }).toList()),
          )),
      ),
    ]);
  }
}
