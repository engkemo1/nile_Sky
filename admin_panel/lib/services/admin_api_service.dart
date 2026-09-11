import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central API service for the NileSky Admin Panel.
/// Connects to the NileSky NestJS backend for all CRUD operations.
class AdminApiService {
  // ──── LIVE DEPLOYED BACKEND URL (Render.com free tier) ────
  // Configurable at build time via --dart-define=API_URL=... or at runtime via setBaseUrl()
  static String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://nilesky-api.onrender.com',
  );

  static void setBaseUrl(String url) {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _currentUser;

  // ───────── Auth State ─────────
  static bool get isLoggedIn => _accessToken != null;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static String? get token => _accessToken;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  static Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
      };

  static void logout() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
  }

  // ───────── AUTH ─────────

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _publicHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _currentUser = data['user'];
      return data;
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<void> refreshAuth() async {
    if (_refreshToken == null) throw ApiException(401, 'No refresh token');
    final res = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _publicHeaders,
      body: jsonEncode({'refreshToken': _refreshToken}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
    } else {
      logout();
      throw ApiException(401, 'Session expired');
    }
  }

  // ───────── Generic HTTP helpers with auto-refresh ─────────

  static Future<dynamic> _get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    var res = await http.get(uri, headers: _authHeaders);
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http.get(uri, headers: _authHeaders);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    var res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    var res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<void> _delete(String path) async {
    var res = await http.delete(Uri.parse('$baseUrl$path'), headers: _authHeaders);
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http.delete(Uri.parse('$baseUrl$path'), headers: _authHeaders);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data['message']?.toString() ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  // ───────── ANALYTICS / DASHBOARD ─────────

  static Future<Map<String, dynamic>> getDashboard({String? operatorId}) async {
    return await _get('/analytics/dashboard', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
    });
  }

  // ───────── OPERATORS ─────────

  static Future<List<dynamic>> getOperators({String? status}) async {
    return await _get('/operators', queryParams: {
      if (status != null) 'status': status,
    });
  }

  static Future<Map<String, dynamic>> getOperator(String id) async {
    return await _get('/operators/$id');
  }

  static Future<Map<String, dynamic>> createOperator(Map<String, dynamic> data) async {
    return await _post('/operators', data);
  }

  static Future<Map<String, dynamic>> updateOperator(String id, Map<String, dynamic> data) async {
    return await _patch('/operators/$id', data);
  }

  static Future<Map<String, dynamic>> verifyOperator(String id) async {
    return await _patch('/operators/$id/verify', {});
  }

  static Future<void> deleteOperator(String id) async {
    await _delete('/operators/$id');
  }

  // ───────── FLIGHTS ─────────

  static Future<List<dynamic>> getFlights({String? date, String? status}) async {
    return await _get('/flights', queryParams: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    });
  }

  static Future<Map<String, dynamic>> getFlight(String id) async {
    return await _get('/flights/$id');
  }

  static Future<Map<String, dynamic>> createFlight(Map<String, dynamic> data) async {
    return await _post('/flights', data);
  }

  static Future<Map<String, dynamic>> updateFlight(String id, Map<String, dynamic> data) async {
    return await _patch('/flights/$id', data);
  }

  static Future<Map<String, dynamic>> updateFlightStatus(String id, String status, {String? reason}) async {
    return await _patch('/flights/$id/status', {
      'status': status,
      if (reason != null) 'cancellationReason': reason,
    });
  }

  static Future<Map<String, dynamic>> updateFlightWeather(String id, String weatherStatus) async {
    return await _patch('/flights/$id/weather', {'weatherStatus': weatherStatus});
  }

  static Future<void> deleteFlight(String id) async {
    await _delete('/flights/$id');
  }

  static Future<List<dynamic>> generateFlights(String targetDate) async {
    return await _post('/flights/generate', {'targetDate': targetDate});
  }

  // ───────── BOOKINGS ─────────

  static Future<List<dynamic>> getBookings({String? operatorId, String? flightId}) async {
    return await _get('/bookings', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
      if (flightId != null) 'flightId': flightId,
    });
  }

  static Future<Map<String, dynamic>> getBooking(String id) async {
    return await _get('/bookings/$id');
  }

  static Future<Map<String, dynamic>> cancelBooking(String id, {String? reason}) async {
    return await _patch('/bookings/$id/cancel', {
      if (reason != null) 'reason': reason,
    });
  }

  static Future<Map<String, dynamic>> checkInBooking(String ref) async {
    return await _patch('/bookings/check-in/$ref', {});
  }

  static Future<Map<String, dynamic>> assignDriver(String bookingId, String driverId, {String? pickupTime}) async {
    return await _patch('/bookings/$bookingId/assign-driver', {
      'driverId': driverId,
      if (pickupTime != null) 'pickupTime': pickupTime,
    });
  }

  // ───────── BALLOONS ─────────

  static Future<List<dynamic>> getBalloons({String? operatorId, String? status}) async {
    return await _get('/balloons', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
      if (status != null) 'status': status,
    });
  }

  static Future<Map<String, dynamic>> createBalloon(Map<String, dynamic> data) async {
    return await _post('/balloons', data);
  }

  static Future<Map<String, dynamic>> updateBalloon(String id, Map<String, dynamic> data) async {
    return await _patch('/balloons/$id', data);
  }

  static Future<void> deleteBalloon(String id) async {
    await _delete('/balloons/$id');
  }

  // ───────── PILOTS ─────────

  static Future<List<dynamic>> getPilots({String? operatorId, String? status}) async {
    return await _get('/pilots', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
      if (status != null) 'status': status,
    });
  }

  static Future<Map<String, dynamic>> createPilot(Map<String, dynamic> data) async {
    return await _post('/pilots', data);
  }

  static Future<Map<String, dynamic>> updatePilot(String id, Map<String, dynamic> data) async {
    return await _patch('/pilots/$id', data);
  }

  static Future<void> deletePilot(String id) async {
    await _delete('/pilots/$id');
  }

  // ───────── DRIVERS ─────────

  static Future<List<dynamic>> getDrivers({String? operatorId, String? status}) async {
    return await _get('/drivers', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
      if (status != null) 'status': status,
    });
  }

  static Future<Map<String, dynamic>> createDriver(Map<String, dynamic> data) async {
    return await _post('/drivers', data);
  }

  static Future<Map<String, dynamic>> updateDriver(String id, Map<String, dynamic> data) async {
    return await _patch('/drivers/$id', data);
  }

  static Future<void> deleteDriver(String id) async {
    await _delete('/drivers/$id');
  }

  // ───────── COUPONS ─────────

  static Future<List<dynamic>> getCoupons() async {
    return await _get('/coupons');
  }

  static Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async {
    return await _post('/coupons', data);
  }

  static Future<void> deleteCoupon(String id) async {
    await _delete('/coupons/$id');
  }

  static Future<Map<String, dynamic>> validateCoupon(String code, {String? operatorId}) async {
    return await _get('/coupons/validate/$code', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
    });
  }

  // ───────── REVIEWS ─────────

  static Future<List<dynamic>> getReviews({String? operatorId}) async {
    return await _get('/reviews', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
    });
  }

  // ───────── USERS ─────────

  static Future<List<dynamic>> getUsers() async {
    return await _get('/users');
  }

  // ───────── WEATHER ─────────

  static Future<Map<String, dynamic>> getLuxorWeather() async {
    return await _get('/weather/luxor');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
