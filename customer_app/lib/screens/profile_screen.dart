import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/hot_air_balloon_logo.dart';
import 'language_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cloud_outlined, color: AppColors.primaryDark),
              SizedBox(width: 8),
              Text('Backend Server URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure the NileSky backend API endpoint (Render, Localhost, or custom host):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Quick Presets:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('🌐 Live Render', style: TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFFFFFBEB),
                    onPressed: () {
                      setDialogState(() {
                        controller.text = 'https://nile-sky.vercel.app';
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('💻 Localhost', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setDialogState(() {
                        controller.text = 'http://localhost:3000';
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('📱 Android 10.0.2.2', style: TextStyle(fontSize: 11)),
                    onPressed: () {
                      setDialogState(() {
                        controller.text = 'http://10.0.2.2:3000';
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  setState(() {
                    ApiService.setBaseUrl(newUrl);
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API URL set to: ${ApiService.baseUrl}')),
                  );
                }
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final isLoggedIn = ApiService.isLoggedIn;
    final userName = user?['name'] ?? 'John Smith';
    final userEmail = user?['email'] ?? 'john@gmail.com';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
        : 'JS';

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.tr('myProfile'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Avatar & Name Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFFFFBEB),
                    child: Text(
                      isLoggedIn ? userInitials : 'GT',
                      style: const TextStyle(color: AppColors.primaryDark, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLoggedIn ? userName : 'Guest Traveler',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLoggedIn ? userEmail : 'Sign in to sync your bookings',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoggedIn
                              ? (user?['phone'] ?? '📍 Luxor, Egypt')
                              : '📍 Luxor, Egypt',
                          style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoggedIn)
                    ElevatedButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Sign In'),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.error, size: 22),
                      tooltip: 'Sign Out',
                      onPressed: () {
                        setState(() {
                          ApiService.logout();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out of NileSky account.')),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Currency Setting
                  ListTile(
                    leading: const Icon(Icons.currency_exchange, color: AppColors.primaryDark),
                    title: Text(
                      context.tr('displayCurrency'),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    trailing: DropdownButton<String>(
                      value: ApiService.selectedCurrency,
                      dropdownColor: Colors.white,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: 'EGP', child: Text('EGP (ج.م)')),
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                        DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => ApiService.selectedCurrency = val);
                        }
                      },
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),

                  // Language
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.secondary),
                    title: Text(
                      context.tr('appLanguage'),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${LanguageService.currentLanguageName} ${LanguageService.currentFlag}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LanguageScreen(isSettingsMode: true)),
                      );
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1),

                  // Backend API Endpoint Setting
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined, color: AppColors.accent),
                    title: const Text(
                      'Live Backend Server URL',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      ApiService.baseUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryDark),
                    onTap: _showServerSettingsDialog,
                  ),
                  const Divider(color: AppColors.border, height: 1),

                  // Notifications
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                    title: Text(
                      context.tr('pushAlerts'),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      context.tr('pushAlertsSub'),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    value: _pushNotifications,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(color: AppColors.border, height: 1),

                  // Cancellation Policy Info
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.success),
                    title: Text(
                      context.tr('cancellationPolicy'),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(context.tr('policyTitle'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('policyRule1'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(context.tr('policyRule2'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text(context.tr('policyRule3'), style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(context.tr('gotIt'), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // About NileSky
            Center(
              child: Column(
                children: [
                  const HotAirBalloonLogo(size: 26),
                  const SizedBox(height: 8),
                  Text(context.tr('aboutNileSky'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(context.tr('aboutNileSkySub'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  const Text('Version 1.2.0 • Luxor Official Tourism Partner', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
