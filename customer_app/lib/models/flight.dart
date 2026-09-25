import '../services/api_service.dart';

String _firstNonEmpty(List<String> candidates) =>
    candidates.firstWhere((c) => c.trim().isNotEmpty, orElse: () => '');

String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value;

class FlightModel {
  final String id;
  final String flightNumber;
  final String operatorId;
  final String operatorName;
  final String operatorLogo;
  final double operatorRating;
  final int totalReviews;
  final String packageId;
  final String packageName;
  final String packageType; // standard | premium | private
  final int durationMinutes;
  final bool hasPickup;
  final bool hasBreakfast;
  final bool isPrivate;
  final String flightDate;
  final String departureTime;
  final int capacity;
  final int bookedCount;
  final int remainingSeats;
  final double priceEgp;
  final double? priceUsd;
  final double? priceEur;
  final double? priceGbp;
  final String status;
  final String weatherStatus;
  final String? badge; // 'Best Value' | 'Best for Couples' | 'Highest Rated'
  final String coverPhotoUrl;
  final List<String> photos;
  final String? videoUrl;
  final String? pilotName;
  final String? balloonName;

  // Where the flight starts and ends. Set by the operator in the admin panel;
  // null until they fill it in, in which case the map falls back to the
  // general Luxor west-bank launch area.
  /// The operator's own copy for this package, shown instead of fixed text.
  final String? descriptionEn;
  final String? descriptionAr;
  final int? maxAltitudeM;

  final String? launchSite;
  final double? launchLat;
  final double? launchLng;
  final String? landingSite;
  final double? landingLat;
  final double? landingLng;

  FlightModel({
    required this.id,
    required this.flightNumber,
    required this.operatorId,
    required this.operatorName,
    required this.operatorLogo,
    required this.operatorRating,
    required this.totalReviews,
    required this.packageId,
    required this.packageName,
    required this.packageType,
    required this.durationMinutes,
    required this.hasPickup,
    required this.hasBreakfast,
    required this.isPrivate,
    required this.flightDate,
    required this.departureTime,
    required this.capacity,
    required this.bookedCount,
    required this.remainingSeats,
    required this.priceEgp,
    this.priceUsd,
    this.priceEur,
    this.priceGbp,
    required this.status,
    required this.weatherStatus,
    this.badge,
    required this.coverPhotoUrl,
    required this.photos,
    this.videoUrl,
    this.pilotName,
    this.balloonName,
    this.descriptionEn,
    this.descriptionAr,
    this.maxAltitudeM,
    this.launchSite,
    this.launchLat,
    this.launchLng,
    this.landingSite,
    this.landingLat,
    this.landingLng,
  });

  bool get hasLaunchPoint => launchLat != null && launchLng != null;
  bool get hasLandingPoint => landingLat != null && landingLng != null;

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    final operator = json['operator'] ?? {};
    final pkg = json['package'] ?? {};
    final balloon = json['balloon'] ?? {};
    final pilot = json['pilot'] ?? {};

    // The upload endpoint stores a path relative to the API ("/upload/<id>").
    // Every media field is made absolute here, once, so no screen can forget.
    final photosRaw = json['photos'] ?? pkg['photos'] ?? [];
    final List<String> photosList = (photosRaw is List)
        ? photosRaw
            .map((e) => ApiService.mediaUrl(e?.toString()))
            .where((u) => u.isNotEmpty)
            .toList()
        : [];

    return FlightModel(
      id: json['id'] ?? '',
      flightNumber: json['flightNumber'] ?? '',
      operatorId: json['operatorId'] ?? operator['id'] ?? '',
      operatorName: operator['nameEn'] ?? 'Luxor Operator',
      operatorLogo: ApiService.mediaUrl(operator['logoUrl']?.toString()),
      operatorRating: double.tryParse(operator['rating']?.toString() ?? '4.9') ?? 4.9,
      totalReviews: int.tryParse(operator['totalReviews']?.toString() ?? '0') ?? 0,
      packageId: json['packageId'] ?? pkg['id'] ?? '',
      packageName: pkg['nameEn'] ?? 'Sunrise Flight',
      packageType: pkg['type'] ?? 'standard',
      durationMinutes: pkg['durationMinutes'] ?? 45,
      hasPickup: pkg['hasPickup'] ?? true,
      hasBreakfast: pkg['hasBreakfast'] ?? false,
      isPrivate: pkg['isPrivate'] ?? false,
      flightDate: json['flightDate']?.toString().split('T')[0] ?? '',
      departureTime: json['departureTime']?.toString().substring(0, 5) ?? '06:15',
      capacity: json['capacity'] ?? 16,
      bookedCount: json['bookedCount'] ?? 0,
      remainingSeats: json['remainingSeats'] ?? (json['capacity'] ?? 16) - (json['bookedCount'] ?? 0),
      priceEgp: double.tryParse(json['priceEgp']?.toString() ?? '1500') ?? 1500,
      priceUsd: double.tryParse(pkg['priceUsd']?.toString() ?? '30'),
      priceEur: double.tryParse(pkg['priceEur']?.toString() ?? '28'),
      priceGbp: double.tryParse(pkg['priceGbp']?.toString() ?? '24'),
      status: json['status'] ?? 'scheduled',
      weatherStatus: json['weatherStatus'] ?? 'favorable',
      badge: json['badge'],
      coverPhotoUrl: _firstNonEmpty([
        ApiService.mediaUrl(pkg['coverPhotoUrl']?.toString()),
        photosList.isNotEmpty ? photosList.first : '',
        'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
      ]),
      photos: photosList.isNotEmpty ? photosList : [
        'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
      ],
      // The flight's own video wins over the package's generic one.
      videoUrl: _nullIfEmpty(ApiService.mediaUrl(
        (json['videoUrl'] ?? pkg['videoUrl'])?.toString(),
      )),
      pilotName: pilot['nameEn'],
      balloonName: balloon['name'],
      descriptionEn: pkg['descriptionEn'],
      descriptionAr: pkg['descriptionAr'],
      maxAltitudeM: int.tryParse(json['maxAltitudeM']?.toString() ?? ''),
      launchSite: json['launchSite'],
      // Postgres hands numerics back as strings, so parse rather than cast.
      launchLat: double.tryParse(json['launchLat']?.toString() ?? ''),
      launchLng: double.tryParse(json['launchLng']?.toString() ?? ''),
      landingSite: json['landingSite'],
      landingLat: double.tryParse(json['landingLat']?.toString() ?? ''),
      landingLng: double.tryParse(json['landingLng']?.toString() ?? ''),
    );
  }
}
