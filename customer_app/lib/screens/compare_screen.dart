import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/flight.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import 'flight_detail_screen.dart';

class CompareScreen extends StatelessWidget {
  final List<FlightModel> flights;

  const CompareScreen({super.key, required this.flights});

  @override
  Widget build(BuildContext context) {
    // Show up to 3 packages for comparison
    final compareList = flights.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('comparePackages'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header description
            Container(
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
                  const Icon(Icons.info_outline, color: AppColors.primaryDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('comparePackagesSub'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Comparison Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DataTable(
                  columnSpacing: 18,
                  horizontalMargin: 16,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: [
                    const DataColumn(
                      label: Text(
                        'Package Tier',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    ...compareList.map(
                      (f) => DataColumn(
                        label: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.packageType.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              f.packageName.length > 15
                                  ? '${f.packageName.substring(0, 14)}...'
                                  : f.packageName,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  rows: [
                    // Price Row
                    DataRow(
                      cells: [
                        DataCell(Text(context.tr('perPerson'), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                        ...compareList.map(
                          (f) => DataCell(
                            Text(
                              ApiService.formatPrice(f.priceEgp),
                              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Duration Row
                    DataRow(
                      cells: [
                        DataCell(Text(context.tr('duration'), style: const TextStyle(color: AppColors.textSecondary))),
                        ...compareList.map((f) => DataCell(Text('${f.durationMinutes} ${context.tr('minutes')}', style: const TextStyle(color: AppColors.textPrimary)))),
                      ],
                    ),

                    // Breakfast Included
                    DataRow(
                      cells: [
                        DataCell(Text(context.tr('breakfast'), style: const TextStyle(color: AppColors.textSecondary))),
                        ...compareList.map(
                          (f) => DataCell(
                            f.hasBreakfast
                                ? const Icon(Icons.check_circle, color: AppColors.success, size: 18)
                                : const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                          ),
                        ),
                      ],
                    ),

                    // Hotel & Nile Pickup
                    DataRow(
                      cells: [
                        DataCell(Text(context.tr('pickup'), style: const TextStyle(color: AppColors.textSecondary))),
                        ...compareList.map(
                          (f) => const DataCell(
                            Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          ),
                        ),
                      ],
                    ),

                    // Basket Capacity
                    DataRow(
                      cells: [
                        const DataCell(Text('Basket Size', style: TextStyle(color: AppColors.textSecondary))),
                        ...compareList.map((f) => DataCell(Text('${f.capacity} guests max', style: const TextStyle(color: AppColors.textPrimary)))),
                      ],
                    ),

                    // Action: Book
                    DataRow(
                      cells: [
                        const DataCell(Text('Action', style: TextStyle(color: AppColors.textSecondary))),
                        ...compareList.map(
                          (f) => DataCell(
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FlightDetailScreen(flight: f)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              child: Text(context.tr('bookNow')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
