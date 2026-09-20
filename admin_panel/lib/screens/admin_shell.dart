import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'operators_screen.dart';
import 'balloons_screen.dart';
import 'pilots_screen.dart';
import 'drivers_screen.dart';
import 'flights_screen.dart';
import 'bookings_screen.dart';
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

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.business_outlined, activeIcon: Icons.business, label: 'Operators'),
    _NavItem(icon: Icons.hot_tub_outlined, activeIcon: Icons.hot_tub, label: 'Balloons'),
    _NavItem(icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Pilots'),
    _NavItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, label: 'Drivers'),
    _NavItem(icon: Icons.flight_takeoff_outlined, activeIcon: Icons.flight_takeoff, label: 'Flights'),
    _NavItem(icon: Icons.book_online_outlined, activeIcon: Icons.book_online, label: 'Bookings'),
    _NavItem(icon: Icons.local_offer_outlined, activeIcon: Icons.local_offer, label: 'Coupons'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Packages'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users'),
    _NavItem(icon: Icons.star_outline, activeIcon: Icons.star, label: 'Reviews'),
    _NavItem(icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
  ];

  static const List<Widget> _screens = [
    DashboardScreen(),
    OperatorsScreen(),
    BalloonsScreen(),
    PilotsScreen(),
    DriversScreen(),
    FlightsScreen(),
    BookingsScreen(),
    CouponsScreen(),
    PackagesScreen(),
    UsersScreen(),
    ReviewsScreen(),
    AnalyticsScreen(),
  ];

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: AdminColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: AdminColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted)),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AdminApiService.currentUser;
    final userName = user?['name'] ?? 'Admin User';
    final userEmail = user?['email'] ?? 'admin@nilesky.com';
    final userRole = user?['role'] ?? 'platform_admin';
    final roleDisplay = userRole == 'platform_admin' ? 'Platform Admin' : 'Operator Admin';
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
                // Logo Header
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AdminColors.primary, AdminColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('🎈', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NileSky',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                          ),
                          const Text(
                            'Admin Panel',
                            style: TextStyle(color: AdminColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: AdminColors.border, height: 1),
                const SizedBox(height: 8),

                // Nav Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final item = _navItems[index];
                      final isActive = _selectedIndex == index;
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
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isActive ? AdminColors.textPrimary : AdminColors.textSecondary,
                                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                                      fontSize: 13,
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

                // Footer with user info and logout
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
                      InkWell(
                        onTap: _handleLogout,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.logout, color: AdminColors.textMuted, size: 18),
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
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
