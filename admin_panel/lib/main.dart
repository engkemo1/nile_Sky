import 'package:flutter/material.dart';
import 'theme/admin_theme.dart';
import 'theme/admin_colors.dart';
import 'screens/login_screen.dart';
import 'screens/admin_shell.dart';
import 'services/admin_api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const _SessionGate(),
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
      return const Scaffold(
        backgroundColor: AdminColors.bgDark,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AdminColors.primary),
              SizedBox(height: 16),
              Text(
                'Restoring your session…',
                style: TextStyle(color: AdminColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return _signedIn ? const AdminShell() : const LoginScreen();
  }
}
