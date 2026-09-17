import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _flights = [];
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
      final data = await AdminApiService.getFlights();
      setState(() { _flights = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Generate Tomorrow\'s Flights'),
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
              DataCell(Text('${f['priceEgp'] ?? 0} EGP', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
              DataCell(Text('$weatherIcon $weatherStatus', style: const TextStyle(fontSize: 12))),
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

  Widget _buildFlightTemplates() {
    // Flight templates are generated by the backend — show info
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AdminColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Flight Templates', style: TextStyle(color: AdminColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Flight templates auto-generate daily flights. Use the "Generate Tomorrow\'s Flights" button to create flights from templates.', style: TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            _buildTemplateRow('Sunrise Standard (King Tut)', 'Daily', '06:15 AM', '1,500 EGP', true),
            _buildTemplateRow('Sunrise Premium (Sindbad)', 'Daily', '06:15 AM', '2,200 EGP', true),
            _buildTemplateRow('Private VIP (SkyScape)', 'Daily', '06:00 AM', '9,000 EGP', true),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateRow(String name, String recurrence, String time, String price, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
          Expanded(child: Text(recurrence, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12))),
          Expanded(child: Text(time, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text(price, style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AdminColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(active ? 'Active' : 'Paused', style: TextStyle(color: active ? AdminColors.success : AdminColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
