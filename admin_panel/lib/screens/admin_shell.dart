import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import '../services/admin_language_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'operators_screen.dart';
import 'balloons_screen.dart';
import 'pilots_screen.dart';
import 'drivers_screen.dart';
import 'flights_screen.dart';
import 'bookings_screen.dart';
import 'payments_screen.dart';
import 'coupons_screen.dart';
import 'analytics_screen.dart';
import 'packages_screen.dart';
import 'users_screen.dart';
import 'reviews_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const List<_NavItemData> _navItems = [
    _NavItemData(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, key: 'navDashboard'),
    _NavItemData(icon: Icons.business_outlined, activeIcon: Icons.business, key: 'navOperators'),
    _NavItemData(icon: Icons.hot_tub_outlined, activeIcon: Icons.hot_tub, key: 'navBalloons'),
    _NavItemData(icon: Icons.person_outlined, activeIcon: Icons.person, key: 'navPilots'),
    _NavItemData(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, key: 'navDrivers'),
    _NavItemData(icon: Icons.flight_takeoff_outlined, activeIcon: Icons.flight_takeoff, key: 'navFlights'),
    _NavItemData(icon: Icons.book_online_outlined, activeIcon: Icons.book_online, key: 'navBookings'),
    _NavItemData(icon: Icons.payments_outlined, activeIcon: Icons.payments, key: 'navPayments'),
    _NavItemData(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer, key: 'navCoupons'),
    _NavItemData(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, key: 'navPackages'),
    _NavItemData(icon: Icons.people_outline, activeIcon: Icons.people, key: 'navUsers'),
    _NavItemData(icon: Icons.star_outline, activeIcon: Icons.star, key: 'navReviews'),
    _NavItemData(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, key: 'navAnalytics'),
  ];

  static const List<Widget> _screens = [
    DashboardScreen(),
    OperatorsScreen(),
    BalloonsScreen(),
    PilotsScreen(),
    DriversScreen(),
    FlightsScreen(),
    BookingsScreen(),
    PaymentsScreen(),
    CouponsScreen(),
    PackagesScreen(),
    UsersScreen(),
    ReviewsScreen(),
    AnalyticsScreen(),
  ];

  /// Change password dialog with full localization
  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AdminLanguageService.tr('changePassword'),
          style: const TextStyle(color: AdminColors.textPrimary, fontSize: 16),
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _passwordField(AdminLanguageService.tr('currentPassword'), currentCtrl),
              _passwordField(AdminLanguageService.tr('newPassword'), newCtrl),
              _passwordField(AdminLanguageService.tr('repeatPassword'), confirmCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AdminLanguageService.tr('cancel'),
              style: const TextStyle(color: AdminColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AdminLanguageService.tr('passwordMismatch')),
                  backgroundColor: AdminColors.error,
                ));
                return;
              }
              if (newCtrl.text.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AdminLanguageService.tr('passwordLengthError')),
                  backgroundColor: AdminColors.error,
                ));
                return;
              }
              Navigator.pop(ctx);
              try {
                await AdminApiService.changeMyPassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(AdminLanguageService.tr('passwordSuccess')),
                  backgroundColor: AdminColors.success,
                ));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString().replaceFirst('ApiException: ', '')),
                  backgroundColor: AdminColors.error,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(AdminLanguageService.tr('change')),
          ),
        ],
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(color: AdminColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
          filled: true,
          fillColor: AdminColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AdminColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AdminLanguageService.tr('logoutConfirmTitle'), style: const TextStyle(color: AdminColors.textPrimary)),
        content: Text(AdminLanguageService.tr('logoutConfirmBody'), style: const TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AdminLanguageService.tr('cancel'), style: const TextStyle(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              AdminApiService.logout();
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AdminLanguageService.tr('logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AdminLanguageService.localeNotifier,
      builder: (context, locale, child) {
        final user = AdminApiService.currentUser;
        final userName = user?['name'] ?? (AdminLanguageService.isArabic ? 'مدير النظام' : 'Admin User');
        final userEmail = user?['email'] ?? 'admin@nilesky.com';
        final userRole = user?['role'] ?? 'platform_admin';
        final roleDisplay = userRole == 'platform_admin'
            ? AdminLanguageService.tr('platformAdmin')
            : AdminLanguageService.tr('operatorAdmin');
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

        return Scaffold(
          body: Row(
            children: [
              // Sidebar Navigation
              Container(
                width: 240,
                color: AdminColors.sidebarBg,
                child: Column(
                  children: [
                    // Logo Header + Language Switcher
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 38,
                            height: 38,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.airplanemode_active,
                              size: 28,
                              color: AdminColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AdminLanguageService.tr('appName'),
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                                ),
                                Text(
                                  AdminLanguageService.tr('adminPanel'),
                                  style: const TextStyle(color: AdminColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // Language Switcher Toggle Button
                          InkWell(
                            onTap: () => AdminLanguageService.toggleLanguage(),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AdminColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.language, color: AdminColors.primary, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    AdminLanguageService.tr('switchLang'),
                                    style: const TextStyle(color: AdminColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AdminColors.border, height: 1),
                    const SizedBox(height: 8),

                    // Nav Items List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _navItems.length,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final item = _navItems[index];
                          final isActive = _selectedIndex == index;
                          final labelText = AdminLanguageService.tr(item.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() => _selectedIndex = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive ? AdminColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive ? item.activeIcon : item.icon,
                                        color: isActive ? AdminColors.primary : AdminColors.textMuted,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          labelText,
                                          style: TextStyle(
                                            color: isActive ? AdminColors.textPrimary : AdminColors.textSecondary,
                                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Footer with user info, change password and logout
                    const Divider(color: AdminColors.border, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AdminColors.primary.withValues(alpha: 0.2),
                            child: Text(initial, style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$userName • $roleDisplay', style: const TextStyle(color: AdminColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(userEmail, style: const TextStyle(color: AdminColors.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: AdminLanguageService.tr('changePassword'),
                            child: InkWell(
                              onTap: _changePassword,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.key_outlined, color: AdminColors.textMuted, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: AdminLanguageService.tr('logout'),
                            child: InkWell(
                              onTap: _handleLogout,
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.logout, color: AdminColors.textMuted, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              Expanded(
                child: _screens[_selectedIndex],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String key;

  const _NavItemData({required this.icon, required this.activeIcon, required this.key});
}
