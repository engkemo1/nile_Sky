import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../utils/num_parse.dart';
import '../widgets/admin_form.dart';
import '../widgets/media_manager.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  static const List<String> _packageTypes = ['standard', 'premium', 'private'];

  List<dynamic> _packages = [];
  List<dynamic> _operators = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminApiService.getPackages(),
        AdminApiService.getOperators(),
      ]);
      if (!mounted) return;
      setState(() {
        _packages = results[0];
        _operators = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load packages: $e';
        _isLoading = false;
      });
    }
  }

  /// Prefers the operator joined onto the package, then falls back to the
  /// operators list, so the column still reads sensibly either way.
  String _operatorName(dynamic pkg) {
    final embedded = pkg['operator'];
    if (embedded is Map) {
      final name = embedded['nameEn'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    final id = pkg['operatorId']?.toString();
    if (id != null) {
      for (final op in _operators) {
        if (op['id']?.toString() == id) {
          final name = op['nameEn'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString();
          }
        }
      }
    }
    return '-';
  }

  /// Decimal columns arrive from Postgres as strings, so every money value
  /// goes through asDouble() before it is formatted.
  String _money(dynamic value) => asDouble(value).toStringAsFixed(2);

  void _showEditDialog([Map<String, dynamic>? pkg]) {
    final isEdit = pkg != null;
    final nameEnCtrl = TextEditingController(text: pkg?['nameEn']?.toString() ?? '');
    final nameArCtrl = TextEditingController(text: pkg?['nameAr']?.toString() ?? '');
    final descEnCtrl = TextEditingController(text: pkg?['descriptionEn']?.toString() ?? '');
    final descArCtrl = TextEditingController(text: pkg?['descriptionAr']?.toString() ?? '');
    final durationCtrl = TextEditingController(text: (pkg?['durationMinutes'] ?? 45).toString());
    final basePriceCtrl =
        TextEditingController(text: pkg == null ? '' : _money(pkg['basePriceEgp']));
    final priceUsdRaw = pkg == null ? null : pkg['priceUsd'];
    final priceUsdCtrl =
        TextEditingController(text: priceUsdRaw == null ? '' : _money(priceUsdRaw));
    final maxGuestsCtrl = TextEditingController(text: pkg?['maxGuestsIfPrivate']?.toString() ?? '');

    final videoCtrl = TextEditingController(text: pkg?['videoUrl']?.toString() ?? '');
    final rawPhotos = pkg?['photos'];
    List<String> photos =
        rawPhotos is List ? rawPhotos.map((e) => e.toString()).toList() : <String>[];

    String? operatorId = pkg?['operatorId']?.toString();
    String type = (pkg?['type'] ?? 'standard').toString();
    bool hasPickup = pkg?['hasPickup'] != false;
    bool hasBreakfast = pkg?['hasBreakfast'] == true;
    bool isPrivate = pkg?['isPrivate'] == true;

    showAdminDialog(
      context: context,
      title: isEdit ? 'Edit Package' : 'Add Package',
      saveLabel: isEdit ? 'Save' : 'Create',
      content: StatefulBuilder(
        builder: (ctx, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminDropdown(
              label: 'Operator',
              value: operatorId,
              items: itemsFrom(_operators),
              onChanged: (v) => setDialogState(() => operatorId = v),
            ),
            AdminTextField(label: 'Name (EN)', controller: nameEnCtrl),
            AdminTextField(label: 'Name (AR)', controller: nameArCtrl),
            AdminDropdown(
              label: 'Type',
              value: type,
              items: _packageTypes
                  .map((t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text('${t[0].toUpperCase()}${t.substring(1)}'),
                      ))
                  .toList(),
              onChanged: (v) => setDialogState(() => type = v ?? 'standard'),
            ),
            AdminTextField(
              label: 'Duration (minutes)',
              controller: durationCtrl,
              keyboardType: TextInputType.number,
            ),
            AdminTextField(
              label: 'Base Price (EGP)',
              controller: basePriceCtrl,
              keyboardType: TextInputType.number,
            ),
            AdminTextField(
              label: 'Price (USD) — optional',
              controller: priceUsdCtrl,
              keyboardType: TextInputType.number,
            ),
            AdminTextField(
              label: 'Description (EN)',
              controller: descEnCtrl,
              maxLines: 3,
            ),
            AdminTextField(
              label: 'Description (AR)',
              controller: descArCtrl,
              maxLines: 3,
            ),
            CheckboxListTile(
              value: hasPickup,
              onChanged: (v) => setDialogState(() => hasPickup = v ?? false),
              activeColor: AdminColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Hotel pickup included',
                  style: TextStyle(color: AdminColors.textPrimary, fontSize: 13)),
            ),
            CheckboxListTile(
              value: hasBreakfast,
              onChanged: (v) => setDialogState(() => hasBreakfast = v ?? false),
              activeColor: AdminColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Breakfast included',
                  style: TextStyle(color: AdminColors.textPrimary, fontSize: 13)),
            ),
            CheckboxListTile(
              value: isPrivate,
              onChanged: (v) => setDialogState(() => isPrivate = v ?? false),
              activeColor: AdminColors.primary,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Private flight',
                  style: TextStyle(color: AdminColors.textPrimary, fontSize: 13)),
            ),
            if (isPrivate)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AdminTextField(
                  label: 'Max guests (private)',
                  controller: maxGuestsCtrl,
                  keyboardType: TextInputType.number,
                ),
              ),
            const SizedBox(height: 12),
            // The package is the customer-facing product page, so it needs its
            // own gallery — the backend stored photos/videoUrl all along.
            MediaManager(
              urls: photos,
              folder: 'packages',
              onChanged: (next) => setDialogState(() => photos = next),
            ),
            AdminTextField(
              label: 'Video URL (optional)',
              controller: videoCtrl,
              hint: 'https://…',
            ),
          ],
        ),
      ),
      onSave: () async {
        final nameEn = nameEnCtrl.text.trim();
        final duration = int.tryParse(durationCtrl.text.trim());
        final basePrice = double.tryParse(basePriceCtrl.text.trim());

        if (operatorId == null || operatorId!.isEmpty) {
          showSnack(context, 'Pick an operator for this package.', error: true);
          return;
        }
        if (nameEn.isEmpty) {
          showSnack(context, 'Name (EN) is required.', error: true);
          return;
        }
        if (duration == null || duration <= 0) {
          showSnack(context, 'Duration must be a number of minutes.', error: true);
          return;
        }
        if (basePrice == null) {
          showSnack(context, 'Base price (EGP) must be a number.', error: true);
          return;
        }

        // @IsOptional() only skips null/undefined, so an empty string still
        // fails validation. Omit blank optional fields entirely.
        final maxGuests = int.tryParse(maxGuestsCtrl.text.trim());
        final priceUsd = double.tryParse(priceUsdCtrl.text.trim());
        final data = <String, dynamic>{
          'operatorId': operatorId,
          'nameEn': nameEn,
          if (nameArCtrl.text.trim().isNotEmpty) 'nameAr': nameArCtrl.text.trim(),
          if (descEnCtrl.text.trim().isNotEmpty) 'descriptionEn': descEnCtrl.text.trim(),
          if (descArCtrl.text.trim().isNotEmpty) 'descriptionAr': descArCtrl.text.trim(),
          'type': type,
          'durationMinutes': duration,
          'hasPickup': hasPickup,
          'hasBreakfast': hasBreakfast,
          'isPrivate': isPrivate,
          if (isPrivate && maxGuests != null) 'maxGuestsIfPrivate': maxGuests,
          'basePriceEgp': basePrice,
          if (priceUsd != null) 'priceUsd': priceUsd,
          // Always sent so removing the last photo actually persists.
          'photos': photos,
          if (videoCtrl.text.trim().isNotEmpty) 'videoUrl': videoCtrl.text.trim(),
          if (photos.isNotEmpty) 'coverPhotoUrl': photos.first,
        };

        try {
          if (pkg != null) {
            await AdminApiService.updatePackage(pkg['id'].toString(), data);
          } else {
            await AdminApiService.createPackage(data);
          }
          await _load();
          if (!mounted) return;
          showSnack(context, isEdit ? 'Package updated' : 'Package created');
        } catch (e) {
          if (!mounted) return;
          showSnack(context, 'Error: $e', error: true);
        }
      },
    );
  }

  Future<void> _delete(Map<String, dynamic> pkg) async {
    final name = pkg['nameEn']?.toString() ?? 'this package';
    final ok = await confirmDelete(context, name);
    if (!ok) return;
    try {
      await AdminApiService.deletePackage(pkg['id'].toString());
      await _load();
      if (!mounted) return;
      showSnack(context, 'Package deleted');
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Error: $e', error: true);
    }
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
                  Text('Packages', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage the flight packages each operator sells',
                    style: TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              Row(children: [
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, color: AdminColors.textMuted),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showEditDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Package'),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AdminColors.border, height: 1),
        Expanded(
          child: ListState(
            loading: _isLoading,
            error: _error,
            empty: _packages.isEmpty,
            emptyMessage: 'No packages found.',
            onRetry: _load,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('NAME (EN)')),
                    DataColumn(label: Text('OPERATOR')),
                    DataColumn(label: Text('DURATION')),
                    DataColumn(label: Text('PRICE')),
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: _packages.map<DataRow>((p) {
                    final pkg = Map<String, dynamic>.from(p as Map);
                    final type = (pkg['type'] ?? 'standard').toString();
                    final typeColor = type == 'premium'
                        ? AdminColors.primary
                        : type == 'private'
                            ? AdminColors.secondary
                            : AdminColors.textSecondary;
                    return DataRow(cells: [
                      DataCell(Text(
                        pkg['nameEn']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      )),
                      DataCell(Text(
                        _operatorName(pkg),
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        '${pkg['durationMinutes'] ?? '-'} min',
                        style: const TextStyle(fontSize: 12),
                      )),
                      DataCell(Text(
                        '${_money(pkg['basePriceEgp'])} EGP',
                        style: const TextStyle(
                          color: AdminColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )),
                      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: AdminColors.secondary, size: 18),
                          tooltip: 'Edit',
                          onPressed: () => _showEditDialog(pkg),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AdminColors.error, size: 18),
                          tooltip: 'Delete',
                          onPressed: () => _delete(pkg),
                        ),
                      ])),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
