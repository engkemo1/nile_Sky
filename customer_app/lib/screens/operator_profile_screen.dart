import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/operator.dart';
import '../services/localization_service.dart';
import '../widgets/media_album_viewer.dart';

class OperatorProfileScreen extends StatelessWidget {
  final OperatorModel operator;

  const OperatorProfileScreen({super.key, required this.operator});

  @override
  Widget build(BuildContext context) {
    final opName = LanguageService.isArabic ? operator.nameAr : operator.nameEn;
    final opDesc = LanguageService.isArabic ? operator.descriptionAr : operator.descriptionEn;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: CustomScrollView(
        slivers: [
          // Collapsible AppBar with Banner
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bgDark,
            actions: [
              IconButton(
                icon: Text(LanguageService.currentFlag, style: const TextStyle(fontSize: 18)),
                onPressed: () => LanguagePickerSheet.show(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    operator.coverPhotoUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Operator Details Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + Name + Verified Badge
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          operator.logoUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.surfaceDark,
                            child: const Icon(Icons.flight, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    opName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: AppColors.secondary, size: 16),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              operator.nameAr,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppColors.primary, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${operator.rating} (${operator.totalReviews} ${context.tr('reviews')})',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('${operator.totalFlights}+', context.tr('flights')),
                        _buildDivider(),
                        _buildStatItem('8', 'Fleet'),
                        _buildDivider(),
                        _buildStatItem('10', 'Pilots'),
                        _buildDivider(),
                        _buildStatItem('${operator.rating}', 'Rating ⭐'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // About Section
                  Text(
                    'About Operator',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opDesc,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 22),

                  // Fleet Photos & Video Album
                  Text(
                    '📸 Fleet Photos & Video Album',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 12),
                  MediaAlbumViewer(
                    photos: operator.photos,
                    videoUrl: operator.videoUrl,
                    title: opName,
                  ),
                  const SizedBox(height: 22),

                  // Contact / Location info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                operator.address,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              operator.phone,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Passenger Reviews
                  Text(
                    '⭐ Passenger Reviews (${operator.totalReviews})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 12),

                  _buildReviewCard(
                    author: 'John S. (United Kingdom)',
                    date: 'August 2026',
                    rating: 5,
                    comment: 'Breathtaking experience! Hotel pickup was prompt at 03:45 AM, Nile boat crossing was magical, and the sunrise flight over the Valley of the Kings exceeded all expectations.',
                  ),
                  const SizedBox(height: 10),
                  _buildReviewCard(
                    author: 'Maria L. (Germany)',
                    date: 'July 2026',
                    rating: 5,
                    comment: 'Capt. Ahmed was very professional and smooth landing. Breakfast upon landing was delicious. NileSky made booking seamless!',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 22, width: 1, color: AppColors.border);
  }

  Widget _buildReviewCard({
    required String author,
    required String date,
    required int rating,
    required String comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  rating,
                  (_) => const Icon(Icons.star, color: AppColors.primary, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(date, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35)),
        ],
      ),
    );
  }
}
