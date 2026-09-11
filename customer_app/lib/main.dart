import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/localization_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NileSkyCustomerApp());
}

class NileSkyCustomerApp extends StatelessWidget {
  const NileSkyCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.localeNotifier,
      builder: (context, currentLocale, _) {
        final isArabic = currentLocale.languageCode == 'ar';
        return MaterialApp(
          title: 'NileSky — Luxor Balloon Flights',
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          supportedLocales: LanguageService.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.darkTheme(isArabic: isArabic),
          home: const SplashScreen(),
        );
      },
    );
  }
}
