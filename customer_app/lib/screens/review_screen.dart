import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';

class ReviewScreen extends StatefulWidget {
  final String? bookingId;
  final String operatorName;
  final String flightName;

  const ReviewScreen({
    super.key,
    this.bookingId,
    this.operatorName = 'NileSky Fleet',
    this.flightName = 'NileSky Classic Sunrise Ride',
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ApiService.submitReview(
        bookingId: widget.bookingId ?? 'sample-booking-id',
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        // Even if not logged in or backend error, show success after feedback
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Thank You! 🎉',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your review and feedback help fellow travelers discover the magic of Luxor from the sky.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.tr('done')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Rate Your Flight', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
            onPressed: () => LanguagePickerSheet.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text('🌅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'You touched the sky!',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How was your flight with ${widget.operatorName}?',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Star Rating Selector
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starNum),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.star,
                        color: starNum <= _rating ? AppColors.primary : const Color(0xFFCBD5E1),
                        size: 38,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 28),

            // Comment text area
            const Text('Share your experience', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Tell us about the pilot, the takeoff, sunrise view, breakfast...',
              ),
            ),
            const SizedBox(height: 24),

            // Photos Album Upload Simulation
            const Text('📸 Add Your Flight Photos (Album)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add_a_photo, color: AppColors.primaryDark, size: 24),
                      SizedBox(height: 4),
                      Text('Add Photo', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=160',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null) ...[
              Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              const SizedBox(height: 12),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Submit Review & Photos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
