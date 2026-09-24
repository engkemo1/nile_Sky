import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../services/localization_service.dart';
import 'review_screen.dart';
import '../widgets/flight_animation_bg.dart';
import '../widgets/hot_air_balloon_logo.dart';
import '../models/booking.dart';

class ActiveFlightScreen extends StatelessWidget {
  /// The booking this screen is about. It used to be absent entirely, so every
  /// passenger saw the same invented driver, van and plate — which is how
  /// somebody ends up climbing into the wrong vehicle at four in the morning.
  final BookingModel? booking;

  const ActiveFlightScreen({super.key, this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('todayFlightExp'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
      ),
      body: FlightAnimationBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Hero Card with Sunrise Warm Luxury Glow
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFFBEB),
                        Color(0xFFE0F2FE),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 18,
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
                          Expanded(
                            child: Row(
                              children: [
                                const HotAirBalloonLogo(size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.tr('sunriseFlightToday'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                '🟢 ${context.tr('confirmedToFly')}',
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('takeoff'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'NileSky Classic Sunrise Ride • Luxor West Bank',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Digital QR Boarding Pass Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              context.tr('digitalBoardingPass'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldenGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NLK-2026-09-0142',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: booking?.qrCodeData ??
                              booking?.bookingRef ??
                              'NO-BOOKING',
                          version: QrVersions.auto,
                          size: 140.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('showQrAtBoarding'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Driver & Vehicle Card
                _driverCard(context),
                const SizedBox(height: 20),

                // Morning Experience Timeline
                Text(
                  context.tr('flightTimeline'),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildTimelineItem('1', context.tr('timelineStep1'), context.tr('timelineStep1Sub'), true),
                _buildTimelineItem('2', context.tr('timelineStep2'), context.tr('timelineStep2Sub'), false),
                _buildTimelineItem('3', context.tr('timelineStep3'), context.tr('timelineStep3Sub'), false),
                _buildTimelineItem('4', context.tr('timelineStep4'), context.tr('timelineStep4Sub'), false, isLast: true),
                const SizedBox(height: 20),

                // Weather Advisory Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.air, color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('weatherAdvisoryTitle'),
                              style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('weatherAdvisoryBody'),
                              style: const TextStyle(color: Color(0xFF047857), fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Rate Experience Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            bookingId: booking?.id,
                            operatorName: booking?.operatorName ?? 'NileSky',
                            flightName:
                                booking?.packageName ?? 'NileSky Sunrise Ride',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryDark),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.star_outline, color: AppColors.primaryDark),
                    label: Text(
                      '⭐ ${context.tr('rateExperience')}',
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The driver the operator actually assigned — or an honest "not yet".
  Widget _driverCard(BuildContext context) {
    final b = booking;
    final assigned = b != null && b.hasDriver;

    Widget shell(Widget child) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        );

    if (!assigned) {
      return shell(
        Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('driverNotAssigned'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.tr('driverNotAssignedSub'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final name = b.driverName!.trim();
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final phone = (b.driverPhone ?? '').trim();

    return shell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  gradient: AppColors.goldenGradient,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFFBEB),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('driverAssigned'),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.airport_shuttle,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (b.driverCarModel ?? '').trim().isEmpty
                            ? '—'
                            : b.driverCarModel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if ((b.driverCarPlate ?? '').trim().isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    b.driverCarPlate!,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copy(context, phone,
                        context.tr('driverNumberCopied')),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.phone,
                        size: 16, color: AppColors.textPrimary),
                    label: Text(
                      phone,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// No url_launcher in this app, so the number is copied to the clipboard
  /// rather than promising a dialler that will not open.
  void _copy(BuildContext context, String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildTimelineItem(String step, String title, String subtitle, bool isActive, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.goldenGradient : null,
                  color: isActive ? null : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: isActive ? Colors.black : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isActive ? AppColors.primaryDark : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
