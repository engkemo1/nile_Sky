import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

/// What the operator has actually sent this passenger.
///
/// The API has written these all along — a cancellation notice, a pickup time,
/// a reminder — and the app never once asked for them, so a passenger whose
/// flight was called off found out by opening their bookings.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ApiService.getNotifications();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _open(Map<String, dynamic> n) async {
    if (n['isRead'] != true && n['id'] != null) {
      await ApiService.markNotificationRead(n['id'].toString());
      if (!mounted) return;
      setState(() => n['isRead'] = true);
    }
  }

  String _title(Map<String, dynamic> n) {
    final ar = (n['titleAr'] ?? '').toString().trim();
    final en = (n['titleEn'] ?? '').toString().trim();
    if (LanguageService.isArabic && ar.isNotEmpty) return ar;
    return en.isNotEmpty ? en : ar;
  }

  String _body(Map<String, dynamic> n) {
    final ar = (n['bodyAr'] ?? '').toString().trim();
    final en = (n['bodyEn'] ?? '').toString().trim();
    if (LanguageService.isArabic && ar.isNotEmpty) return ar;
    return en.isNotEmpty ? en : ar;
  }

  IconData _icon(String type) {
    switch (type) {
      case 'weather':
        return Icons.air;
      case 'pickup':
        return Icons.directions_car;
      case 'flight_update':
        return Icons.flight;
      case 'booking_confirm':
        return Icons.check_circle_outline;
      case 'review_request':
        return Icons.star_outline;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_none;
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
          context.tr('notifications'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _items.isEmpty
                ? ListView(
                    // A ListView so pull-to-refresh still works when empty.
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notifications_none,
                                    size: 40, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  context.tr('noNotifications'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final n = _items[i];
                      final unread = n['isRead'] != true;
                      return InkWell(
                        onTap: () => _open(n),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: unread
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _icon((n['type'] ?? '').toString()),
                                size: 20,
                                color: unread
                                    ? AppColors.primaryDark
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _title(n),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: unread
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _body(n),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12.5,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (unread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4, left: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
