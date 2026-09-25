import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../services/admin_language_service.dart';
import '../utils/num_parse.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _data;
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminApiService.getDashboard(),
        AdminApiService.getBookings(),
      ]);
      _data = results[0] as Map<String, dynamic>;
      _bookings = results[1] as List;
      _error = null;
    } catch (e) {
      _error = 'Could not load analytics: '
          '${e.toString().replaceFirst('ApiException: ', '')}';
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AdminColors.primary));

    final today = _data?['today'] ?? {};

    // Calculate stats from bookings
    final confirmedBookings = _bookings.where((b) => b['bookingStatus'] != 'cancelled').toList();
    final totalRevenue = confirmedBookings.fold<double>(0, (sum, b) => sum + asDouble(b['totalPriceEgp']));
    final totalCommission = confirmedBookings.fold<double>(0, (sum, b) => sum + asDouble(b['commissionAmount']));
    final totalPassengers = confirmedBookings.fold<int>(0, (sum, b) => sum + ((b['guestCount'] ?? 0) as int));
    final cancelledCount = _bookings.where((b) => b['bookingStatus'] == 'cancelled').length;
    final avgPerBooking = confirmedBookings.isNotEmpty ? totalRevenue / confirmedBookings.length : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AdminLanguageService.tr('analyticsTitle'), style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 4),
              Text('${AdminLanguageService.isArabic ? 'مؤشرات الأداء والإيرادات' : 'Performance metrics'} • ${DateFormat('MMMM yyyy', AdminLanguageService.currentLanguage).format(DateTime.now())}', style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
            ]),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: AdminColors.textMuted)),
          ]),
          const SizedBox(height: 28),

          // Revenue KPIs
          Row(children: [
            Expanded(child: _MetricCard(label: AdminLanguageService.tr('totalRevenue'), value: '${NumberFormat('#,###').format(totalRevenue)} EGP', sub: '≈ \$${NumberFormat('#,###').format(totalRevenue ~/ 49.5)} USD', icon: Icons.monetization_on, color: AdminColors.success)),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(label: AdminLanguageService.tr('platformCommission'), value: '${NumberFormat('#,###').format(totalCommission)} EGP', sub: '≈ \$${NumberFormat('#,###').format(totalCommission ~/ 49.5)} USD', icon: Icons.account_balance, color: AdminColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(label: AdminLanguageService.isArabic ? 'متوسط سعر الحجز' : 'Avg per Booking', value: '${NumberFormat('#,###').format(avgPerBooking)} EGP', sub: AdminLanguageService.isArabic ? 'لكل حجز مؤكد' : 'Per confirmed booking', icon: Icons.receipt_long, color: AdminColors.secondary)),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(label: AdminLanguageService.tr('totalPassengers'), value: NumberFormat('#,###').format(totalPassengers), sub: AdminLanguageService.isArabic ? 'إجمالي الركاب' : 'All-time passenger count', icon: Icons.people, color: AdminColors.accent)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MetricCard(label: AdminLanguageService.tr('totalBookings'), value: '${_bookings.length}', sub: '${confirmedBookings.length} ${AdminLanguageService.isArabic ? 'مؤكد' : 'confirmed'}', icon: Icons.book_online, color: AdminColors.info)),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(label: AdminLanguageService.isArabic ? 'الإلغاءات' : 'Cancellations', value: '$cancelledCount', sub: '${_bookings.isNotEmpty ? (cancelledCount * 100 ~/ _bookings.length) : 0}% ${AdminLanguageService.isArabic ? 'نسبة الإلغاء' : 'cancellation rate'}', icon: Icons.cancel_outlined, color: AdminColors.error)),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(label: AdminLanguageService.tr('todayFlights'), value: '${today['flightsCount'] ?? 0}', sub: '${today['passengersCount'] ?? 0} ${AdminLanguageService.tr('passengers')}', icon: Icons.flight_takeoff, color: AdminColors.warning)),
            const SizedBox(width: 16),
            Expanded(child: _MetricCard(label: AdminLanguageService.tr('todayRevenue'), value: '${NumberFormat('#,###').format(today['revenueEgp'] ?? 0)} EGP', sub: '${today['bookingsCount'] ?? 0} ${AdminLanguageService.tr('todayBookings')}', icon: Icons.today, color: AdminColors.success)),
          ]),
          const SizedBox(height: 28),

          // Revenue by operator (computed from bookings)
          Text(AdminLanguageService.isArabic ? 'إيرادات كل شركة مشغّلة' : 'Revenue by Operator', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
            padding: const EdgeInsets.all(20),
            child: _buildOperatorBreakdown(confirmedBookings),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorBreakdown(List<dynamic> bookings) {
    final Map<String, double> revenueByOp = {};
    final Map<String, int> countByOp = {};
    for (final b in bookings) {
      final opName = b['operator']?['nameEn'] ?? 'Unknown';
      revenueByOp[opName] = (revenueByOp[opName] ?? 0) + asDouble(b['totalPriceEgp']);
      countByOp[opName] = (countByOp[opName] ?? 0) + 1;
    }
    if (revenueByOp.isEmpty) return const Text('No data yet.', style: TextStyle(color: AdminColors.textMuted));

    final maxRevenue = revenueByOp.values.reduce((a, b) => a > b ? a : b);
    final colors = [AdminColors.primary, AdminColors.secondary, AdminColors.accent, AdminColors.info, AdminColors.success];

    return Column(
      children: revenueByOp.entries.toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final opName = entry.value.key;
        final revenue = entry.value.value;
        final count = countByOp[opName] ?? 0;
        final color = colors[idx % colors.length];
        final barWidth = maxRevenue > 0 ? revenue / maxRevenue : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(opName, style: const TextStyle(color: AdminColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${NumberFormat('#,###').format(revenue)} EGP ($count bookings)', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barWidth,
                  backgroundColor: AdminColors.surfaceDark,
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.sub, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AdminColors.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AdminColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(label, style: const TextStyle(color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        ]),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(color: AdminColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}
