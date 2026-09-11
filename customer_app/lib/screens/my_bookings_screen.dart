import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../models/booking.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/date_helper.dart';
import 'active_flight_screen.dart';
import 'review_screen.dart';
import 'auth_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getMyBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Flight Booking?', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to cancel booking ${booking.bookingRef}?\n\nPer NileSky weather guarantee, full refunds are processed immediately.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.cancelBooking(booking.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Booking cancelled successfully.' : 'Cancellation recorded.'),
            backgroundColor: success ? AppColors.success : AppColors.secondary,
          ),
        );
        _fetchBookings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcomingBookings = _bookings.where((b) => b.bookingStatus != 'completed' && b.bookingStatus != 'cancelled').toList();
    final pastBookings = _bookings.where((b) => b.bookingStatus == 'completed' || b.bookingStatus == 'cancelled').toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('myTrips'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _fetchBookings,
          ),
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: [
            Tab(text: context.tr('upcomingTrips')),
            Tab(text: context.tr('pastTrips')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(upcomingBookings),
                _buildPastTab(pastBookings),
              ],
            ),
    );
  }

  Widget _buildUpcomingTab(List<BookingModel> upcomingBookings) {
    if (upcomingBookings.isEmpty) {
      // If no live bookings, show the sample boarding pass so customer can still test day-of flow
      return RefreshIndicator(
        onRefresh: _fetchBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (!ApiService.isLoggedIn)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primaryDark),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Log in with your NileSky account to see all synced bookings across devices.',
                          style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        },
                        child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      ),
                    ],
                  ),
                ),
              // Empty state
              const SizedBox(height: 32),
              const Icon(Icons.flight_takeoff, size: 64, color: AppColors.border),
              const SizedBox(height: 16),
              const Text(
                'No upcoming flights found.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book a flight to see it here!',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookings,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: upcomingBookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          return _buildBookingCard(upcomingBookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {bool isSample = false}) {
    final formattedFlightDate = DateHelper.formatFlightDate(context, booking.flightDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '🟢 ${booking.bookingStatus.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                child: Text(
                  booking.bookingRef,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            booking.packageName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${booking.operatorName} • ${booking.guestCount} Guests • ${ApiService.formatPrice(booking.totalPriceEgp)}',
            style: const TextStyle(color: AppColors.secondary, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const Divider(color: AppColors.border, height: 24),

          _buildTicketDetailRow(context.tr('flightDate'), formattedFlightDate),
          _buildTicketDetailRow(context.tr('flightTime'), '${booking.departureTime} (${context.tr('sunrise')})'),
          _buildTicketDetailRow(context.tr('pickupTime'), '${booking.pickupTime ?? "03:45 AM"} (${context.tr('pickup')})'),
          _buildTicketDetailRow(context.tr('pickupPoint'), booking.pickupHotelName ?? 'Hotel Reception'),
          const Divider(color: AppColors.border, height: 24),

          // Action Buttons: View QR Ticket & Day-of Hub
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQrModal(context, booking.qrCodeData ?? booking.bookingRef),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.qr_code, size: 18, color: AppColors.textPrimary),
                  label: Text(context.tr('viewQrTicket'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ActiveFlightScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.directions_car, size: 18, color: Colors.black),
                    label: Text(context.tr('dayOfHubBtn'), style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),

          // Cancel Option
          if (!isSample) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancelBooking(booking),
                child: const Text('Cancel Booking', style: TextStyle(color: AppColors.error, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPastTab(List<BookingModel> pastBookings) {
    if (pastBookings.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      context.tr('completedTrip'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Text('NLK-2026-02-0089', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'NileSky Premium Sunrise + Breakfast',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const Text('NileSky Fleet • 2 Guests • 20 Feb 2026', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Divider(color: AppColors.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('flightCertificate'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading Official Luxor Flight Certificate (PDF)...')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16, color: AppColors.primaryDark),
                    label: Text(context.tr('download'), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReviewScreen(
                          operatorName: 'NileSky Fleet',
                          flightName: 'NileSky Premium Sunrise + Breakfast',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline, color: AppColors.primaryDark, size: 18),
                  label: const Text('Write Flight Review', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: pastBookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final b = pastBookings[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: b.bookingStatus == 'cancelled'
                          ? AppColors.error.withValues(alpha: 0.1)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      b.bookingStatus == 'cancelled' ? 'CANCELLED' : context.tr('completedTrip'),
                      style: TextStyle(
                        color: b.bookingStatus == 'cancelled' ? AppColors.error : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(b.bookingRef, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                b.packageName,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text('${b.operatorName} • ${b.guestCount} Guests • ${b.flightDate}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Divider(color: AppColors.border, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.tr('flightCertificate'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading Official Luxor Flight Certificate (PDF)...')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16, color: AppColors.primaryDark),
                    label: Text(context.tr('download'), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (b.bookingStatus != 'cancelled') ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            bookingId: b.id,
                            operatorName: b.operatorName,
                            flightName: b.packageName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_outline, color: AppColors.primaryDark, size: 18),
                    label: const Text('Write Flight Review', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('digitalBoardingPass'),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                code,
                style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 180.0,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('showQrAtBoarding'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
