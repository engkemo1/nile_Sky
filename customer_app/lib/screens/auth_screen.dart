import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/localization_service.dart';
import '../services/api_service.dart';
import '../widgets/hot_air_balloon_logo.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  final _emailController = TextEditingController(text: 'john@gmail.com');
  final _passwordController = TextEditingController(text: 'Admin@123456');
  final _nameController = TextEditingController(text: 'John Smith');
  final _phoneController = TextEditingController(text: '+20 101 234 5678');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      if (_isLogin) {
        await ApiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await ApiService.register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const HotAirBalloonLogo(size: 64, animate: true, showGlow: true),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('appName'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      context.tr('taglineSubtitle'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                    ],
                  ),
                ),
              ],

              // Tab Switcher (Sign In / Create Account)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isLogin
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              context.tr('signIn'),
                              style: TextStyle(
                                color: _isLogin ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isLogin
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              context.tr('createAccount'),
                              style: TextStyle(
                                color: !_isLogin ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form fields
              if (!_isLogin) ...[
                Text(context.tr('fullName'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                    hintText: context.tr('fullName'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(context.tr('whatsappPhone'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                    hintText: context.tr('whatsappPhone'),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(context.tr('emailAddress'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline, color: AppColors.textSecondary),
                  hintText: 'your@email.com',
                ),
              ),
              const SizedBox(height: 16),

              Text(context.tr('password'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary),
                  hintText: '••••••••',
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isLogin ? context.tr('signIn') : context.tr('createAccount')),
                ),
              ),
              const SizedBox(height: 20),

              // Social Logins
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                      label: const Text('Google', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.apple, color: AppColors.textPrimary, size: 22),
                      label: const Text('Apple', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Explore as Guest
              Center(
                child: TextButton(
                  onPressed: _continueAsGuest,
                  child: Text(
                    context.tr('exploreAsGuest'),
                    style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
