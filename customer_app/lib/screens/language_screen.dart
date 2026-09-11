import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/localization_service.dart';
import 'auth_screen.dart';

class LanguageScreen extends StatefulWidget {
  final bool isSettingsMode;

  const LanguageScreen({super.key, this.isSettingsMode = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  Widget build(BuildContext context) {
    final currentCode = LanguageService.currentLanguageCode;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: widget.isSettingsMode
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                context.tr('appLanguage'),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isSettingsMode) ...[
                const SizedBox(height: 20),
                const Center(
                  child: Text('🌐', style: TextStyle(fontSize: 56)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    context.tr('chooseLanguage'),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    context.tr('chooseLanguageSub'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Language options list
              Expanded(
                child: ListView.separated(
                  itemCount: LanguageService.supportedLanguages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lang = LanguageService.supportedLanguages[index];
                    final isSelected = currentCode == lang['code'];

                    return GestureDetector(
                      onTap: () {
                        LanguageService.setLanguage(lang['code']!);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFFBEB) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['native']!,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    lang['name']!,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 16, color: Colors.black),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue / Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.isSettingsMode) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    }
                  },
                  child: Text(widget.isSettingsMode ? context.tr('done') : context.tr('continueBtn')),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
