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
      flightNumber: flight['flightNumber'] ?? 'FL-101',
      flightDate: (json['flightDate'] ?? flight['flightDate'] ?? '').toString().split('T')[0],
      departureTime: (flight['departureTime'] ?? '06:15').toString().substring(0, 5),
      operatorName: operator['nameEn'] ?? 'Luxor Operator',
      packageName: pkg['nameEn'] ?? 'Sunrise Flight',
      guestCount: json['guestCount'] ?? 2,
      totalPriceEgp: double.tryParse(json['totalPriceEgp']?.toString() ?? '3000') ?? 3000,
      paymentStatus: json['paymentStatus'] ?? 'paid',
      bookingStatus: json['bookingStatus'] ?? 'confirmed',
      pickupLocation: json['pickupLocation'],
      pickupHotelName: json['pickupHotelName'] ?? 'Hilton Luxor Resort',
      pickupTime: (json['pickupTime'] ?? '03:45').toString().substring(0, 5),
      driverName: driver['name'] ?? 'Ahmed Mahmoud',
      driverPhone: driver['phone'] ?? '01012345678',
      driverCarModel: driver['carModel'] ?? 'Toyota HiAce (White Van)',
      driverCarPlate: driver['carPlate'] ?? 'ل م ط ١٢٣٤',
      qrCodeData: json['qrCodeData'] ?? json['bookingRef'] ?? 'NLK-2026-09-0142',
      specialRequests: json['specialRequests'],
    );
  }
}
