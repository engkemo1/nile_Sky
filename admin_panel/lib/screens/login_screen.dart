import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../services/admin_api_service.dart';
import 'admin_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AdminApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check that user is admin or operator_admin
      final user = AdminApiService.currentUser;
      if (user != null && (user['role'] == 'platform_admin' || user['role'] == 'operator_admin')) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminShell()),
          );
        }
      } else {
        AdminApiService.logout();
        setState(() {
          _errorMessage = 'Access denied. Admin or Operator role required.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Check backend URL & network.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bgDark,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AdminColors.primary, AdminColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AdminColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🎈', style: TextStyle(fontSize: 34)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'NileSky Admin',
                    style: TextStyle(
                      color: AdminColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Luxor Operations Control Center',
                    style: TextStyle(color: AdminColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 36),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AdminColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sign In', style: TextStyle(color: AdminColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Enter your admin credentials', style: TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 24),

                        // Error
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AdminColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AdminColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AdminColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AdminColors.error, fontSize: 12))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        const Text('Email', style: TextStyle(color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: AdminColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'admin@nilesky.com',
                            hintStyle: const TextStyle(color: AdminColors.textMuted),
                            prefixIcon: const Icon(Icons.mail_outline, color: AdminColors.textMuted, size: 18),
                            filled: true,
                            fillColor: AdminColors.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password
                        const Text('Password', style: TextStyle(color: AdminColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AdminColors.textPrimary, fontSize: 14),
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            hintStyle: const TextStyle(color: AdminColors.textMuted),
                            prefixIcon: const Icon(Icons.lock_outline, color: AdminColors.textMuted, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AdminColors.textMuted,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: AdminColors.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Backend URL indicator (clickable to configure)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      final urlCtrl = TextEditingController(text: AdminApiService.baseUrl);
                      showDialog(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: AdminColors.cardDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Configure Backend URL', style: TextStyle(color: AdminColors.textPrimary, fontSize: 16)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Set the NileSky NestJS backend API endpoint:', style: TextStyle(color: AdminColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: urlCtrl,
                                style: const TextStyle(color: AdminColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'API Base URL',
                                  labelStyle: const TextStyle(color: AdminColors.textMuted),
                                  filled: true,
                                  fillColor: AdminColors.surfaceDark,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('🌐 Live Render', style: TextStyle(color: AdminColors.primary, fontSize: 11)),
                                    backgroundColor: AdminColors.surfaceDark,
                                    onPressed: () => urlCtrl.text = 'https://nile-sky.vercel.app',
                                  ),
                                  ActionChip(
                                    label: const Text('💻 Localhost', style: TextStyle(color: AdminColors.textSecondary, fontSize: 11)),
                                    backgroundColor: AdminColors.surfaceDark,
                                    onPressed: () => urlCtrl.text = 'http://localhost:3000',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('Cancel', style: TextStyle(color: AdminColors.textMuted)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final u = urlCtrl.text.trim();
                                if (u.isNotEmpty) {
                                  setState(() => AdminApiService.setBaseUrl(u));
                                  Navigator.pop(dCtx);
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.black),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AdminColors.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AdminColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Backend: ${AdminApiService.baseUrl}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AdminColors.textMuted, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_outlined, size: 12, color: AdminColors.textMuted),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
