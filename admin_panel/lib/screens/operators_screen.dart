import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../widgets/admin_form.dart';
import '../widgets/media_manager.dart';
import 'package:intl/intl.dart';

class OperatorsScreen extends StatefulWidget {
  const OperatorsScreen({super.key});

  @override
  State<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends State<OperatorsScreen> {
  List<dynamic> _operators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _operators = await AdminApiService.getOperators();
      _error = null;
    } catch (e) {
      _error = 'Could not load operators: '
          '${e.toString().replaceFirst('ApiException: ', '')}';
    }
    setState(() => _isLoading = false);
  }


  /// Reads a date that may arrive as 'yyyy-MM-dd' or a full timestamp.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.length < 10) return null;
    return DateTime.tryParse(text.substring(0, 10));
  }

  /// A tappable date field with a clear button, for nullable dates.
  Widget _dateField(
    BuildContext ctx,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onPicked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPicked(picked);
        },
        child: InputDecorator(
          decoration: adminInput(label),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value == null
                      ? 'Not set'
                      : DateFormat('d MMM yyyy').format(value),
                  style: TextStyle(
                    color: value == null
                        ? AdminColors.textMuted
                        : AdminColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              if (value != null)
                IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: AdminColors.textMuted),
                  onPressed: () => onPicked(null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog([Map<String, dynamic>? op]) {
    final nameEnCtrl = TextEditingController(text: op?['nameEn'] ?? '');
    final nameArCtrl = TextEditingController(text: op?['nameAr'] ?? '');
    final emailCtrl = TextEditingController(text: op?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: op?['phone'] ?? '');
    final commissionCtrl = TextEditingController(text: (op?['commissionRate'] ?? 10).toString());
    final descEnCtrl = TextEditingController(text: op?['descriptionEn']?.toString() ?? '');
    final whatsappCtrl = TextEditingController(text: op?['whatsapp']?.toString() ?? '');
    final websiteCtrl = TextEditingController(text: op?['website']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: op?['address']?.toString() ?? '');
    final licenseCtrl = TextEditingController(text: op?['licenseNumber']?.toString() ?? '');
    final videoCtrl = TextEditingController(text: op?['videoUrl']?.toString() ?? '');
    final rawPhotos = op?['photos'];
    List<String> photos =
        rawPhotos is List ? rawPhotos.map((e) => e.toString()).toList() : <String>[];
    DateTime? licenseExpiry = _parseDate(op?['licenseExpiry']);
    DateTime? insuranceExpiry = _parseDate(op?['insuranceExpiry']);
    final isEdit = op != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit ${op['nameEn']}' : 'Add Operator', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (ctx2, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Name (EN)', nameEnCtrl),
                _field('Name (AR)', nameArCtrl),
                _field('Email', emailCtrl),
                _field('Phone', phoneCtrl),
                _field('WhatsApp', whatsappCtrl),
                _field('Website', websiteCtrl),
                _field('Address / launch site', addressCtrl),
                _field('Commission %', commissionCtrl),
                _field('Licence number', licenseCtrl),
                _dateField(ctx2, 'Licence expiry', licenseExpiry,
                    (d) => setLocal(() => licenseExpiry = d)),
                _dateField(ctx2, 'Insurance expiry', insuranceExpiry,
                    (d) => setLocal(() => insuranceExpiry = d)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: descEnCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        color: AdminColors.textPrimary, fontSize: 13),
                    decoration: adminInput('Description (EN)'),
                  ),
                ),
                MediaManager(
                  urls: photos,
                  folder: 'operators',
                  onChanged: (next) => setLocal(() => photos = next),
                ),
                _field('Video URL', videoCtrl),
              ],
            ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // @IsOptional() only skips null/undefined, so an empty string
              // fails @IsEmail(). Omit blank optional fields entirely.
              final data = <String, dynamic>{
                'nameEn': nameEnCtrl.text,
                'nameAr': nameArCtrl.text,
                if (emailCtrl.text.trim().isNotEmpty) 'email': emailCtrl.text.trim(),
                if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
                'commissionRate': double.tryParse(commissionCtrl.text) ?? 10,
                if (whatsappCtrl.text.trim().isNotEmpty) 'whatsapp': whatsappCtrl.text.trim(),
                if (websiteCtrl.text.trim().isNotEmpty) 'website': websiteCtrl.text.trim(),
                if (addressCtrl.text.trim().isNotEmpty) 'address': addressCtrl.text.trim(),
                if (licenseCtrl.text.trim().isNotEmpty) 'licenseNumber': licenseCtrl.text.trim(),
                if (descEnCtrl.text.trim().isNotEmpty) 'descriptionEn': descEnCtrl.text.trim(),
                if (licenseExpiry != null)
                  'licenseExpiry': DateFormat('yyyy-MM-dd').format(licenseExpiry!),
                if (insuranceExpiry != null)
                  'insuranceExpiry': DateFormat('yyyy-MM-dd').format(insuranceExpiry!),
                'photos': photos,
                if (photos.isNotEmpty) 'logoUrl': photos.first,
                if (videoCtrl.text.trim().isNotEmpty) 'videoUrl': videoCtrl.text.trim(),
              };
              try {
                if (isEdit) {
                  await AdminApiService.updateOperator(op['id'], data);
                } else {
                  await AdminApiService.createOperator(data);
                }
                _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Operator updated' : 'Operator created'), backgroundColor: AdminColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black),
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AdminColors.surfaceDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.primary)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Operators', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  const Text('Manage balloon flight operators', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
                ],
              ),
              Row(children: [
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
                const SizedBox(width: 8),
                ElevatedButton.icon(onPressed: () => _showEditDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Operator')),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AdminColors.border, height: 1),
      ErrorBanner(error: _error, onRetry: _load),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
              : _operators.isEmpty
                  ? const Center(child: Text('No operators found.', style: TextStyle(color: AdminColors.textMuted)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
                        child: DataTable(
                          columnSpacing: 16,
                          columns: const [
                            DataColumn(label: Text('NAME')),
                            DataColumn(label: Text('EMAIL')),
                            DataColumn(label: Text('PHONE')),
                            DataColumn(label: Text('RATING')),
                            DataColumn(label: Text('FLIGHTS')),
                            DataColumn(label: Text('COMMISSION')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: _operators.map<DataRow>((op) {
                            final status = (op['status'] ?? 'pending').toString();
                            final statusColor = status == 'verified' ? AdminColors.success : status == 'suspended' ? AdminColors.error : AdminColors.warning;
                            return DataRow(cells: [
                              DataCell(Text(op['nameEn'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                              DataCell(Text(op['email'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text(op['phone'] ?? '-', style: const TextStyle(fontSize: 12))),
                              DataCell(Text('${op['rating'] ?? 0} ⭐', style: const TextStyle(fontSize: 12))),
                              DataCell(Text('${op['totalFlights'] ?? 0}')),
                              DataCell(Text('${op['commissionRate'] ?? 10}%', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              )),
                              DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), tooltip: 'Edit', onPressed: () => _showEditDialog(op)),
                                if (status == 'pending')
                                  IconButton(
                                    icon: const Icon(Icons.verified_outlined, color: AdminColors.success, size: 18),
                                    tooltip: 'Verify',
                                    onPressed: () async {
                                      try {
                                        await AdminApiService.verifyOperator(op['id']);
                                        _load();
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operator verified!'), backgroundColor: AdminColors.success));
                                      } catch (e) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                                      }
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                      backgroundColor: AdminColors.cardDark,
                                      title: const Text('Delete Operator?', style: TextStyle(color: AdminColors.error)),
                                      content: Text('Delete ${op['nameEn']}? This cannot be undone.', style: const TextStyle(color: AdminColors.textSecondary)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error), child: const Text('Delete')),
                                      ],
                                    ));
                                    if (confirm == true) {
                                      try {
                                        await AdminApiService.deleteOperator(op['id']);
                                        _load();
                                      } catch (e) {
                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                                      }
                                    }
                                  },
                                ),
                              ])),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
