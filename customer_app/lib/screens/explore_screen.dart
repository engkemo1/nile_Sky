import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/flight.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'flight_detail_screen.dart';
import 'compare_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'price';
  List<FlightModel> _flights = [];
  bool _isLoading = true;
  final Set<String> _selectedToCompare = {};

  final List<String> _categories = ['All', 'Standard', 'Premium', 'Private'];

  @override
  void initState() {
    super.initState();
    _fetchFlights();
  }

  Future<void> _fetchFlights() async {
    setState(() => _isLoading = true);
    final flights = await ApiService.getFlights(
      packageType: _selectedCategory,
      sortBy: _sortBy,
    );
    if (mounted) {
      setState(() {
        _flights = flights;
        _isLoading = false;
      });
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'Standard':
        return context.tr('standardCategory');
      case 'Premium':
        return context.tr('premiumCategory');
      case 'Private':
        return context.tr('privateCategory');
      default:
        return context.tr('allCategory');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('availableFlightsTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
        ),
        actions: [
          // 1-Tap Language Quick Switcher
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),

          // Currency selector button
          PopupMenuButton<String>(
            initialValue: ApiService.selectedCurrency,
            onSelected: (val) {
              setState(() {
                ApiService.selectedCurrency = val;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ApiService.selectedCurrency,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
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
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Categories Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                            _fetchFlights();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.goldenGradient : null,
                              color: isSelected ? null : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Text(
                              _getCategoryLabel(cat),
                              style: TextStyle(
                                color: isSelected ? Colors.black : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Sort Dropdown and Results Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_flights.length} ${context.tr('packagesAvailable')}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (val) {
                        setState(() => _sortBy = val);
                        _fetchFlights();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _sortBy == 'price' ? context.tr('lowestPrice') : context.tr('topRated'),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'price', child: Text(context.tr('lowestPrice'))),
                        PopupMenuItem(value: 'rating', child: Text(context.tr('topRated'))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),

          // Flight List Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _flights.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('noFlightsFound'),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        itemCount: _flights.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final flight = _flights[index];
                          final isSelectedForCompare = _selectedToCompare.contains(flight.id);

                          return _buildDetailedFlightCard(flight, isSelectedForCompare);
                        },
                      ),
          ),

          // Sticky Compare Float Bar if 2+ selected
          if (_selectedToCompare.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedToCompare.length} ${context.tr('compareFlights')}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final selectedList = _flights.where((f) => _selectedToCompare.contains(f.id)).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompareScreen(flights: selectedList.length >= 2 ? selectedList : _flights),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: Text(context.tr('compareFlights')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedFlightCard(FlightModel flight, bool isSelectedForCompare) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image with Badges & Rating
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
                child: Image.network(
                  flight.coverPhotoUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Badges
              if (flight.badge != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: AppColors.sunriseGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      flight.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),

              // Rating top-right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${flight.operatorRating}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

              // Departure Time banner bottom
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${flight.departureTime} AM (${context.tr('sunrise')})',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flight.packageName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'NileSky Official Fleet',
                            style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Features Row: Duration, Pickup, Breakfast
                Wrap(
                  spacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${flight.durationMinutes} ${context.tr('minutes')}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text(context.tr('pickupIncluded'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                      ],
                    ),
                    if (flight.hasBreakfast)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant, size: 14, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Text(context.tr('breakfastIncluded'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                        ],
                      ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 24),

                // Price, Compare Checkbox and View Details Button
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
                            fontSize: 17,
                          ),
                        ),
                        Text(context.tr('perPerson'), style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5)),
                      ],
                    ),
                    Row(
                      children: [
                        // Compare Checkbox Icon Button
                        IconButton(
                          icon: Icon(
                            isSelectedForCompare ? Icons.check_box : Icons.check_box_outline_blank,
                            color: isSelectedForCompare ? AppColors.primaryDark : AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isSelectedForCompare) {
                                _selectedToCompare.remove(flight.id);
                              } else {
                                _selectedToCompare.add(flight.id);
                              }
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FlightDetailScreen(flight: flight)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(context.tr('viewFlightDetails')),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
