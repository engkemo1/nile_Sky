import '../services/api_service.dart';

class OperatorModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String logoUrl;
  final String coverPhotoUrl;
  final List<String> photos;
  final String? videoUrl;
  final String phone;
  final String whatsapp;
  final String website;
  final double rating;
  final int totalReviews;
  final int totalFlights;
  final String status;
  final String address;

  OperatorModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.logoUrl,
    required this.coverPhotoUrl,
    required this.photos,
    this.videoUrl,
    required this.phone,
    required this.whatsapp,
    required this.website,
    required this.rating,
    required this.totalReviews,
    required this.totalFlights,
    required this.status,
    required this.address,
  });

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    final photosRaw = json['photos'] ?? [];
    final List<String> photosList = (photosRaw is List)
        ? photosRaw
            .map((e) => ApiService.mediaUrl(e?.toString()))
            .where((u) => u.isNotEmpty)
            .toList()
        : [];

    return OperatorModel(
      id: json['id'] ?? '',
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      descriptionEn: json['descriptionEn'] ?? '',
      descriptionAr: json['descriptionAr'] ?? '',
      logoUrl: ApiService.mediaUrl(json['logoUrl']?.toString()),
      coverPhotoUrl: [
        ApiService.mediaUrl(json['coverPhotoUrl']?.toString()),
        photosList.isNotEmpty ? photosList.first : '',
        'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
      ].firstWhere((c) => c.trim().isNotEmpty),
      photos: photosList.isNotEmpty ? photosList : [
        'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=800',
        'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
      ],
      videoUrl: (json['videoUrl'] == null || json['videoUrl'].toString().isEmpty)
          ? null
          : ApiService.mediaUrl(json['videoUrl'].toString()),
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      website: json['website'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
      totalReviews: int.tryParse(json['totalReviews']?.toString() ?? '0') ?? 0,
      totalFlights: int.tryParse(json['totalFlights']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'verified',
      address: json['address'] ?? 'Luxor West Bank, Egypt',
    );
  }
}
