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
      'navBalloons': 'الأسطول والبالونات',
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
