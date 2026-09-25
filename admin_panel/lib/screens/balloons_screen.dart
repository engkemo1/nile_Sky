import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../widgets/operator_picker.dart';
import '../widgets/admin_form.dart';
import '../widgets/media_manager.dart';
import '../services/admin_language_service.dart';

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

  /// Must match BalloonStatus in balloon.entity.ts exactly, or the save 400s.
  static const List<String> _statuses = [
    'available',
    'in_flight',
    'maintenance',
    'retired',
  ];

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

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

  /// Postgres `date` columns come back as 'yyyy-MM-dd' (sometimes with a time
  /// part), so take the first 10 characters and parse that.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    if (s.length < 10) return null;
    return DateTime.tryParse(s.substring(0, 10));
  }

  /// Red once an expiry is past or less than 30 days away, amber inside 90
  /// days. An expired insurance has to be obvious from the list.
  static Color _expiryColor(DateTime? date) {
    if (date == null) return AdminColors.textMuted;
    final days = date.difference(DateTime.now()).inDays;
    if (days <= 30) return AdminColors.error;
    if (days <= 90) return AdminColors.warning;
    return AdminColors.textPrimary;
  }

  Widget _dateField(
    BuildContext ctx,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onPicked,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
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
              child: Text(
                value == null ? 'Not set' : _apiDate.format(value),
                style: TextStyle(
                  color: value == null
                      ? AdminColors.textMuted
                      : AdminColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 16, color: AdminColors.textMuted),
            tooltip: 'Clear',
            onPressed: () => onPicked(null),
          ),
      ]),
    );
  }

  void _showEditDialog([Map<String, dynamic>? b]) {
    final regCtrl = TextEditingController(text: b?['registrationCode'] ?? '');
    final nameCtrl = TextEditingController(text: b?['name'] ?? '');
    final capCtrl = TextEditingController(text: (b?['capacity'] ?? 16).toString());
    final notesCtrl = TextEditingController(text: b?['notes']?.toString() ?? '');
    final videoCtrl = TextEditingController(text: b?['videoUrl']?.toString() ?? '');

    String? selectedOperatorId = b?['operatorId']?.toString() ??
        (_operators.isNotEmpty ? _operators.first['id']?.toString() : null);

    String status = b?['status']?.toString() ?? 'available';
    if (!_statuses.contains(status)) status = 'available';

    DateTime? lastInspection = _parseDate(b?['lastInspection']);
    DateTime? insuranceExpiry = _parseDate(b?['insuranceExpiry']);

    List<String> photos = [];
    final rawPhotos = b?['photos'];
    if (rawPhotos is List) {
      photos = rawPhotos.map((e) => e.toString()).toList();
    }

    final isEdit = b != null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit
            ? 'Edit ${b?['name'] ?? b?['registrationCode'] ?? 'Balloon'}'
            : 'Add Balloon',
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (sctx, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OperatorPicker(
                  operators: _operators,
                  value: selectedOperatorId,
                  onChanged: (v) => setLocal(() => selectedOperatorId = v),
                ),
                AdminTextField(label: 'Registration Code', controller: regCtrl),
                AdminTextField(label: 'Name', controller: nameCtrl),
                AdminTextField(
                  label: 'Capacity',
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                ),
                AdminDropdown(
                  label: 'Status',
                  value: status,
                  items: _statuses
                      .map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) => setLocal(() => status = v ?? status),
                ),
                _dateField(
                  sctx,
                  'Last Inspection',
                  lastInspection,
                  (d) => setLocal(() => lastInspection = d),
                ),
                _dateField(
                  sctx,
                  'Insurance Expiry',
                  insuranceExpiry,
                  (d) => setLocal(() => insuranceExpiry = d),
                ),
                AdminTextField(
                  label: 'Notes (maintenance log)',
                  controller: notesCtrl,
                  maxLines: 4,
                ),
                MediaManager(
                  urls: photos,
                  folder: 'balloons',
                  onChanged: (next) => setLocal(() => photos = next),
                ),
                AdminTextField(
                  label: 'Video URL (optional)',
                  controller: videoCtrl,
                  hint: 'https://…',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
        ElevatedButton(
          onPressed: () async {
            if (selectedOperatorId == null) {
              showSnack(context, 'Select an operator first', error: true);
              return;
            }
            if (regCtrl.text.trim().isEmpty) {
              showSnack(context, 'Registration code is required', error: true);
              return;
            }
            Navigator.pop(ctx);
            final data = <String, dynamic>{
              'registrationCode': regCtrl.text.trim(),
              'capacity': int.tryParse(capCtrl.text.trim()) ?? 16,
              'operatorId': selectedOperatorId,
              'status': status,
              'photos': photos,
              // @IsOptional() only skips null/undefined, so '' would fail
              // validation: blank optional strings are omitted entirely.
              if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
              if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
              if (videoCtrl.text.trim().isNotEmpty) 'videoUrl': videoCtrl.text.trim(),
              if (lastInspection != null)
                'lastInspection': _apiDate.format(lastInspection!),
              if (insuranceExpiry != null)
                'insuranceExpiry': _apiDate.format(insuranceExpiry!),
            };
            try {
              if (isEdit) {
                await AdminApiService.updateBalloon(b!['id'].toString(), data);
              } else {
                await AdminApiService.createBalloon(data);
              }
              _load();
              if (mounted) showSnack(context, isEdit ? 'Updated' : 'Created');
            } catch (e) {
              if (mounted) {
                showSnack(
                  context,
                  'Error: ${e.toString().replaceFirst('ApiException: ', '')}',
                  error: true,
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black),
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(28, 28, 28, 0), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AdminLanguageService.tr('balloonsTitle'), style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 4),
            Text(
              AdminLanguageService.isArabic ? 'إدارة أسطول البالونات وفحوصات السلامة' : 'Manage balloon fleet & inspections',
              style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13),
            ),
          ]),
          Row(children: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showEditDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AdminLanguageService.tr('addBalloon')),
            ),
          ]),
        ],
      )),
      const SizedBox(height: 16), const Divider(color: AdminColors.border, height: 1),
      ErrorBanner(error: _error, onRetry: _load),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
        : _balloons.isEmpty ? Center(child: Text(AdminLanguageService.isArabic ? 'لا توجد بالونات مسجلة حتى الآن.' : 'No balloons found.', style: const TextStyle(color: AdminColors.textMuted)))
        : SingleChildScrollView(padding: const EdgeInsets.all(28), child: Container(
            width: double.infinity, decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            child: DataTable(columnSpacing: 20, columns: [
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'رقم التسجيل' : 'REG CODE')),
              DataColumn(label: Text(AdminLanguageService.tr('name'))),
              DataColumn(label: Text(AdminLanguageService.tr('operator'))),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'السعة' : 'CAPACITY')),
              DataColumn(label: Text(AdminLanguageService.tr('status'))),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'التأمين' : 'INSURANCE')),
              DataColumn(label: Text(AdminLanguageService.tr('actions'))),
            ], rows: _balloons.map<DataRow>((b) {
              final status = (b['status'] ?? 'available').toString();
              final statusColor = status == 'available' ? AdminColors.success : status == 'in_flight' ? AdminColors.info : status == 'maintenance' ? AdminColors.warning : AdminColors.error;
              final insurance = _parseDate(b['insuranceExpiry']);
              final insuranceColor = _expiryColor(insurance);
              return DataRow(cells: [
                DataCell(Text(b['registrationCode'] ?? '-', style: const TextStyle(color: AdminColors.secondary, fontWeight: FontWeight.w600, fontSize: 12))),
                DataCell(Text(b['name'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(b['operator']?['nameEn'] ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text('${b['capacity'] ?? 0} pax', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  if (insurance != null && insuranceColor != AdminColors.textPrimary)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.warning_amber_rounded, size: 14, color: insuranceColor),
                    ),
                  Text(
                    insurance == null ? 'Not set' : _apiDate.format(insurance),
                    style: TextStyle(
                      color: insuranceColor,
                      fontSize: 12,
                      fontWeight: insuranceColor == AdminColors.error
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ])),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), tooltip: 'Edit', onPressed: () => _showEditDialog(b)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), tooltip: 'Delete', onPressed: () async {
                    final ok = await confirmDelete(
                      context,
                      (b['registrationCode'] ?? b['name'] ?? 'this balloon').toString(),
                    );
                    if (!ok) return;
                    try {
                      await AdminApiService.deleteBalloon(b['id'].toString());
                      _load();
                    } catch (e) {
                      if (mounted) {
                        showSnack(
                          context,
                          'Error: ${e.toString().replaceFirst('ApiException: ', '')}',
                          error: true,
                        );
                      }
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
