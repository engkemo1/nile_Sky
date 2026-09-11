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
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    final operator = json['operator'] ?? {};
    final pkg = json['package'] ?? {};
    final balloon = json['balloon'] ?? {};
    final pilot = json['pilot'] ?? {};

    final photosRaw = json['photos'] ?? pkg['photos'] ?? [];
    final List<String> photosList = (photosRaw is List)
        ? photosRaw.map((e) => e.toString()).toList()
        : [];

    return FlightModel(
      id: json['id'] ?? '',
      flightNumber: json['flightNumber'] ?? '',
      operatorId: json['operatorId'] ?? operator['id'] ?? '',
      operatorName: operator['nameEn'] ?? 'Luxor Operator',
      operatorLogo: operator['logoUrl'] ?? '',
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
      coverPhotoUrl: pkg['coverPhotoUrl'] ?? json['photoUrl'] ?? 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
      photos: photosList.isNotEmpty ? photosList : [
        'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
      ],
      videoUrl: pkg['videoUrl'] ?? json['videoUrl'],
      pilotName: pilot['nameEn'],
      balloonName: balloon['name'],
    );
  }
}
