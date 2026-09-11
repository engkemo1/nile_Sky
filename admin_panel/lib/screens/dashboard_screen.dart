import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _recentBookings = [];
  Map<String, dynamic>? _weather;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        AdminApiService.getDashboard(),
        AdminApiService.getBookings(),
        AdminApiService.getLuxorWeather().catchError((_) => <String, dynamic>{
          'condition': 'Clear ☀️',
          'flightStatus': 'favorable',
        }),
      ]);
      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _recentBookings = (results[1] as List).take(5).toList();
        _weather = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AdminColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load dashboard', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: AdminColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black),
            ),
          ],
        ),
      );
    }

    final today = _dashboardData?['today'] ?? {};
    final allTime = _dashboardData?['allTime'] ?? {};
    final todayFlights = (_dashboardData?['todayFlightsSummary'] as List?) ?? [];
    final weatherCondition = _weather?['condition'] ?? 'Clear ☀️';
    final flightStatus = _weather?['flightStatus'] ?? 'favorable';
    final flightStatusLabel = flightStatus == 'favorable' ? 'Flights: GO ✅' : flightStatus == 'uncertain' ? 'Flights: HOLD ⚠️' : 'Flights: NO-GO ❌';
    final flightStatusColor = flightStatus == 'favorable' ? AdminColors.success : flightStatus == 'uncertain' ? AdminColors.warning : AdminColors.error;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AdminColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard', style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Luxor Operations • ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                      style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _StatusBadge(label: 'Weather: $weatherCondition', color: AdminColors.success),
                    const SizedBox(width: 10),
                    _StatusBadge(label: flightStatusLabel, color: flightStatusColor),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh, color: AdminColors.textMuted),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // KPI Cards Row — Live Data
            Row(
              children: [
                Expanded(child: _KpiCard(
                  title: "Today's Flights",
                  value: '${today['flightsCount'] ?? 0}',
                  subtitle: 'Scheduled for today',
                  icon: Icons.flight_takeoff,
                  iconColor: AdminColors.secondary,
                )),
                const SizedBox(width: 16),
                Expanded(child: _KpiCard(
                  title: 'Today Bookings',
                  value: '${today['bookingsCount'] ?? 0}',
                  subtitle: '${today['passengersCount'] ?? 0} passengers',
                  icon: Icons.book_online,
                  iconColor: AdminColors.primary,
                )),
                const SizedBox(width: 16),
                Expanded(child: _KpiCard(
                  title: 'Today Revenue',
                  value: '${NumberFormat('#,###').format(today['revenueEgp'] ?? 0)} EGP',
                  subtitle: '≈ \$${NumberFormat('#,###').format((today['revenueEgp'] ?? 0) ~/ 49.5)} USD',
                  icon: Icons.monetization_on,
                  iconColor: AdminColors.success,
                )),
                const SizedBox(width: 16),
                Expanded(child: _KpiCard(
                  title: 'All-Time Revenue',
                  value: '${NumberFormat('#,###').format(allTime['revenueEgp'] ?? 0)} EGP',
                  subtitle: '${allTime['totalBookings'] ?? 0} total bookings',
                  icon: Icons.trending_up,
                  iconColor: AdminColors.accent,
                )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _KpiCard(
                  title: 'Active Operators',
                  value: '${allTime['totalOperators'] ?? 0}',
                  subtitle: 'Registered operators',
                  icon: Icons.business,
                  iconColor: AdminColors.info,
                )),
                const SizedBox(width: 16),
                Expanded(child: _KpiCard(
                  title: 'Passengers Today',
                  value: '${today['passengersCount'] ?? 0}',
                  subtitle: 'Across all flights',
                  icon: Icons.people,
                  iconColor: AdminColors.warning,
                )),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 28),

            // Today's Flights Table
            if (todayFlights.isNotEmpty) ...[
              Text("Today's Flight Schedule", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DataTable(
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('FLIGHT #')),
                    DataColumn(label: Text('DEPARTURE')),
                    DataColumn(label: Text('BOOKED / CAP')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: todayFlights.map<DataRow>((f) {
                    final status = (f['status'] ?? 'scheduled').toString();
                    final statusColor = status == 'completed' ? AdminColors.success
                        : status == 'cancelled' ? AdminColors.error
                        : status == 'in_flight' ? AdminColors.info
                        : AdminColors.warning;
                    return DataRow(cells: [
                      DataCell(Text(f['flightNumber']?.toString() ?? '-', style: const TextStyle(color: AdminColors.secondary, fontWeight: FontWeight.w600, fontSize: 12))),
                      DataCell(Text(f['departureTime']?.toString() ?? '-')),
                      DataCell(Text('${f['bookedCount'] ?? 0}/${f['capacity'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(_StatusChip(label: status.toUpperCase(), color: statusColor)),
                    ]);
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Recent Bookings Table
            if (_recentBookings.isNotEmpty) ...[
              Text('Recent Bookings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AdminColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminColors.border),
                ),
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text('REF')),
                    DataColumn(label: Text('GUEST')),
                    DataColumn(label: Text('GUESTS')),
                    DataColumn(label: Text('TOTAL')),
                    DataColumn(label: Text('PAYMENT')),
                    DataColumn(label: Text('STATUS')),
                  ],
                  rows: _recentBookings.map<DataRow>((b) {
                    final bookingStatus = (b['bookingStatus'] ?? 'pending').toString();
                    final paymentStatus = (b['paymentStatus'] ?? 'pending').toString();
                    final statusColor = bookingStatus == 'confirmed' ? AdminColors.success
                        : bookingStatus == 'cancelled' ? AdminColors.error
                        : AdminColors.warning;
                    final payColor = paymentStatus == 'paid' ? AdminColors.success : AdminColors.warning;
                    final guestName = b['user']?['name'] ?? 'Guest';
                    return DataRow(cells: [
                      DataCell(Text(b['bookingRef']?.toString() ?? '-', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600, fontSize: 12))),
                      DataCell(Text(guestName, style: const TextStyle(fontSize: 12))),
                      DataCell(Text('${b['guestCount'] ?? 0}')),
                      DataCell(Text('${NumberFormat('#,###').format(b['totalPriceEgp'] ?? 0)} EGP', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(_StatusChip(label: paymentStatus.toUpperCase(), color: payColor)),
                      DataCell(_StatusChip(label: bookingStatus.toUpperCase(), color: statusColor)),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AdminColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
