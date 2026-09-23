import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../models/booking.dart';
import '../models/flight.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/date_helper.dart';
import '../widgets/hot_air_balloon_logo.dart';
import '../widgets/nile_map.dart';
import 'active_flight_screen.dart';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;
  final FlightModel flight;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
    required this.flight,
  });

  @override
  Widget build(BuildContext context) {
    final formattedFlightDate = DateHelper.formatFlightDate(
      context,
      booking.flightDate,
    );

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Success Icon & Confirmed text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 54),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('bookingConfirmed'),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('confirmedSubtitle'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Digital Boarding Pass Ticket with QR Code
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top header: Airline/Operator + Flight Number
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const HotAirBalloonLogo(size: 22),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'NileSky Official Fleet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              booking.bookingRef,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // QR Code in Center
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: QrImageView(
                              data: booking.qrCodeData ?? booking.bookingRef,
                              version: QrVersions.auto,
                              size: 150.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('showQrAtBoarding'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Flight Info Details Grid
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          const Divider(color: AppColors.border, height: 20),
                          _buildTicketRow(context.tr('packageSelected'), flight.packageName),
                          _buildTicketRow(context.tr('flightDate'), formattedFlightDate),
                          _buildTicketRow(context.tr('flightTime'), '${flight.departureTime} AM (${context.tr('sunrise')})'),
                          _buildTicketRow(context.tr('pickupTime'), '${booking.pickupTime} AM (${context.tr('pickup')})'),
                          _buildTicketRow(context.tr('pickupPoint'), booking.pickupHotelName ?? 'Hotel Lobby'),
                          _buildTicketRow(context.tr('guestsCount'), '${booking.guestCount} ${context.tr('persons')}'),
                          _buildTicketRow(
                            context.tr('totalPaid'),
                            ApiService.formatPrice(booking.totalPriceEgp),
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Where the balloon lifts off from
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('meetingPoint'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              NileMap(
                height: 190,
                initialZoom: flight.hasLaunchPoint ? 14 : 12,
                pins: [
                  MapPin(
                    point: flight.hasLaunchPoint
                        ? MapPoint(flight.launchLat!, flight.launchLng!)
                        : kLuxorLaunchArea,
                    label: flight.launchSite ?? context.tr('launchAreaGeneric'),
                    icon: Icons.flight_takeoff,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action: Track Driver Pickup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ActiveFlightScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.directions_car, color: Colors.black),
                  label: Text(context.tr('trackDriverBtn')),
                ),
              ),
              const SizedBox(height: 12),

              // Return Home Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(context.tr('backToHome'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
