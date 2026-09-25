import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central localization and language management service for NileSky Admin Panel.
/// Default language is Arabic (العربية).
class AdminLanguageService {
  static const String _prefKey = 'nilesky.admin_lang';

  /// ValueNotifier for instant UI reaction across all widgets when locale changes.
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(
    const Locale('ar'), // Arabic is the main default language
  );

  static String get currentLanguage => localeNotifier.value.languageCode;
  static bool get isArabic => currentLanguage == 'ar';
  static TextDirection get textDirection => isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Restores saved language preference on app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey);
      if (savedLang != null && (savedLang == 'ar' || savedLang == 'en')) {
        localeNotifier.value = Locale(savedLang);
      } else {
        localeNotifier.value = const Locale('ar'); // Default to Arabic
      }
    } catch (_) {}
  }

  /// Sets active language and persists choice
  static Future<void> setLanguage(String langCode) async {
    if (langCode == 'ar' || langCode == 'en') {
      localeNotifier.value = Locale(langCode);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, langCode);
      } catch (_) {}
    }
  }

  /// Toggles between Arabic and English
  static Future<void> toggleLanguage() async {
    final nextLang = isArabic ? 'en' : 'ar';
    await setLanguage(nextLang);
  }

  /// Translation getter with fallback
  static String tr(String key) {
    final lang = currentLanguage;
    final dict = _translations[lang] ?? _translations['ar']!;
    if (dict.containsKey(key)) return dict[key]!;
    // Fallback to English if missing in Arabic, or raw key
    return _translations['en']?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'ar': {
      // General & App Shell
      'appName': 'نايل سكاي',
      'adminPanel': 'لوحة الإدارة',
      'luxorOperations': 'عمليات الطيران بالأقصر',
      'platformAdmin': 'مدير المنصة',
      'operatorAdmin': 'مدير شركة',
      'changePassword': 'تغيير كلمة المرور',
      'logout': 'تسجيل الخروج',
      'logoutConfirmTitle': 'تسجيل الخروج',
      'logoutConfirmBody': 'هل أنت تأكد من إغلاق الجلسة وتسجيل الخروج؟',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'refresh': 'تحديث',
      'search': 'بحث',
      'filter': 'تصفية',
      'actions': 'الإجراءات',
      'status': 'الحالة',
      'all': 'الكل',
      'retry': 'إعادة المحاولة',
      'yes': 'نعم',
      'no': 'لا',
      'close': 'إغلاق',
      'language': 'اللغة',
      'switchLang': 'English',

      // Navigation Sidebar
      'navDashboard': 'لوحة التحكم',
      'navOperators': 'شركات المنطاد',
      'navBalloons': 'المنطاد والبالونات',
      'navPilots': 'الكباتن والطيارين',
      'navDrivers': 'السائقين والتوصيل',
      'navFlights': 'جدول الرحلات',
      'navBookings': 'الحجوزات',
      'navPayments': 'المدفوعات والمستحقات',
      'navCoupons': 'كوبونات الخصم',
      'navPackages': 'باقات الرحلات',
      'navUsers': 'دليل المستخدمين',
      'navReviews': 'التقييمات والآراء',
      'navAnalytics': 'الإحصائيات والتقارير',

      // Password Change Dialog
      'currentPassword': 'كلمة المرور الحالية',
      'newPassword': 'كلمة المرور الجديدة (10 رموز على الأقل)',
      'repeatPassword': 'تأكيد كلمة المرور الجديدة',
      'passwordMismatch': 'كلمتا المرور غير متطابقتين',
      'passwordLengthError': 'يجب أن لا تقل كلمة المرور عن 10 رموز',
      'passwordSuccess': 'تم تغيير كلمة المرور بنجاح. يرجى إعادة الدخول على الأجهزة الأخرى.',
      'change': 'تغيير',

      // Login Screen
      'loginTitle': 'نايل سكاي - لوحة الإدارة',
      'loginSubtitle': 'سجّل الدخول لإدارة رحلات المنطاد والعملاء بالأقصر',
      'emailAddress': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'signIn': 'تسجيل الدخول',
      'signingIn': 'جارٍ تسجيل الدخول…',

      // Dashboard
      'dashboardTitle': 'لوحة التحكم والمتابعة',
      'todayFlights': 'رحلات اليوم',
      'scheduledForToday': 'المجدولة لليوم',
      'todayBookings': 'حجوزات اليوم',
      'passengers': 'ركاب',
      'todayRevenue': 'إيرادات اليوم',
      'allTimeRevenue': 'إجمالي الإيرادات',
      'totalBookings': 'حجز إجمالي',
      'activeOperators': 'الشركات النشطة',
      'registeredOperators': 'شركة مسجلة',
      'passengersToday': 'ركاب اليوم',
      'acrossAllFlights': 'عبر كل الرحلات',
      'todaySchedule': 'جدول رحلات اليوم',
      'recentBookings': 'أحدث الحجوزات',
      'weatherStatus': 'حالة الطقس',
      'flightStatusGo': 'الطيران: آمن ومصرح ✅',
      'flightStatusHold': 'الطيران: قيد التقييم ⚠️',
      'flightStatusNoGo': 'الطيران: معلق رسمياً ❌',
      'weatherUnavailable': 'بيانات الطقس غير متاحة',

      // Operators Screen
      'operatorsTitle': 'شركات طيران المنطاد',
      'addOperator': 'إضافة شركة جديدة',
      'companyName': 'اسم الشركة',
      'licenseNumber': 'رقم الترخيص',
      'contactPerson': 'مسؤول التواصل',

      // Balloons Screen
      'balloonsTitle': 'إدارة بالونات المنطاد',
      'addBalloon': 'إضافة بالون جديد',
      'balloonModel': 'موديل المنطاد',
      'balloonCapacity': 'سعة البالون (عدد الركاب)',
      'registrationNum': 'رقم التسجيل الرسمى',

      // Pilots Screen
      'pilotsTitle': 'الكباتن والطيارين المعتمدين',
      'addPilot': 'إضافة طيار جديد',
      'licenseExp': 'انتهاء الترخيص',
      'flightHours': 'ساعات الطيران',

      // Drivers Screen
      'driversTitle': 'السائقين وسيارات التوصيل',
      'addDriver': 'إضافة سائق جديد',
      'vehicleModel': 'نوع السيارة / الحافلة',
      'plateNumber': 'رقم اللوحة',

      // Flights Screen
      'flightsTitle': 'جدول رحلات المنطاد',
      'createFlight': 'إضافة رحلة جديدة',
      'generateFlights': 'توليد رحلات اليوم تلقائياً',
      'departureTime': 'وقت الإقلاع',
      'meetingPoint': 'نقطة التجمع بالبر الغربي',

      // Bookings Screen
      'bookingsTitle': 'سجل الحجوزات',
      'bookingRef': 'رقم مرجع الحجز',
      'checkIn': 'تسجيل وصول العميل',
      'assignDriver': 'تخصيص سائق التوصيل',
      'cancelBooking': 'إلغاء الحجز',

      // Payments Screen
      'paymentsTitle': 'المدفوعات ومستحقات الشركات',
      'payoutSettlements': 'صافي المستحقات للشركات',
      'refundPayment': 'استرداد المبلغ',
      'platformCommission': 'عمولة المنصة',

      // Coupons Screen
      'couponsTitle': 'كوبونات الخصم والترويج',
      'addCoupon': 'إضافة كوبون خصم',
      'couponCode': 'كود الكوبون',
      'discountPct': 'نسبة الخصم %',
      'validUntil': 'تاريخ انتهاء الصلاحية',

      // Packages Screen
      'packagesTitle': 'باقات رحلات المنطاد',
      'addPackage': 'إضافة باقة جديدة',
      'packageName': 'اسم الباقة',
      'packageType': 'نوع الباقة (أساسية / مميزة / VIP)',

      // Users Screen
      'usersTitle': 'دليل المستخدمين والعملاء',
      'sendNotification': 'إرسال تنبيه / إشعار',
      'changeUserRole': 'تغيير الصلاحية والمشغّل',

      // Reviews Screen
      'reviewsTitle': 'التقييمات وآراء العملاء',
      'hideReview': 'إخفاء التقييم المسيء',
      'restoreReview': 'استعادة التقييم',
      'overallRating': 'التقييم العام للشركة',

      // Analytics Screen
      'analyticsTitle': 'التقارير والإحصائيات الشاملة',
      'totalRevenue': 'إجمالي الإيرادات والتحصيلات',
      'totalPassengers': 'إجمالي الركاب المسافرين',

      // Table Columns & Fields
      'flightNum': 'رقم الرحلة',
      'departure': 'الإقلاع',
      'bookedCap': 'المحجوز / السعة',
      'ref': 'المرجع',
      'guest': 'العميل',
      'guestsCount': 'الأفراد',
      'total': 'الإجمالي',
      'payment': 'الدفع',
      'name': 'الاسم',
      'email': 'البريد الإلكتروني',
      'phone': 'رقم الهاتف',
      'role': 'الصلاحية',
      'verified': 'معتمد',
      'active': 'مفعل',
      'inactive': 'معطل',
      'date': 'التاريخ',
      'operator': 'الشركة',
      'price': 'السعر',

      // Roles
      'customer': 'عميل',
      'roleOperatorAdmin': 'مدير شركة',
      'rolePlatformAdmin': 'مدير النظام (أدمن)',
    },

    'en': {
      // General & App Shell
      'appName': 'NileSky',
      'adminPanel': 'Admin Panel',
      'luxorOperations': 'Luxor Operations',
      'platformAdmin': 'Platform Admin',
      'operatorAdmin': 'Operator Admin',
      'changePassword': 'Change Password',
      'logout': 'Logout',
      'logoutConfirmTitle': 'Logout',
      'logoutConfirmBody': 'Are you sure you want to sign out?',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'refresh': 'Refresh',
      'search': 'Search',
      'filter': 'Filter',
      'actions': 'Actions',
      'status': 'Status',
      'all': 'All',
      'retry': 'Retry',
      'yes': 'Yes',
      'no': 'No',
      'close': 'Close',
      'language': 'Language',
      'switchLang': 'العربية',

      // Navigation Sidebar
      'navDashboard': 'Dashboard',
      'navOperators': 'Operators',
      'navBalloons': 'Balloons',
      'navPilots': 'Pilots',
      'navDrivers': 'Drivers',
      'navFlights': 'Flights',
      'navBookings': 'Bookings',
      'navPayments': 'Payments',
      'navCoupons': 'Coupons',
      'navPackages': 'Packages',
      'navUsers': 'Users',
      'navReviews': 'Reviews',
      'navAnalytics': 'Analytics',

      // Password Change Dialog
      'currentPassword': 'Current password',
      'newPassword': 'New password (10+ characters)',
      'repeatPassword': 'Repeat the new password',
      'passwordMismatch': 'The two new passwords do not match',
      'passwordLengthError': 'Use at least 10 characters',
      'passwordSuccess': 'Password changed. Sign in again on your other devices.',
      'change': 'Change',

      // Login Screen
      'loginTitle': 'NileSky Admin',
      'loginSubtitle': 'Sign in to manage Luxor balloon operations',
      'emailAddress': 'Email address',
      'password': 'Password',
      'signIn': 'Sign In',
      'signingIn': 'Signing in…',

      // Dashboard
      'dashboardTitle': 'Dashboard',
      'todayFlights': "Today's Flights",
      'scheduledForToday': 'Scheduled for today',
      'todayBookings': 'Today Bookings',
      'passengers': 'passengers',
      'todayRevenue': 'Today Revenue',
      'allTimeRevenue': 'All-Time Revenue',
      'totalBookings': 'total bookings',
      'activeOperators': 'Active Operators',
      'registeredOperators': 'Registered operators',
      'passengersToday': 'Passengers Today',
      'acrossAllFlights': 'Across all flights',
      'todaySchedule': "Today's Flight Schedule",
      'recentBookings': 'Recent Bookings',
      'weatherStatus': 'Weather Status',
      'flightStatusGo': 'Flights: GO ✅',
      'flightStatusHold': 'Flights: HOLD ⚠️',
      'flightStatusNoGo': 'Flights: NO-GO ❌',
      'weatherUnavailable': 'Weather: unavailable',

      // Operators Screen
      'operatorsTitle': 'Balloon Operators',
      'addOperator': 'Add New Operator',
      'companyName': 'Company Name',
      'licenseNumber': 'License Number',
      'contactPerson': 'Contact Person',

      // Balloons Screen
      'balloonsTitle': 'Balloons Management',
      'addBalloon': 'Add New Balloon',
      'balloonModel': 'Balloon Model',
      'balloonCapacity': 'Capacity (Passengers)',
      'registrationNum': 'Registration Number',

      // Pilots Screen
      'pilotsTitle': 'Certified Pilots',
      'addPilot': 'Add New Pilot',
      'licenseExp': 'License Expiration',
      'flightHours': 'Flight Hours',

      // Drivers Screen
      'driversTitle': 'Drivers & Transport Vans',
      'addDriver': 'Add New Driver',
      'vehicleModel': 'Vehicle Model',
      'plateNumber': 'Plate Number',

      // Flights Screen
      'flightsTitle': 'Flight Schedule',
      'createFlight': 'Create Flight',
      'generateFlights': 'Generate Today Flights',
      'departureTime': 'Departure Time',
      'meetingPoint': 'West Bank Meeting Field',

      // Bookings Screen
      'bookingsTitle': 'Bookings Record',
      'bookingRef': 'Booking Ref',
      'checkIn': 'Check-In Passenger',
      'assignDriver': 'Assign Driver',
      'cancelBooking': 'Cancel Booking',

      // Payments Screen
      'paymentsTitle': 'Payments & Payouts',
      'payoutSettlements': 'Operator Net Payouts',
      'refundPayment': 'Refund Payment',
      'platformCommission': 'Platform Commission',

      // Coupons Screen
      'couponsTitle': 'Discount Coupons',
      'addCoupon': 'Add Discount Coupon',
      'couponCode': 'Coupon Code',
      'discountPct': 'Discount %',
      'validUntil': 'Valid Until',

      // Packages Screen
      'packagesTitle': 'Flight Packages',
      'addPackage': 'Add New Package',
      'packageName': 'Package Name',
      'packageType': 'Package Type (Standard / Premium / VIP)',

      // Users Screen
      'usersTitle': 'Users & Guests Directory',
      'sendNotification': 'Send Notification',
      'changeUserRole': 'Change Role & Operator',

      // Reviews Screen
      'reviewsTitle': 'Reviews & Ratings',
      'hideReview': 'Hide Review',
      'restoreReview': 'Restore Review',
      'overallRating': 'Overall Operator Rating',

      // Analytics Screen
      'analyticsTitle': 'Reports & Analytics',
      'totalRevenue': 'Total Revenue',
      'totalPassengers': 'Total Passengers Flown',

      // Table Columns & Fields
      'flightNum': 'FLIGHT #',
      'departure': 'DEPARTURE',
      'bookedCap': 'BOOKED / CAP',
      'ref': 'REF',
      'guest': 'GUEST',
      'guestsCount': 'GUESTS',
      'total': 'TOTAL',
      'payment': 'PAYMENT',
      'name': 'NAME',
      'email': 'EMAIL',
      'phone': 'PHONE',
      'role': 'ROLE',
      'verified': 'VERIFIED',
      'active': 'ACTIVE',
      'inactive': 'INACTIVE',
      'date': 'DATE',
      'operator': 'OPERATOR',
      'price': 'PRICE',

      // Roles
      'customer': 'Customer',
      'roleOperatorAdmin': 'Operator Admin',
      'rolePlatformAdmin': 'Platform Admin',
    },
  };
}
