import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API service for the NileSky Admin Panel.
/// Connects to the NileSky NestJS backend for all CRUD operations.
class AdminApiService {
  // ──── LIVE DEPLOYED BACKEND URL (Render.com free tier) ────
  // Configurable at build time via --dart-define=API_URL=... or at runtime via setBaseUrl()
  static String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://nile-sky.vercel.app',
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


  /// Render's free tier sleeps after 15 min idle; the next request takes
  /// 30-60s to wake it. Without this every call hangs forever on a dead host.
  static const Duration _requestTimeout = Duration(seconds: 60);

  static Never _timedOut() => throw ApiException(
        408,
        'The server did not respond in 60s. If this is a free Render instance '
        'it may be waking up — try again in a moment.',
      );

  static void logout() {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    // Fire and forget: clearing storage must not block the UI.
    _clearSession();
  }

  // ───────── AUTH ─────────

  // ───────── Session persistence ─────────
  // Without this the tokens live only in memory, so every page refresh (and
  // every app restart) drops the admin back to the login screen.
  static const _kAccess = 'nilesky.accessToken';
  static const _kRefresh = 'nilesky.refreshToken';
  static const _kUser = 'nilesky.user';

  static Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) {
        await prefs.setString(_kAccess, _accessToken!);
      } else {
        await prefs.remove(_kAccess);
      }
      if (_refreshToken != null) {
        await prefs.setString(_kRefresh, _refreshToken!);
      } else {
        await prefs.remove(_kRefresh);
      }
      if (_currentUser != null) {
        await prefs.setString(_kUser, jsonEncode(_currentUser));
      } else {
        await prefs.remove(_kUser);
      }
    } catch (_) {
      // Storage can be unavailable (private windows, blocked site data).
      // A lost session is recoverable; a crash here is not worth it.
    }
  }

  /// Restores a saved session on startup. Returns true if one was found and
  /// the token still works.
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString(_kAccess);
      if (access == null) return false;
      _accessToken = access;
      _refreshToken = prefs.getString(_kRefresh);
      final user = prefs.getString(_kUser);
      if (user != null) _currentUser = jsonDecode(user) as Map<String, dynamic>;

      // Verify rather than trust: the token may have expired while away.
      await _get('/users/me');
      return true;
    } catch (_) {
      await _clearSession();
      return false;
    }
  }

  static Future<void> _clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccess);
      await prefs.remove(_kRefresh);
      await prefs.remove(_kUser);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: _publicHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_requestTimeout, onTimeout: _timedOut);
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      _currentUser = data['user'];
      await _persistSession();
      return data;
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<void> refreshAuth() async {
    if (_refreshToken == null) throw ApiException(401, 'No refresh token');
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: _publicHeaders,
          body: jsonEncode({'refreshToken': _refreshToken}),
        )
        .timeout(_requestTimeout, onTimeout: _timedOut);
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken'];
      await _persistSession();
    } else {
      logout();
      throw ApiException(401, 'Session expired');
    }
  }

  // ───────── Generic HTTP helpers with auto-refresh ─────────

  static Future<dynamic> _get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    var res = await http.get(uri, headers: _authHeaders).timeout(_requestTimeout, onTimeout: _timedOut);
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http.get(uri, headers: _authHeaders).timeout(_requestTimeout, onTimeout: _timedOut);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    var res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _authHeaders,
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout, onTimeout: _timedOut);
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _authHeaders,
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout, onTimeout: _timedOut);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    var res = await http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: _authHeaders,
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout, onTimeout: _timedOut);
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: _authHeaders,
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout, onTimeout: _timedOut);
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, _parseError(res.body));
  }

  static Future<void> _delete(String path) async {
    var res = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _authHeaders)
        .timeout(_requestTimeout, onTimeout: _timedOut);
    if (res.statusCode == 401 && _refreshToken != null) {
      await refreshAuth();
      res = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _authHeaders)
        .timeout(_requestTimeout, onTimeout: _timedOut);
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

  /// Sets a user's role, and for an operator admin which operator they belong
  /// to. Bookings and flights are scoped by that link, so an operator admin
  /// without one is refused rather than shown every operator's data.
  static Future<void> setUserRole(
    String id,
    String role, {
    String? operatorId,
  }) async {
    await _patch('/users/$id/role', {
      'role': role,
      if (operatorId != null) 'operatorId': operatorId,
    });
  }

  /// Rotates the signed-in admin's own password. The seeded one ended up in
  /// a public repository, so there has to be a way to change it from the UI.
  static Future<void> changeMyPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _patch('/users/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ───────── FLIGHTS ─────────

  /// The API defaults to SCHEDULED only when it is given no filter at all, so
  /// a board that asked for "everything" silently lost every flight the moment
  /// it was cancelled or completed. Passing a date range instead keeps the
  /// whole history visible.
  static Future<List<dynamic>> getFlights({
    String? date,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) async {
    return await _get('/flights', queryParams: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
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

  /// POST /flights/generate returns {"message": "...", "flights": [...]},
  /// not a bare list.
  /// The pre-dawn go/no-go. Pass false to withdraw a confirmation.
  static Future<Map<String, dynamic>> confirmFlight(String id, {bool confirmed = true}) async {
    return await _patch('/flights/$id/confirm', {'confirmed': confirmed});
  }

  static Future<Map<String, dynamic>> generateFlights(String targetDate) async {
    return await _post('/flights/generate', {'targetDate': targetDate});
  }

  static Future<List<dynamic>> getFlightTemplates() async {
    return await _get('/flight-templates');
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

  // ───────── PAYMENTS ─────────

  /// GET /payments/booking/:bookingId — returns the raw Payment rows for one
  /// booking, newest first. This is the only *read* route the payments module
  /// exposes: there is no "list all payments" endpoint, so a payments screen
  /// has to start from bookings and drill in per booking.
  static Future<List<dynamic>> getPaymentsForBooking(String bookingId) async {
    return await _get('/payments/booking/$bookingId');
  }

  /// POST /payments/:id/refund — platform_admin / operator_admin only.
  /// [paymentId] is the Payment row's id, NOT the booking id. The controller
  /// reads the reason with @Body('reason'), so it goes in the body as a bare
  /// `reason` key and may be omitted entirely.
  ///
  /// Note: the backend only flips the payment/booking records to `refunded`
  /// and releases the flight seats — it does not call any payment gateway,
  /// so no money moves.
  static Future<Map<String, dynamic>> refundPayment(String paymentId,
      {String? reason}) async {
    return await _post('/payments/$paymentId/refund', {
      if (reason != null) 'reason': reason,
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

  /// The moderation list: hidden reviews included, so they can be restored.
  static Future<List<dynamic>> getReviews({String? operatorId}) async {
    return await _get('/reviews/all', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
    });
  }

  /// Hides a review from the app, or puts it back. The row is kept either way,
  /// and the operator's public rating is recomputed.
  static Future<void> setReviewVisibility(String id, bool isVisible) async {
    await _patch('/reviews/$id/visibility', {'isVisible': isVisible});
  }

  /// What each operator is owed for a period, and what the platform keeps.
  static Future<Map<String, dynamic>> getPayouts({
    String? from,
    String? to,
    String? operatorId,
  }) async {
    return await _get('/analytics/payouts', queryParams: {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (operatorId != null) 'operatorId': operatorId,
    });
  }


  // ───────── USERS ─────────

  static Future<List<dynamic>> getUsers() async {
    return await _get('/users');
  }

  // ───────── WEATHER ─────────

  // ───────── PACKAGES ─────────

  static Future<List<dynamic>> getPackages({String? operatorId}) async {
    return await _get('/packages', queryParams: {
      if (operatorId != null) 'operatorId': operatorId,
    });
  }

  static Future<Map<String, dynamic>> createPackage(Map<String, dynamic> data) async {
    return await _post('/packages', data);
  }

  static Future<Map<String, dynamic>> updatePackage(String id, Map<String, dynamic> data) async {
    return await _patch('/packages/$id', data);
  }

  static Future<void> deletePackage(String id) async {
    await _delete('/packages/$id');
  }

  // ───────── FLIGHT TEMPLATES ─────────

  static Future<Map<String, dynamic>> createFlightTemplate(Map<String, dynamic> data) async {
    return await _post('/flight-templates', data);
  }

  static Future<Map<String, dynamic>> updateFlightTemplate(String id, Map<String, dynamic> data) async {
    return await _patch('/flight-templates/$id', data);
  }

  static Future<void> deleteFlightTemplate(String id) async {
    await _delete('/flight-templates/$id');
  }

  // ───────── USERS ─────────

  static Future<Map<String, dynamic>> updateUserStatus(String id, bool isActive) async {
    return await _patch('/users/$id/status', {'isActive': isActive});
  }

  // ───────── NOTIFICATIONS ─────────

  /// type must be one of: booking_confirm, reminder, pickup, flight_update,
  /// weather, review_request, promo.
  static Future<Map<String, dynamic>> sendNotification({
    required String userId,
    required String titleEn,
    required String bodyEn,
    required String type,
    String? titleAr,
    String? bodyAr,
  }) async {
    return await _post('/notifications/send', {
      'userId': userId,
      'titleEn': titleEn,
      'bodyEn': bodyEn,
      'type': type,
      if (titleAr != null && titleAr.isNotEmpty) 'titleAr': titleAr,
      if (bodyAr != null && bodyAr.isNotEmpty) 'bodyAr': bodyAr,
    });
  }

  // ───────── MEDIA ─────────

  /// Uploads raw bytes and returns the stored file's metadata, including a
  /// `url` such as /upload/<id>. Pair it with [mediaUrl] to display it.
  static Future<Map<String, dynamic>> uploadImage({
    required String filename,
    required String mimetype,
    required List<int> bytes,
    String folder = 'flights',
  }) async {
    return await _post('/upload/image', {
      'filename': filename,
      'mimetype': mimetype,
      'base64': base64Encode(bytes),
      'folder': folder,
    });
  }

  static Future<List<dynamic>> listMedia({String? folder}) async {
    return await _get('/upload/list', queryParams: {
      if (folder != null) 'folder': folder,
    });
  }

  static Future<void> deleteMedia(String id) async {
    await _delete('/upload/$id');
  }

  /// Turns a stored path such as /upload/<id> into a full URL. Absolute URLs
  /// (older records, or links typed by hand) are returned untouched.
  static String mediaUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return '$baseUrl${pathOrUrl.startsWith('/') ? '' : '/'}$pathOrUrl';
  }

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
