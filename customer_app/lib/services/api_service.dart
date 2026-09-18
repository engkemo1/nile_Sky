import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/flight.dart';
import '../models/operator.dart';
import '../models/booking.dart';
import '../models/weather.dart';

class ApiService {
  // ──── CHANGE THIS to your deployed backend URL (e.g. Render) ────
  // For local dev: 'http://localhost:3000'
  static String _baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://nile-sky.vercel.app',
  );
  static String get baseUrl => _baseUrl;
  static void setBaseUrl(String url) => _baseUrl = url;

  // ──── Auth State ────
  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? currentUser;
  static bool get isLoggedIn => _accessToken != null;

  // Selected Currency helper
  static String selectedCurrency = 'EGP';
  static double usdRate = 49.5;
  static double eurRate = 53.2;
  static double gbpRate = 62.1;

  static String formatPrice(double priceEgp) {
    if (selectedCurrency == 'USD') {
      final usd = (priceEgp / usdRate).round();
      return '\$$usd USD (${priceEgp.toInt()} EGP)';
    } else if (selectedCurrency == 'EUR') {
      final eur = (priceEgp / eurRate).round();
      return '€$eur EUR (${priceEgp.toInt()} EGP)';
    } else if (selectedCurrency == 'GBP') {
      final gbp = (priceEgp / gbpRate).round();
      return '£$gbp GBP (${priceEgp.toInt()} EGP)';
    }
    return '${priceEgp.toInt()} EGP';
  }

  static Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  static Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
  };

  // ──── AUTH ────

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _publicHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      currentUser = data['user'];
      return data;
    }
    throw Exception(_parseError(res.body));
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? languagePref,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: _publicHeaders,
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            if (phone != null) 'phone': phone,
            if (languagePref != null) 'languagePref': languagePref,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      currentUser = data['user'];
      return data;
    }
    throw Exception(_parseError(res.body));
  }

  static void logout() {
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;
  }

  static Future<void> _refreshAuth() async {
    if (_refreshToken == null) return;
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: _publicHeaders,
            body: jsonEncode({'refreshToken': _refreshToken}),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
      }
    } catch (_) {}
  }

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return (data['message'] is List ? (data['message'] as List).join('\n') : data['message']?.toString()) ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  // ──── FLIGHTS ────

  static Future<List<FlightModel>> getFlights({
    String? date,
    int? guests,
    String? packageType,
    String? sortBy,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/flights').replace(
        queryParameters: {
          if (date != null) 'date': date,
          if (guests != null) 'guests': guests.toString(),
          if (packageType != null && packageType != 'All')
            'packageType': packageType.toLowerCase(),
          if (sortBy != null) 'sortBy': sortBy.toLowerCase(),
        },
      );

      final res = await http
          .get(uri, headers: _publicHeaders)
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => FlightModel.fromJson(e)).toList();
      }
    } catch (_) {}

    return [];
  }

  // ──── OPERATORS ────

  static Future<List<OperatorModel>> getOperators() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/operators'), headers: _publicHeaders)
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((e) => OperatorModel.fromJson(e)).toList();
      }
    } catch (_) {}

    return [];
  }

  // ──── WEATHER ────

  static Future<WeatherModel?> getLuxorWeather() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/weather/luxor'), headers: _publicHeaders)
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        return WeatherModel.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}

    return null;
  }

  // ──── BOOKINGS ────

  static Future<BookingModel> createBooking({
    required String flightId,
    required int guestCount,
    required String pickupHotelName,
    String? couponCode,
    String? specialRequests,
  }) async {
    // Try real API first
    if (_accessToken != null) {
      try {
        final res = await http
            .post(
              Uri.parse('$baseUrl/bookings'),
              headers: _authHeaders,
              body: jsonEncode({
                'flightId': flightId,
                'guestCount': guestCount,
                'pickupHotelName': pickupHotelName,
                'pickupLocation': pickupHotelName,
                if (couponCode != null && couponCode.isNotEmpty)
                  'couponCode': couponCode,
                if (specialRequests != null) 'specialRequests': specialRequests,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = jsonDecode(res.body);
          return BookingModel(
            id: data['id'] ?? '',
            bookingRef: data['bookingRef'] ?? '',
            flightId: data['flightId'] ?? flightId,
            flightNumber: data['flight']?['flightNumber'] ?? 'NS-101',
            flightDate:
                data['flight']?['flightDate']?.toString().substring(0, 10) ??
                'Tomorrow',
            departureTime: data['flight']?['departureTime'] ?? '06:15 AM',
            operatorName: data['operator']?['nameEn'] ?? 'NileSky Fleet',
            packageName:
                data['flight']?['package']?['nameEn'] ?? 'Flight Package',
            guestCount: data['guestCount'] ?? guestCount,
            totalPriceEgp: double.tryParse(data['totalPriceEgp']?.toString() ?? '0') ?? 0,
            paymentStatus: data['paymentStatus'] ?? 'paid',
            bookingStatus: data['bookingStatus'] ?? 'confirmed',
            pickupHotelName: data['pickupHotelName'] ?? pickupHotelName,
            pickupTime: data['pickupTime'] ?? '03:45 AM',
            driverName: data['driver']?['name'],
            driverPhone: data['driver']?['phone'],
            driverCarModel: data['driver']?['carModel'],
            driverCarPlate: data['driver']?['carPlate'],
            qrCodeData: data['qrCodeData'] ?? data['bookingRef'] ?? 'NLK-2026',
            specialRequests: data['specialRequests'],
          );
        } else {
            throw Exception(_parseError(res.body));
        }
      } catch (e) {
          throw Exception(e.toString());
      }
    } else {
        throw Exception("User not logged in");
    }
  }

  // Get My Bookings
  static Future<List<BookingModel>> getMyBookings() async {
    if (_accessToken != null) {
      try {
        final res = await http
            .get(Uri.parse('$baseUrl/bookings'), headers: _authHeaders)
            .timeout(const Duration(seconds: 60));

        if (res.statusCode == 200) {
          final List list = jsonDecode(res.body);
          return list
              .map(
                (data) => BookingModel(
                  id: data['id'] ?? '',
                  bookingRef: data['bookingRef'] ?? '',
                  flightId: data['flightId'] ?? '',
                  flightNumber: data['flight']?['flightNumber'] ?? '-',
                  flightDate:
                      data['flight']?['flightDate']?.toString().substring(
                        0,
                        10,
                      ) ??
                      '-',
                  departureTime: data['flight']?['departureTime'] ?? '-',
                  operatorName: data['operator']?['nameEn'] ?? '-',
                  packageName: data['flight']?['package']?['nameEn'] ?? '-',
                  guestCount: data['guestCount'] ?? 0,
                  totalPriceEgp: double.tryParse(data['totalPriceEgp']?.toString() ?? '0') ?? 0,
                  paymentStatus: data['paymentStatus'] ?? 'pending',
                  bookingStatus: data['bookingStatus'] ?? 'pending',
                  pickupHotelName: data['pickupHotelName'] ?? '-',
                  pickupTime: data['pickupTime'] ?? '-',
                  driverName: data['driver']?['name'],
                  driverPhone: data['driver']?['phone'],
                  driverCarModel: data['driver']?['carModel'],
                  driverCarPlate: data['driver']?['carPlate'],
                  qrCodeData: data['qrCodeData'] ?? data['bookingRef'] ?? '',
                  specialRequests: data['specialRequests'],
                ),
              )
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  // Cancel Booking
  static Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    if (_accessToken == null) return false;
    try {
      final res = await http
          .patch(
            Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
            headers: _authHeaders,
            body: jsonEncode({'reason': reason ?? 'Cancelled by customer'}),
          )
          .timeout(const Duration(seconds: 60));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ──── REVIEWS ────

  static Future<bool> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
    List<String>? photos,
  }) async {
    if (_accessToken == null) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/reviews'),
            headers: _authHeaders,
            body: jsonEncode({
              'bookingId': bookingId,
              'rating': rating,
              if (comment != null) 'comment': comment,
              if (photos != null) 'photos': photos,
            }),
          )
          .timeout(const Duration(seconds: 60));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ──── COUPON VALIDATION ────

  static Future<Map<String, dynamic>?> validateCoupon(String code) async {
    try {
      final res = await http
          .get(
            Uri.parse('$baseUrl/coupons/validate/$code'),
            headers: _publicHeaders,
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

}
