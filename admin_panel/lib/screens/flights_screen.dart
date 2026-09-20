import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../utils/num_parse.dart';
import '../widgets/admin_form.dart';
import '../widgets/flight_editor.dart';

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _flights = [];
  List<dynamic> _operators = [];
  List<dynamic> _packages = [];
  List<dynamic> _balloons = [];
  List<dynamic> _pilots = [];
  List<dynamic> _templates = [];
  bool _templatesLoading = true;
  String? _templatesError;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFlights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        AdminApiService.getFlights(),
        AdminApiService.getOperators(),
        AdminApiService.getPackages(),
        AdminApiService.getBalloons(),
        AdminApiService.getPilots(),
      ]);
      if (!mounted) return;
      setState(() {
        _flights = results[0];
        _operators = results[1];
        _packages = results[2];
        _balloons = results[3];
        _pilots = results[4];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _isLoading = false;
      });
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() { _templatesLoading = true; _templatesError = null; });
    try {
      final data = await AdminApiService.getFlightTemplates();
      if (!mounted) return;
      setState(() { _templates = data; _templatesLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _templatesError = e.toString().replaceFirst('ApiException: ', '');
        _templatesLoading = false;
      });
    }
  }

  /// Opens the add/edit dialog. [flight] null means create.
  Future<void> _openEditor([Map<String, dynamic>? flight]) async {
    if (_operators.isEmpty || _packages.isEmpty) {
      showSnack(context,
          'Add at least one operator and one package before creating flights.',
          error: true);
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => FlightEditor(
        flight: flight,
        operators: _operators,
        packages: _packages,
        balloons: _balloons,
        pilots: _pilots,
      ),
    );
    if (saved == true) {
      if (mounted) showSnack(context, flight == null ? 'Flight created' : 'Flight updated');
      _loadFlights();
    }
  }

  Future<void> _deleteFlight(Map<String, dynamic> flight) async {
    final ok = await confirmDelete(context, 'flight ${flight['flightNumber']}');
    if (!ok) return;
    try {
      await AdminApiService.deleteFlight(flight['id'].toString());
      if (mounted) showSnack(context, 'Flight deleted');
      _loadFlights();
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString().replaceFirst('ApiException: ', ''), error: true);
      }
    }
  }

  void _showStatusDialog(Map<String, dynamic> flight) {
    final statuses = ['scheduled', 'boarding', 'in_flight', 'landed', 'completed', 'cancelled'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Flight ${flight['flightNumber']}', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((s) {
            final isActive = flight['status'] == s;
            return ListTile(
              dense: true,
              title: Text(s.toUpperCase(), style: TextStyle(color: isActive ? AdminColors.primary : AdminColors.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              leading: Icon(isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isActive ? AdminColors.primary : AdminColors.textMuted, size: 18),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await AdminApiService.updateFlightStatus(flight['id'], s);
                  _loadFlights();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Flight status updated to $s'), backgroundColor: AdminColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCancelDialog(Map<String, dynamic> flight) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Flight ${flight['flightNumber']}?', style: const TextStyle(color: AdminColors.error, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will cancel all associated bookings.', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cancellation reason (e.g., Weather)',
                hintStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AdminColors.surfaceDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AdminApiService.updateFlightStatus(flight['id'], 'cancelled', reason: reasonController.text.isNotEmpty ? reasonController.text : 'Cancelled by admin');
                _loadFlights();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flight cancelled'), backgroundColor: AdminColors.error));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPassengerManifest(Map<String, dynamic> flight) async {
    try {
      final bookings = await AdminApiService.getBookings(flightId: flight['id']);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AdminColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Passenger Manifest — ${flight['flightNumber']}', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: 600,
            child: bookings.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No bookings for this flight.', style: TextStyle(color: AdminColors.textMuted)),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('REF')),
                        DataColumn(label: Text('GUEST')),
                        DataColumn(label: Text('HOTEL')),
                        DataColumn(label: Text('GUESTS')),
                        DataColumn(label: Text('STATUS')),
                        DataColumn(label: Text('CHECK-IN')),
                      ],
                      rows: bookings.map<DataRow>((b) {
                        final status = b['bookingStatus']?.toString() ?? 'pending';
                        final isCheckedIn = status == 'checked_in';
                        return DataRow(cells: [
                          DataCell(Text(b['bookingRef']?.toString() ?? '-', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600, fontSize: 11))),
                          DataCell(Text(b['user']?['name'] ?? 'Guest', style: const TextStyle(fontSize: 12))),
                          DataCell(Text(b['pickupHotelName'] ?? '-', style: const TextStyle(fontSize: 12))),
                          DataCell(Text('${b['guestCount'] ?? 0}')),
                          DataCell(Text(status.toUpperCase(), style: TextStyle(color: isCheckedIn ? AdminColors.success : AdminColors.warning, fontSize: 11, fontWeight: FontWeight.w600))),
                          DataCell(
                            IconButton(
                              icon: Icon(isCheckedIn ? Icons.check_circle : Icons.radio_button_unchecked, color: isCheckedIn ? AdminColors.success : AdminColors.textMuted, size: 18),
                              onPressed: isCheckedIn ? null : () async {
                                Navigator.pop(ctx);
                                try {
                                  await AdminApiService.checkInBooking(b['bookingRef']);
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passenger checked in!'), backgroundColor: AdminColors.success));
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                                }
                              },
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AdminColors.primary))),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading manifest: $e'), backgroundColor: AdminColors.error));
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
                  Text('Flight Management', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  const Text('Manage schedule & passenger manifests', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  IconButton(onPressed: _loadFlights, icon: const Icon(Icons.refresh, color: AdminColors.textMuted), tooltip: 'Refresh'),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
                      try {
                        final result = await AdminApiService.generateFlights(tomorrow);
                        _loadFlights();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Flights generated for $tomorrow'), backgroundColor: AdminColors.success));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                      }
                    },
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generate Tomorrow\'s Flights'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Flight'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AdminColors.primary,
            labelColor: AdminColors.primary,
            unselectedLabelColor: AdminColors.textMuted,
            isScrollable: true,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: '📅 Flight Schedule'),
              Tab(text: '🔄 Flight Templates'),
            ],
          ),
        ),
        const Divider(color: AdminColors.border, height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFlightSchedule(),
              _buildFlightTemplates(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlightSchedule() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
    if (_error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Error: $_error', style: const TextStyle(color: AdminColors.error, fontSize: 12)),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _loadFlights, child: const Text('Retry')),
    ]));
    if (_flights.isEmpty) return const Center(child: Text('No flights found.', style: TextStyle(color: AdminColors.textMuted)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AdminColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('FLIGHT #')),
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('TIME')),
            DataColumn(label: Text('BOOKED/CAP')),
            DataColumn(label: Text('PRICE')),
            DataColumn(label: Text('WEATHER')),
            DataColumn(label: Text('MEDIA')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: _flights.map<DataRow>((f) {
            final status = (f['status'] ?? 'scheduled').toString();
            final weatherStatus = (f['weatherStatus'] ?? 'favorable').toString();
            final statusColor = status == 'completed' ? AdminColors.success
                : status == 'cancelled' ? AdminColors.error
                : status == 'in_flight' ? AdminColors.info
                : (f['bookedCount'] ?? 0) >= (f['capacity'] ?? 1) ? AdminColors.warning
                : AdminColors.success;
            final weatherIcon = weatherStatus == 'favorable' ? '☀️' : weatherStatus == 'uncertain' ? '🌤️' : '⛈️';

            return DataRow(cells: [
              DataCell(Text(f['flightNumber']?.toString() ?? '-', style: const TextStyle(color: AdminColors.secondary, fontWeight: FontWeight.w600, fontSize: 12))),
              DataCell(Text(f['flightDate']?.toString().substring(0, 10) ?? '-', style: const TextStyle(fontSize: 12))),
              DataCell(Text(f['departureTime']?.toString().substring(0, 5) ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text('${f['bookedCount'] ?? 0}/${f['capacity'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text('${asDouble(f['priceEgp']).toStringAsFixed(0)} EGP', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
              DataCell(Text('$weatherIcon $weatherStatus', style: const TextStyle(fontSize: 12))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined, size: 14, color: AdminColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${(f['photos'] is List ? (f['photos'] as List).length : 0)}',
                      style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary)),
                  if ((f['videoUrl']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.videocam, size: 14, color: AdminColors.secondary),
                  ],
                ],
              )),
              DataCell(InkWell(
                onTap: () => _showStatusDialog(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.people_outline, color: AdminColors.primary, size: 18), tooltip: 'Passenger Manifest', onPressed: () => _showPassengerManifest(f)),
                  IconButton(icon: const Icon(Icons.edit_outlined, color: AdminColors.secondary, size: 18), tooltip: 'Edit flight', onPressed: () => _openEditor(Map<String, dynamic>.from(f))),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 18), tooltip: 'Delete flight', onPressed: () => _deleteFlight(Map<String, dynamic>.from(f))),
                  if (status != 'cancelled' && status != 'completed')
                    IconButton(icon: const Icon(Icons.cancel_outlined, color: AdminColors.error, size: 18), tooltip: 'Cancel Flight', onPressed: () => _showCancelDialog(f)),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ───────── Flight templates (real data, was three hardcoded rows) ─────────

  Future<void> _openTemplateEditor([Map<String, dynamic>? tpl]) async {
    if (_operators.isEmpty || _packages.isEmpty) {
      showSnack(context, 'Add an operator and a package first.', error: true);
      return;
    }
    final timeCtrl = TextEditingController(
        text: tpl?['departureTime']?.toString() ?? '06:15:00');
    final capCtrl =
        TextEditingController(text: (tpl?['capacity'] ?? 16).toString());
    String? operatorId = tpl?['operatorId']?.toString() ??
        _operators.first['id']?.toString();
    String? packageId =
        tpl?['packageId']?.toString() ?? _packages.first['id']?.toString();
    String recurrence = tpl?['recurrence']?.toString() ?? 'daily';
    bool isActive = tpl?['isActive'] != false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AdminColors.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(tpl == null ? 'Add Template' : 'Edit Template',
              style: const TextStyle(
                  color: AdminColors.textPrimary, fontSize: 16)),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminDropdown(
                    label: 'Operator',
                    value: operatorId,
                    items: itemsFrom(_operators),
                    onChanged: (v) => setLocal(() => operatorId = v),
                  ),
                  AdminDropdown(
                    label: 'Package',
                    value: packageId,
                    items: itemsFrom(_packages),
                    onChanged: (v) => setLocal(() => packageId = v),
                  ),
                  AdminTextField(
                      label: 'Departure Time',
                      controller: timeCtrl,
                      hint: '06:15:00'),
                  AdminTextField(
                      label: 'Capacity',
                      controller: capCtrl,
                      keyboardType: TextInputType.number),
                  AdminDropdown(
                    label: 'Recurrence',
                    value: recurrence,
                    items: const ['daily', 'weekdays', 'weekends', 'custom']
                        .map((r) => DropdownMenuItem(
                            value: r, child: Text(r.toUpperCase())))
                        .toList(),
                    onChanged: (v) => setLocal(() => recurrence = v ?? 'daily'),
                  ),
                  SwitchListTile(
                    value: isActive,
                    onChanged: (v) => setLocal(() => isActive = v),
                    title: const Text('Active',
                        style: TextStyle(
                            color: AdminColors.textPrimary, fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AdminColors.textMuted))),
            ElevatedButton(
              onPressed: () async {
                final cap = int.tryParse(capCtrl.text.trim());
                if (operatorId == null || packageId == null || cap == null) {
                  showSnack(ctx, 'Operator, package and a numeric capacity are required.',
                      error: true);
                  return;
                }
                Navigator.pop(ctx);
                final body = {
                  'operatorId': operatorId,
                  'packageId': packageId,
                  'departureTime': timeCtrl.text.trim(),
                  'capacity': cap,
                  'recurrence': recurrence,
                  'isActive': isActive,
                };
                try {
                  if (tpl == null) {
                    await AdminApiService.createFlightTemplate(body);
                  } else {
                    await AdminApiService.updateFlightTemplate(
                        tpl['id'].toString(), body);
                  }
                  if (mounted) {
                    showSnack(context,
                        tpl == null ? 'Template created' : 'Template updated');
                  }
                  _loadTemplates();
                } catch (e) {
                  if (mounted) {
                    showSnack(
                        context,
                        e.toString().replaceFirst('ApiException: ', ''),
                        error: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.black),
              child: Text(tpl == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTemplate(Map<String, dynamic> tpl) async {
    final ok = await confirmDelete(context, 'this template');
    if (!ok) return;
    try {
      await AdminApiService.deleteFlightTemplate(tpl['id'].toString());
      if (mounted) showSnack(context, 'Template deleted');
      _loadTemplates();
    } catch (e) {
      if (mounted) {
        showSnack(context, e.toString().replaceFirst('ApiException: ', ''),
            error: true);
      }
    }
  }

  String _operatorName(String? id) {
    if (id == null) return '-';
    final match = _operators.where((o) => o['id']?.toString() == id);
    if (match.isEmpty) return '-';
    return (match.first['nameEn'] ?? match.first['nameAr'] ?? '-').toString();
  }

  String _packageName(String? id) {
    if (id == null) return '-';
    final match = _packages.where((p) => p['id']?.toString() == id);
    if (match.isEmpty) return '-';
    return (match.first['nameEn'] ?? '-').toString();
  }

  Widget _buildFlightTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Templates generate the daily schedule. "Generate Tomorrow\'s Flights" builds flights from every active template.',
                  style: TextStyle(
                      color: AdminColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                  onPressed: _loadTemplates,
                  icon: const Icon(Icons.refresh,
                      color: AdminColors.textMuted),
                  tooltip: 'Refresh'),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _openTemplateEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Template'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListState(
            loading: _templatesLoading,
            error: _templatesError,
            empty: _templates.isEmpty,
            emptyMessage: 'No flight templates yet.',
            onRetry: _loadTemplates,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('OPERATOR')),
                    DataColumn(label: Text('PACKAGE')),
                    DataColumn(label: Text('TIME')),
                    DataColumn(label: Text('CAPACITY')),
                    DataColumn(label: Text('RECURRENCE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: _templates.map<DataRow>((t) {
                    final active = t['isActive'] != false;
                    return DataRow(cells: [
                      DataCell(Text(
                          t['operator']?['nameEn']?.toString() ??
                              _operatorName(t['operatorId']?.toString()),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                          t['package']?['nameEn']?.toString() ??
                              _packageName(t['packageId']?.toString()),
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(
                          t['departureTime']?.toString() ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(Text('${t['capacity'] ?? 0}')),
                      DataCell(Text(
                          (t['recurrence'] ?? 'daily')
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(fontSize: 11))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (active
                                  ? AdminColors.success
                                  : AdminColors.warning)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(active ? 'ACTIVE' : 'PAUSED',
                            style: TextStyle(
                                color: active
                                    ? AdminColors.success
                                    : AdminColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AdminColors.secondary, size: 18),
                              tooltip: 'Edit',
                              onPressed: () => _openTemplateEditor(
                                  Map<String, dynamic>.from(t))),
                          IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: AdminColors.error, size: 18),
                              tooltip: 'Delete',
                              onPressed: () => _deleteTemplate(
                                  Map<String, dynamic>.from(t))),
                        ],
                      )),
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
