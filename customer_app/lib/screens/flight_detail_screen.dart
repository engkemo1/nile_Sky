import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/flight.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/media_album_viewer.dart';
import '../widgets/nile_map.dart';
import 'booking_flow_screen.dart';

class FlightDetailScreen extends StatelessWidget {
  final FlightModel flight;

  const FlightDetailScreen({super.key, required this.flight});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          flight.packageName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('linkCopied'))),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Photos Album Gallery & Video Player Overlay
                MediaAlbumViewer(
                  photos: flight.photos,
                  videoUrl: flight.videoUrl,
                  title: flight.packageName,
                ),
                const SizedBox(height: 18),

                // 2. Flight Header & Direct NileSky Operation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (flight.badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.sunriseGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                flight.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            flight.packageName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // The operator's own name is deliberately not shown:
                          // passengers book NileSky, not a company behind it.
                          Row(
                            children: [
                              const Icon(Icons.wb_twilight,
                                  color: AppColors.secondary, size: 16),
                              const SizedBox(width: 5),
                              Text(
                                context.tr('sunriseFlightLabel'),
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Quick Spec Bar (Duration, Max Altitude, Pickup, Breakfast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHighlightItem(Icons.timer_outlined, '${flight.durationMinutes}m', context.tr('duration')),
                      _buildDivider(),
                      if (flight.maxAltitudeM != null) ...[
                        _buildHighlightItem(Icons.terrain_outlined,
                            '${flight.maxAltitudeM}m', context.tr('maxAltitude')),
                        _buildDivider(),
                      ],
                      _buildHighlightItem(Icons.wb_sunny_outlined, '${flight.departureTime} AM', context.tr('takeoff')),
                      _buildDivider(),
                      _buildHighlightItem(Icons.people_outline, '${flight.capacity} max', context.tr('basketSize')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. NileSky Official Fleet & Aviation Authority Guarantee Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldenGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.flight_takeoff, color: Colors.black, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NileSky Official Fleet Operations',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.tr('safetyBriefingNote'),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 20),
                      Row(
                        children: [
                          _buildSafetyPill('🛡️ 100% Safety Record'),
                          const SizedBox(width: 8),
                          _buildSafetyPill('👨‍✈️ Master Pilots'),
                          const SizedBox(width: 8),
                          _buildSafetyPill('⛵ Nile Boat Transfer'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Flight Overview Description
                Text(
                  context.tr('overview'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  // Written by whoever runs the flight, in the admin panel.
                  // It used to be a fixed paragraph, so editing the package
                  // description changed nothing a passenger could see.
                  child: Text(
                    _overviewText(context),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Included Amenities List
                Text(
                  context.tr('whatsIncluded'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // These follow the package the operator configured; the
                      // list used to claim hotel pickup whether or not the
                      // package included it.
                      if (flight.hasPickup)
                        _buildInclusionRow(Icons.check_circle, AppColors.success,
                            context.tr('hotelPickupIncluded'))
                      else
                        _buildInclusionRow(Icons.cancel, AppColors.textMuted,
                            context.tr('pickupNotIncluded')),
                      const SizedBox(height: 10),
                      if (flight.isPrivate) ...[
                        _buildInclusionRow(Icons.check_circle, AppColors.success,
                            context.tr('privateBasket')),
                        const SizedBox(height: 10),
                      ],
                      _buildInclusionRow(Icons.check_circle, AppColors.success, context.tr('nileMotorboatCrossing')),
                      const SizedBox(height: 10),
                      _buildInclusionRow(Icons.check_circle, AppColors.success, '${flight.durationMinutes} ${context.tr('sunriseFlightAirtime')}'),
                      const SizedBox(height: 10),
                      _buildInclusionRow(Icons.check_circle, AppColors.success, context.tr('flightCertificate')),
                      const SizedBox(height: 10),
                      if (flight.hasBreakfast)
                        _buildInclusionRow(Icons.check_circle, AppColors.success, context.tr('egyptianBreakfastIncluded'))
                      else
                        _buildInclusionRow(Icons.cancel, AppColors.textMuted, context.tr('breakfastNotIncluded')),
                      const SizedBox(height: 10),
                      _buildInclusionRow(Icons.check_circle, AppColors.success, context.tr('passengerInsuranceIncluded')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 7. Sights / Landmarks Visited
                Text(
                  context.tr('landmarksVisible'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildLandmarkChip('👑 ${context.tr('valleyOfTheKings')}'),
                    _buildLandmarkChip('🏛️ ${context.tr('hatshepsutTemple')}'),
                    _buildLandmarkChip('🗿 ${context.tr('colossiOfMemnon')}'),
                    _buildLandmarkChip('🌊 ${context.tr('nileRiverDawn')}'),
                    _buildLandmarkChip('🌾 ${context.tr('luxorFarms')}'),
                  ],
                ),
                const SizedBox(height: 20),

                // 7a. The operator's weather call, which the app used to parse
                // and then never show. An uncertain morning is exactly what a
                // passenger needs to know before they book.
                if (flight.weatherStatus == 'uncertain' ||
                    flight.weatherStatus == 'unfavorable') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: flight.weatherStatus == 'unfavorable'
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: flight.weatherStatus == 'unfavorable'
                            ? AppColors.error.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          flight.weatherStatus == 'unfavorable'
                              ? Icons.cloud_off
                              : Icons.air,
                          size: 20,
                          color: flight.weatherStatus == 'unfavorable'
                              ? AppColors.error
                              : AppColors.primaryDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            flight.weatherStatus == 'unfavorable'
                                ? context.tr('weatherUnfavorable')
                                : context.tr('weatherUncertain'),
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: flight.weatherStatus == 'unfavorable'
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 7b. Where the flight starts and ends
                Text(
                  context.tr('whereYouFly'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                NileMap(
                  height: 230,
                  initialZoom: flight.hasLaunchPoint ? 13 : 12,
                  connectPins: flight.hasLandingPoint,
                  pins: [
                    MapPin(
                      point: flight.hasLaunchPoint
                          ? MapPoint(flight.launchLat!, flight.launchLng!)
                          : kLuxorLaunchArea,
                      label: flight.launchSite ?? context.tr('launchAreaGeneric'),
                      icon: Icons.flight_takeoff,
                    ),
                    if (flight.hasLandingPoint)
                      MapPin(
                        point: MapPoint(flight.landingLat!, flight.landingLng!),
                        label: flight.landingSite ?? context.tr('landingSite'),
                        icon: Icons.flight_land,
                        color: const Color(0xFF3A8C96),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        flight.hasLandingPoint
                            ? context.tr('landingVaries')
                            : context.tr('mapHint'),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 7c. What passengers who actually flew this package said.
                // The app used to show two invented reviews on a screen
                // nothing linked to, and never fetched the real ones.
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: ApiService.getReviews(packageId: flight.packageId),
                  builder: (context, snap) {
                    final reviews = snap.data ?? const [];
                    if (snap.connectionState != ConnectionState.done ||
                        reviews.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('passengerReviews'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontSize: 17, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        ...reviews.take(5).map(_reviewCard),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // 8. Cancellation Policy Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.success, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('freeCancellationPolicy'),
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('freeCancellationSub'),
                              style: const TextStyle(
                                color: Color(0xFF047857),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 9. Sticky Bottom Booking Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ApiService.formatPrice(flight.priceEgp),
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.tr('perPerson'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingFlowScreen(flight: flight),
                              ),
                            );
                          },
                          child: Text(context.tr('bookNow')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The operator's description in the reader's language, falling back to the
  /// other language and then to a plain sentence when they have written none.
  String _overviewText(BuildContext context) {
    final ar = (flight.descriptionAr ?? '').trim();
    final en = (flight.descriptionEn ?? '').trim();
    if (LanguageService.isArabic && ar.isNotEmpty) return ar;
    if (!LanguageService.isArabic && en.isNotEmpty) return en;
    if (en.isNotEmpty) return en;
    if (ar.isNotEmpty) return ar;
    return context.tr('overviewFallback');
  }

  /// One real review. The reviewer's first name only — the API returns the
  /// whole user record and a full name on a public screen is more than a
  /// passenger agreed to.
  Widget _reviewCard(Map<String, dynamic> r) {
    final rating = int.tryParse(r['rating']?.toString() ?? '') ?? 5;
    final comment = (r['comment'] ?? '').toString().trim();
    final fullName = (r['user']?['name'] ?? '').toString().trim();
    final name = fullName.isEmpty ? 'Passenger' : fullName.split(' ').first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 28,
      width: 1,
      color: AppColors.border,
    );
  }

  Widget _buildSafetyPill(String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInclusionRow(IconData icon, Color iconColor, String text) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
