import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/admin_theme.dart';
import 'theme/admin_colors.dart';
import 'screens/login_screen.dart';
import 'screens/admin_shell.dart';
import 'services/admin_api_service.dart';
import 'services/admin_language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdminLanguageService.init();
  runApp(const NileSkyAdminApp());
}

class NileSkyAdminApp extends StatelessWidget {
  const NileSkyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AdminLanguageService.localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'نايل سكاي - لوحة الإدارة',
          debugShowCheckedModeBanner: false,
          theme: AdminTheme.darkTheme(),
          locale: locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, widget) {
            return Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: widget ?? const SizedBox(),
            );
          },
          home: const _SessionGate(),
        );
      },
    );
  }
}

/// Checks for a saved session before deciding which screen to show, so a page
/// refresh no longer dumps the admin back at the login form.
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool _checking = true;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final ok = await AdminApiService.restoreSession();
    if (!mounted) return;
    setState(() {
      _signedIn = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return Scaffold(
        backgroundColor: AdminColors.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AdminColors.primary),
              const SizedBox(height: 16),
              Text(
                AdminLanguageService.isArabic
                    ? 'جارٍ استعادة الجلسة…'
                    : 'Restoring your session…',
                style: const TextStyle(color: AdminColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return _signedIn ? const AdminShell() : const LoginScreen();
  }
}
