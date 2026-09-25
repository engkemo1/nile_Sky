import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/flight.dart';
import '../models/weather.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../utils/date_helper.dart';
import 'explore_screen.dart';
import 'compare_screen.dart';
import 'flight_detail_screen.dart';
import 'my_bookings_screen.dart';
import 'active_flight_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;
  List<FlightModel> _flights = [];
  WeatherModel? _weather;
  bool _isLoading = true;
  int _guestCount = 2;
  String _selectedCategory = 'All';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnread();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final flights = await ApiService.getFlights(
      date: DateHelper.toApiDateString(_selectedDate),
    );
    final weather = await ApiService.getLuxorWeather();
    if (mounted) {
      setState(() {
        _flights = flights;
        _weather = weather;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await DateHelper.pickFlightDate(
      context: context,
      initialDate: _selectedDate,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadData();
    }
  }

  /// Opens the day-of screen for the nearest upcoming booking.
  int _unreadCount = 0;

  Future<void> _loadUnread() async {
    if (!ApiService.isLoggedIn) return;
    final items = await ApiService.getNotifications();
    if (!mounted) return;
    setState(() =>
        _unreadCount = items.where((n) => n['isRead'] != true).length);
  }

  Future<void> _openNextFlight() async {
    final bookings = await ApiService.getMyBookings();
    if (!mounted) return;

    final upcoming = bookings.where((b) => !b.isCancelled).toList()
      ..sort((a, b) => a.flightDate.compareTo(b.flightDate));

    if (upcoming.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('noUpcomingFlight'))),
      );
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveFlightScreen(booking: upcoming.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeContent(),
      const ExploreScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: pages[_bottomNavIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (idx) => setState(() => _bottomNavIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_filled, color: AppColors.primary),
              ),
              label: context.tr('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore, color: AppColors.primary),
              ),
              label: context.tr('explore'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.confirmation_number_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.confirmation_number, color: AppColors.primary),
              ),
              label: context.tr('myTrips'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              label: context.tr('profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Location & Quick Language / Currency Switchers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.accent.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('luxorEgypt'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                context.tr('westBankZone'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 1-Tap Language Quick Switcher Pill (Clean white with gold border)
                  GestureDetector(
                    onTap: () => LanguagePickerSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          Text(
                            LanguageService.currentLanguageCode.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Notifications — the API has been writing these all along
                  // (cancellations, pickup times) and nothing ever showed them.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: AppColors.textPrimary, size: 22),
                        tooltip: context.tr('notifications'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          );
                          _loadUnread();
                        },
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            constraints: const BoxConstraints(minWidth: 16),
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Currency Switcher
                  PopupMenuButton<String>(
                    initialValue: ApiService.selectedCurrency,
                    onSelected: (val) => setState(() => ApiService.selectedCurrency = val),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        ApiService.selectedCurrency,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'EGP', child: Text('EGP (ج.م)')),
                      PopupMenuItem(value: 'USD', child: Text('USD (\$)')),
                      PopupMenuItem(value: 'EUR', child: Text('EUR (€)')),
                      PopupMenuItem(value: 'GBP', child: Text('GBP (£)')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Active Flight Quick Access Banner (Soft Amber Glow)
              GestureDetector(
                // The banner used to open a day-of screen with no booking
                // behind it, which is how everyone saw the same invented
                // driver. Now it opens the passenger's own next flight, or
                // says plainly that there isn't one.
                onTap: _openNextFlight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldenGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.black, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr('sunriseFlightToday'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    context.tr('confirmedToFly'),
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '03:45 AM Pickup • Steigenberger Nile Palace',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Dynamic Greeting & Headline
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldenGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('greeting'),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('skyAdventureHeadline'),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 27, height: 1.15, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 18),

              // Weather & Safety Condition Card
              if (_weather != null) _buildWeatherCard(_weather!),
              const SizedBox(height: 18),

              // Dynamic Date & Guest Search Card
              _buildSearchCard(),
              const SizedBox(height: 24),

              // Compare Packages Action Card
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CompareScreen(flights: _flights)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldenGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.compare_arrows, color: Colors.black, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('comparePackages'),
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.tr('comparePackagesSub'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: AppColors.primaryDark, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // NileSky Packages Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('availableFlights'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18.5, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _bottomNavIndex = 1),
                    child: Text(
                      context.tr('seeAll'),
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: AppColors.primary)))
              else
                SizedBox(
                  height: 320,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _flights.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) => _buildFlightCard(_flights[index]),
                  ),
                ),
              const SizedBox(height: 28),

              // Why Fly with NileSky Section (Direct Brand Guarantees)
              _buildWhyNileSkySection(),
              const SizedBox(height: 24),

              // Why Luxor Info Card
              _buildWhyLuxorCard(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(WeatherModel weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.goldenGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.black, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperatureC}°C / ${weather.temperatureF}°F',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.tr('wind')}: ${weather.windSpeedKmH} km/h • ${context.tr('visibility')}: ${weather.visibilityKm} km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('favorable'),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.secondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LanguageService.isArabic
                        ? 'الظروف الجوية مثالية ومصرح بها رسمياً من سلطة الطيران المدني.'
                        : weather.flightSafetySummary,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    final formattedSelectedDate = DateHelper.formatFlightDate(
      context,
      DateHelper.toApiDateString(_selectedDate),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('findFlightTitle'),
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15.5),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Date & Guest Selector Row
          Row(
            children: [
              // Dynamic Date Picker Button
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primaryDark, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('date'), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              Text(
                                formattedSelectedDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Guests Stepper
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('guests'), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            Text(
                              '$_guestCount ${context.tr('persons')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_guestCount > 1) setState(() => _guestCount--);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.remove, size: 12, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _guestCount++),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldenGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add, size: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilter('All', context.tr('allCategory')),
                _buildCategoryFilter('Standard', context.tr('standardCategory')),
                _buildCategoryFilter('Premium', context.tr('premiumCategory')),
                _buildCategoryFilter('Private', context.tr('privateCategory')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => setState(() => _bottomNavIndex = 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: Colors.black, size: 18),
                  const SizedBox(width: 8),
                  Text(context.tr('searchFlightsInLuxor')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.goldenGradient : null,
            color: isSelected ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlightCard(FlightModel flight) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FlightDetailScreen(flight: flight)),
        );
      },
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                  child: Image.network(
                    flight.coverPhotoUrl,
                    height: 132,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (flight.badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.sunriseGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        flight.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${flight.operatorRating}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flight.packageName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.secondary, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'NileSky Official Fleet',
                        style: const TextStyle(color: AppColors.secondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Duration, Pickup, Breakfast tags
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text('${flight.durationMinutes}m', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(width: 8),
                      const Icon(Icons.directions_car, size: 13, color: AppColors.secondary),
                      const SizedBox(width: 3),
                      Text(context.tr('pickup'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      if (flight.hasBreakfast) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.restaurant, size: 13, color: AppColors.primaryDark),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Price and Seats Left
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ApiService.formatPrice(flight.priceEgp),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(context.tr('perPerson'), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (flight.remainingSeats > 4 ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (flight.remainingSeats > 4 ? AppColors.success : AppColors.warning).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${flight.remainingSeats} ${context.tr('seatsLeft')}',
                          style: TextStyle(
                            color: flight.remainingSeats > 4 ? AppColors.success : AppColors.warning,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Why Fly With NileSky Section
  Widget _buildWhyNileSkySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('whyNileSky'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18.5, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('whyNileSkySub'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 14),

        _buildNileSkyFeatureCard(
          icon: Icons.shield_outlined,
          iconColor: AppColors.success,
          title: context.tr('nileSkyFeature1Title'),
          subtitle: context.tr('nileSkyFeature1Sub'),
        ),
        const SizedBox(height: 10),
        _buildNileSkyFeatureCard(
          icon: Icons.flight_takeoff,
          iconColor: AppColors.primaryDark,
          title: context.tr('nileSkyFeature2Title'),
          subtitle: context.tr('nileSkyFeature2Sub'),
        ),
        const SizedBox(height: 10),
        _buildNileSkyFeatureCard(
          icon: Icons.directions_boat,
          iconColor: AppColors.secondary,
          title: context.tr('nileSkyFeature3Title'),
          subtitle: context.tr('nileSkyFeature3Sub'),
        ),
        const SizedBox(height: 10),
        _buildNileSkyFeatureCard(
          icon: Icons.verified_user_outlined,
          iconColor: AppColors.primaryDark,
          title: context.tr('nileSkyFeature4Title'),
          subtitle: context.tr('nileSkyFeature4Sub'),
        ),
      ],
    );
  }

  Widget _buildNileSkyFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyLuxorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F2FE),
            Color(0xFFFFFBEB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.tr('whyLuxorTitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('whyLuxorDesc'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: Text(
              context.tr('safeWindBadge'),
              style: const TextStyle(color: AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
