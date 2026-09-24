import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../widgets/operator_picker.dart';
import '../widgets/admin_form.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});
  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<dynamic> _drivers = [];
  List<dynamic> _operators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _drivers = await AdminApiService.getDrivers();
      _error = null;
    } catch (e) {
      _error = 'Could not load drivers: '
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

  void _showEditDialog([Map<String, dynamic>? d]) {
    final nameCtrl = TextEditingController(text: d?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: d?['phone'] ?? '');
    final carCtrl = TextEditingController(text: d?['carModel'] ?? '');
    final plateCtrl = TextEditingController(text: d?['carPlate'] ?? '');
    String? selectedOperatorId = d?['operatorId']?.toString() ??
        (_operators.isNotEmpty ? _operators.first['id']?.toString() : null);
    final isEdit = d != null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Driver' : 'Add Driver', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        StatefulBuilder(
          builder: (_, setLocal) => OperatorPicker(
            operators: _operators,
            value: selectedOperatorId,
            onChanged: (v) => setLocal(() => selectedOperatorId = v),
          ),
        ),
        _field('Name', nameCtrl), _field('Phone', phoneCtrl), _field('Car Model', carCtrl), _field('Plate #', plateCtrl),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
        ElevatedButton(onPressed: () async {
          if (selectedOperatorId == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select an operator first')));
            return;
          }
          // Name and phone are @IsNotEmpty() on the API; without this check a
          // blank field came back as a raw 400 in a snackbar.
          if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Name and phone are required'),
              backgroundColor: AdminColors.error,
            ));
            return;
          }
          Navigator.pop(ctx);
          final data = {
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            if (carCtrl.text.trim().isNotEmpty) 'carModel': carCtrl.text.trim(),
            if (plateCtrl.text.trim().isNotEmpty) 'carPlate': plateCtrl.text.trim(),
            'operatorId': selectedOperatorId,
          };
          try {
            if (isEdit) { await AdminApiService.updateDriver(d['id'], data); } else { await AdminApiService.createDriver(data); }
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Updated' : 'Created'), backgroundColor: AdminColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black), child: Text(isEdit ? 'Save' : 'Create')),
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
      Padding(padding: const EdgeInsets.fromLTRB(28, 28, 28, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Driver Management', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4), const Text('Manage hotel pickup drivers & vehicles', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
        ]),
        Row(children: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
          const SizedBox(width: 8),
          ElevatedButton.icon(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Driver')),
        ]),
      ])),
      const SizedBox(height: 16), const Divider(color: AdminColors.border, height: 1),
      ErrorBanner(error: _error, onRetry: _load),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
        : _drivers.isEmpty ? const Center(child: Text('No drivers found.', style: TextStyle(color: AdminColors.textMuted)))
        : SingleChildScrollView(padding: const EdgeInsets.all(28), child: Container(
            width: double.infinity, decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            child: DataTable(columnSpacing: 20, columns: const [
              DataColumn(label: Text('NAME')), DataColumn(label: Text('PHONE')), DataColumn(label: Text('CAR')),
              DataColumn(label: Text('PLATE')), DataColumn(label: Text('STATUS')), DataColumn(label: Text('ACTIONS')),
            ], rows: _drivers.map<DataRow>((d) {
              final status = (d['status'] ?? 'available').toString();
              final statusColor = status == 'available' ? AdminColors.success : status == 'on_trip' ? AdminColors.info : AdminColors.warning;
              return DataRow(cells: [
                DataCell(Text(d['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataCell(Text(d['phone'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(d['carModel'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(d['carPlate'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), onPressed: () => _showEditDialog(d)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), onPressed: () async {
                    try { await AdminApiService.deleteDriver(d['id']); _load(); } catch (e) {
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
