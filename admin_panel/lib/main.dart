import 'package:flutter/material.dart';
import 'theme/admin_theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin_shell.dart';
import 'services/admin_api_service.dart';

void main() {
  runApp(const NileSkyAdminApp());
}

class NileSkyAdminApp extends StatelessWidget {
  const NileSkyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NileSky Admin — Luxor Operations',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.darkTheme(),
      home: AdminApiService.isLoggedIn ? const AdminShell() : const LoginScreen(),
    );
  }
}
