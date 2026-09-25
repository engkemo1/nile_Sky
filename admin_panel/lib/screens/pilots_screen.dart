import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../utils/num_parse.dart';
import '../widgets/operator_picker.dart';
import '../widgets/admin_form.dart';
import '../widgets/media_manager.dart';
import '../services/admin_language_service.dart';

class PilotsScreen extends StatefulWidget {
  const PilotsScreen({super.key});
  @override
  State<PilotsScreen> createState() => _PilotsScreenState();
}

class _PilotsScreenState extends State<PilotsScreen> {
  List<dynamic> _pilots = [];
  List<dynamic> _operators = [];
  bool _isLoading = true;
  String? _error;

  /// Must match PilotStatus in pilot.entity.ts exactly, or the save 400s.
  static const List<String> _statuses = ['active', 'on_leave', 'inactive'];

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _pilots = await AdminApiService.getPilots();
      _error = null;
    } catch (e) {
      _error = 'Could not load pilots: '
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

  /// Red once a licence is past or less than 30 days from expiry, amber inside
  /// 90 days. A lapsed ECAA licence has to be obvious from the list.
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

  void _showEditDialog([Map<String, dynamic>? p]) {
    final nameEnCtrl = TextEditingController(text: p?['nameEn'] ?? '');
    final nameArCtrl = TextEditingController(text: p?['nameAr'] ?? '');
    final licenseCtrl = TextEditingController(text: p?['licenseNumber'] ?? '');
    final expCtrl = TextEditingController(text: (p?['experienceYears'] ?? 0).toString());

    String? selectedOperatorId = p?['operatorId']?.toString() ??
        (_operators.isNotEmpty ? _operators.first['id']?.toString() : null);

    String status = p?['status']?.toString() ?? 'active';
    if (!_statuses.contains(status)) status = 'active';

    DateTime? licenseExpiry = _parseDate(p?['licenseExpiry']);

    // photoUrl is a single string on the backend, so the manager is capped at
    // one file and the first url is what gets sent.
    List<String> photo = [];
    final rawPhoto = p?['photoUrl'];
    if (rawPhoto != null && rawPhoto.toString().trim().isNotEmpty) {
      photo = <String>[rawPhoto.toString()];
    }

    final isEdit = p != null;

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AdminColors.cardDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Pilot' : 'Add Pilot', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
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
                AdminTextField(label: 'Name (EN)', controller: nameEnCtrl),
                AdminTextField(label: 'Name (AR)', controller: nameArCtrl),
                AdminTextField(label: 'License #', controller: licenseCtrl),
                _dateField(
                  sctx,
                  'Licence Expiry (ECAA)',
                  licenseExpiry,
                  (d) => setLocal(() => licenseExpiry = d),
                ),
                AdminTextField(
                  label: 'Experience (Years)',
                  controller: expCtrl,
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
                MediaManager(
                  urls: photo,
                  folder: 'pilots',
                  maxFiles: 1,
                  onChanged: (next) => setLocal(() => photo = next),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
        ElevatedButton(onPressed: () async {
          if (selectedOperatorId == null) {
            showSnack(context, 'Select an operator first', error: true);
            return;
          }
          if (nameEnCtrl.text.trim().isEmpty) {
            showSnack(context, 'Name (EN) is required', error: true);
            return;
          }
          Navigator.pop(ctx);
          final data = <String, dynamic>{
            'nameEn': nameEnCtrl.text.trim(),
            'experienceYears': int.tryParse(expCtrl.text.trim()) ?? 0,
            'operatorId': selectedOperatorId,
            'status': status,
            // @IsOptional() only skips null/undefined, so '' would fail
            // validation: blank optional strings are omitted entirely.
            if (nameArCtrl.text.trim().isNotEmpty) 'nameAr': nameArCtrl.text.trim(),
            if (licenseCtrl.text.trim().isNotEmpty) 'licenseNumber': licenseCtrl.text.trim(),
            if (photo.isNotEmpty) 'photoUrl': photo.first,
            if (licenseExpiry != null)
              'licenseExpiry': _apiDate.format(licenseExpiry!),
          };
          try {
            if (isEdit) {
              await AdminApiService.updatePilot(p!['id'].toString(), data);
            } else {
              await AdminApiService.createPilot(data);
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
        }, style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black), child: Text(isEdit ? 'Save' : 'Create')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(28, 28, 28, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AdminLanguageService.tr('pilotsTitle'), style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          Text(
            AdminLanguageService.isArabic ? 'إدارة طياري وكباتن المنطاد والتراخيص' : 'Manage pilot assignments & licensing',
            style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13),
          ),
        ]),
        Row(children: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showEditDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: Text(AdminLanguageService.tr('addPilot')),
          ),
        ]),
      ])),
      const SizedBox(height: 16), const Divider(color: AdminColors.border, height: 1),
      ErrorBanner(error: _error, onRetry: _load),
      Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
        : _pilots.isEmpty ? Center(child: Text(AdminLanguageService.isArabic ? 'لا يوجد طيارون مسجلون حتى الآن.' : 'No pilots found.', style: const TextStyle(color: AdminColors.textMuted)))
        : SingleChildScrollView(padding: const EdgeInsets.all(28), child: Container(
            width: double.infinity, decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            child: DataTable(columnSpacing: 20, columns: [
              DataColumn(label: Text(AdminLanguageService.tr('name'))),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'رقم الترخيص' : 'LICENSE')),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'انتهاء الترخيص' : 'LICENCE EXPIRY')),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'الخبرة' : 'EXPERIENCE')),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'الرحلات' : 'FLIGHTS')),
              DataColumn(label: Text(AdminLanguageService.isArabic ? 'التقييم' : 'RATING')),
              DataColumn(label: Text(AdminLanguageService.tr('status'))),
              DataColumn(label: Text(AdminLanguageService.tr('actions'))),
            ], rows: _pilots.map<DataRow>((p) {
              final status = (p['status'] ?? 'active').toString();
              final statusColor = status == 'active' ? AdminColors.success : status == 'on_leave' ? AdminColors.warning : AdminColors.error;
              final expiry = _parseDate(p['licenseExpiry']);
              final expiryColor = _expiryColor(expiry);
              return DataRow(cells: [
                DataCell(Text(p['nameEn'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                DataCell(Text(p['licenseNumber'] ?? '-', style: const TextStyle(color: AdminColors.secondary, fontSize: 12))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  if (expiry != null && expiryColor != AdminColors.textPrimary)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.warning_amber_rounded, size: 14, color: expiryColor),
                    ),
                  Text(
                    expiry == null ? 'Not set' : _apiDate.format(expiry),
                    style: TextStyle(
                      color: expiryColor,
                      fontSize: 12,
                      fontWeight: expiryColor == AdminColors.error
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ])),
                DataCell(Text('${p['experienceYears'] ?? 0} years')),
                DataCell(Text('${p['totalFlights'] ?? 0}')),
                DataCell(Text('${asDouble(p['rating']).toStringAsFixed(1)} ⭐', style: const TextStyle(fontSize: 12))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(status.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)))),
                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), tooltip: 'Edit', onPressed: () => _showEditDialog(p)),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), tooltip: 'Delete', onPressed: () async {
                    final ok = await confirmDelete(
                      context,
                      (p['nameEn'] ?? 'this pilot').toString(),
                    );
                    if (!ok) return;
                    try {
                      await AdminApiService.deletePilot(p['id'].toString());
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
