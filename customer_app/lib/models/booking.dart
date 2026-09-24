class BookingModel {
  final String id;
  final String bookingRef;
  final String flightId;
  final String flightNumber;
  final String flightDate;
  final String departureTime;
  final String operatorName;
  final String packageName;
  final int guestCount;
  final double totalPriceEgp;
  final String paymentStatus;
  final String bookingStatus;
  final String? pickupLocation;
  final String? pickupHotelName;
  final String? pickupTime;
  final String? driverName;
  final String? driverPhone;
  final String? driverCarModel;
  final String? driverCarPlate;
  final String? qrCodeData;
  final String? specialRequests;

  /// Why the flight or the booking was called off, as the operator typed it.
  final String? cancellationReason;

  /// The flight's own launch point, so the day-of screen can map the real one.
  final String? launchSite;
  final double? launchLat;
  final double? launchLng;

  /// A driver is only shown once the operator has actually assigned one.
  bool get hasDriver => (driverName ?? '').trim().isNotEmpty;
  bool get isCancelled => bookingStatus.toLowerCase() == 'cancelled';

  BookingModel({
    required this.id,
    required this.bookingRef,
    required this.flightId,
    required this.flightNumber,
    required this.flightDate,
    required this.departureTime,
    required this.operatorName,
    required this.packageName,
    required this.guestCount,
    required this.totalPriceEgp,
    required this.paymentStatus,
    required this.bookingStatus,
    this.pickupLocation,
    this.pickupHotelName,
    this.pickupTime,
    this.driverName,
    this.driverPhone,
    this.driverCarModel,
    this.driverCarPlate,
    this.qrCodeData,
    this.specialRequests,
    this.cancellationReason,
    this.launchSite,
    this.launchLat,
    this.launchLng,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final flight = json['flight'] ?? {};
    final pkg = flight['package'] ?? {};
    final operator = json['operator'] ?? {};
    final driver = json['driver'] ?? {};

    return BookingModel(
      id: json['id'] ?? '',
      bookingRef: json['bookingRef'] ?? '',
      flightId: json['flightId'] ?? flight['id'] ?? '',
      flightNumber: flight['flightNumber'] ?? '-',
      flightDate: (json['flightDate'] ?? flight['flightDate'] ?? '').toString().split('T')[0],
      departureTime: (flight['departureTime'] ?? '06:15').toString().substring(0, 5),
      operatorName: operator['nameEn'] ?? '-',
      packageName: pkg['nameEn'] ?? 'Sunrise Flight',
      guestCount: json['guestCount'] ?? 0,
      totalPriceEgp: double.tryParse(json['totalPriceEgp']?.toString() ?? '') ?? 0,
      paymentStatus: json['paymentStatus'] ?? 'pending',
      bookingStatus: json['bookingStatus'] ?? 'pending',
      pickupLocation: json['pickupLocation'],
      pickupHotelName: json['pickupHotelName'],
      pickupTime: json['pickupTime']?.toString().padRight(5).substring(0, 5).trim(),
      // No invented driver. These stay null until an operator assigns someone,
      // so the app can say "not assigned yet" instead of naming a driver who
      // is not coming and a van the passenger should not get into.
      driverName: driver['name'],
      driverPhone: driver['phone'],
      driverCarModel: driver['carModel'],
      driverCarPlate: driver['carPlate'],
      qrCodeData: json['qrCodeData'] ?? json['bookingRef'],
      specialRequests: json['specialRequests'],
      cancellationReason: json['cancellationReason'] ?? flight['cancellationReason'],
      launchSite: flight['launchSite'],
      launchLat: double.tryParse(flight['launchLat']?.toString() ?? ''),
      launchLng: double.tryParse(flight['launchLng']?.toString() ?? ''),
    );
  }
}
