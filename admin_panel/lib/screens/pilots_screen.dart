import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';

class PilotsScreen extends StatefulWidget {
  const PilotsScreen({super.key});
  @override
  State<PilotsScreen> createState() => _PilotsScreenState();
}

class _PilotsScreenState extends State<PilotsScreen> {
  List<dynamic> _pilots = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try { _pilots = await AdminApiService.getPilots(); } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showEditDialog([Map<String, dynamic>? p]) {
    final nameEnCtrl = TextEditingController(text: p?['nameEn'] ?? '');
    final nameArCtrl = TextEditingController(text: p?['nameAr'] ?? '');
    final licenseCtrl = TextEditingController(text: p?['licenseNumber'] ?? '');
    final expCtrl = TextEditingController(text: (p?['experienceYears'] ?? 0).toString());
    final isEdit = p != null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Pilot' : 'Add Pilot', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _field('Name (EN)', nameEnCtrl), _field('Name (AR)', nameArCtrl),
        _field('License #', licenseCtrl), _field('Experience (Years)', expCtrl),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          final data = {'nameEn': nameEnCtrl.text, 'nameAr': nameArCtrl.text, 'licenseNumber': licenseCtrl.text, 'experienceYears': int.tryParse(expCtrl.text) ?? 0};
          try {
            if (isEdit) { await AdminApiService.updatePilot(p['id'], data); } else { await AdminApiService.createPilot(data); }
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
          Text('Pilot Management', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4), const Text('Manage pilot assignments & licensing', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
        ]),
        Row(children: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
          const SizedBox(width: 8),
          ElevatedButton.icon(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Pilot')),
        ]),
      ])),
      const SizedBox(height: 16), const Divider(color: AdminColors.border, height: 1),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
        : _pilots.isEmpty ? const Center(child: Text('No pilots found.', style: TextStyle(color: AdminColors.textMuted)))
        : SingleChildScrollView(padding: const EdgeInsets.all(28), child: Container(
            width: double.infinity, decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            child: DataTable(columnSpacing: 20, columns: const [
              DataColumn(label: Text('NAME')), DataColumn(label: Text('LICENSE')), DataColumn(label: Text('EXPERIENCE')),
              DataColumn(label: Text('FLIGHTS')), DataColumn(label: Text('RATING')), DataColumn(label: Text('STATUS')), DataColumn(label: Text('ACTIONS')),
            ], rows: _pilots.map<DataRow>((p) {
              final status = (p['status'] ?? 'active').toString();
              final statusColor = status == 'active' ? AdminColors.success : status == 'on_leave' ? AdminColors.warning : AdminColors.error;
              return DataRow(cells: [
                DataCell(Text(p['nameEn'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataCell(Text(p['licenseNumber'] ?? '-', style: const TextStyle(color: AdminColors.secondary, fontSize: 12))),
                DataCell(Text('${p['experienceYears'] ?? 0} years')),
                DataCell(Text('${p['totalFlights'] ?? 0}')),
                DataCell(Text('${p['rating'] ?? 0} ⭐', style: const TextStyle(fontSize: 12))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), onPressed: () => _showEditDialog(p)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), onPressed: () async {
                    try { await AdminApiService.deletePilot(p['id']); _load(); } catch (e) {
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
