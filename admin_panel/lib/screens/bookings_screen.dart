import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AdminApiService.getBookings();
      setState(() { _bookings = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Booking ${booking['bookingRef']}', style: const TextStyle(color: AdminColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Guest', booking['user']?['name'] ?? 'N/A'),
                _detailRow('Email', booking['user']?['email'] ?? 'N/A'),
                _detailRow('Phone', booking['user']?['phone'] ?? 'N/A'),
                const Divider(color: AdminColors.border),
                _detailRow('Flight', booking['flight']?['flightNumber'] ?? 'N/A'),
                _detailRow('Date', booking['flight']?['flightDate']?.toString().substring(0, 10) ?? 'N/A'),
                _detailRow('Package', booking['flight']?['package']?['nameEn'] ?? 'N/A'),
                const Divider(color: AdminColors.border),
                _detailRow('Guests', '${booking['guestCount']}'),
                _detailRow('Total', '${NumberFormat('#,###').format(booking['totalPriceEgp'] ?? 0)} EGP'),
                _detailRow('Commission', '${NumberFormat('#,###').format(booking['commissionAmount'] ?? 0)} EGP'),
                _detailRow('Discount', '${booking['discountAmount'] ?? 0} EGP'),
                const Divider(color: AdminColors.border),
                _detailRow('Pickup', booking['pickupHotelName'] ?? 'N/A'),
                _detailRow('Pickup Time', booking['pickupTime'] ?? 'N/A'),
                _detailRow('Driver', booking['driver']?['name'] ?? 'Not assigned'),
                _detailRow('Special Req.', booking['specialRequests'] ?? 'None'),
                const Divider(color: AdminColors.border),
                _detailRow('Payment', (booking['paymentStatus'] ?? 'pending').toString().toUpperCase()),
                _detailRow('Status', (booking['bookingStatus'] ?? 'pending').toString().toUpperCase()),
              ],
            ),
          ),
        ),
        actions: [
          if (booking['bookingStatus'] != 'cancelled' && booking['bookingStatus'] != 'checked_in')
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await AdminApiService.checkInBooking(booking['bookingRef']);
                  _loadBookings();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in!'), backgroundColor: AdminColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                }
              },
              child: const Text('✅ Check In', style: TextStyle(color: AdminColors.success)),
            ),
          if (booking['bookingStatus'] != 'cancelled')
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await AdminApiService.cancelBooking(booking['id'], reason: 'Cancelled by admin');
                  _loadBookings();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled'), backgroundColor: AdminColors.error));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                }
              },
              child: const Text('Cancel Booking', style: TextStyle(color: AdminColors.error)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AdminColors.primary))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AdminColors.textMuted, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
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
                  Text('Booking Management', style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 4),
                  Text('${_bookings.length} total bookings', style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13)),
                ],
              ),
              IconButton(onPressed: _loadBookings, icon: const Icon(Icons.refresh, color: AdminColors.textMuted), tooltip: 'Refresh'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AdminColors.border, height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Error: $_error', style: const TextStyle(color: AdminColors.error, fontSize: 12)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadBookings, child: const Text('Retry')),
                    ]))
                  : _bookings.isEmpty
                      ? const Center(child: Text('No bookings yet.', style: TextStyle(color: AdminColors.textMuted)))
                      : SingleChildScrollView(
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
                                DataColumn(label: Text('REF')),
                                DataColumn(label: Text('GUEST')),
                                DataColumn(label: Text('FLIGHT')),
                                DataColumn(label: Text('HOTEL')),
                                DataColumn(label: Text('GUESTS')),
                                DataColumn(label: Text('TOTAL')),
                                DataColumn(label: Text('PAYMENT')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: _bookings.map<DataRow>((b) {
                                final status = (b['bookingStatus'] ?? 'pending').toString();
                                final payStatus = (b['paymentStatus'] ?? 'pending').toString();
                                final statusColor = status == 'confirmed' ? AdminColors.success
                                    : status == 'checked_in' ? AdminColors.info
                                    : status == 'cancelled' ? AdminColors.error
                                    : status == 'completed' ? AdminColors.success
                                    : AdminColors.warning;
                                final payColor = payStatus == 'paid' ? AdminColors.success
                                    : payStatus == 'refunded' ? AdminColors.info
                                    : AdminColors.warning;
                                return DataRow(cells: [
                                  DataCell(InkWell(
                                    onTap: () => _showBookingDetails(b),
                                    child: Text(b['bookingRef']?.toString() ?? '-', style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.w600, fontSize: 12, decoration: TextDecoration.underline)),
                                  )),
                                  DataCell(Text(b['user']?['name'] ?? 'Guest', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(b['flight']?['flightNumber']?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(b['pickupHotelName'] ?? '-', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('${b['guestCount'] ?? 0}')),
                                  DataCell(Text('${NumberFormat('#,###').format(b['totalPriceEgp'] ?? 0)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: payColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(payStatus.toUpperCase(), style: TextStyle(color: payColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.info_outline, color: AdminColors.secondary, size: 18), tooltip: 'Details', onPressed: () => _showBookingDetails(b)),
                                      if (status == 'confirmed')
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: AdminColors.success, size: 18),
                                          tooltip: 'Check In',
                                          onPressed: () async {
                                            try {
                                              await AdminApiService.checkInBooking(b['bookingRef']);
                                              _loadBookings();
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in!'), backgroundColor: AdminColors.success));
                                            } catch (e) {
                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.error));
                                            }
                                          },
                                        ),
                                    ],
                                  )),
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
