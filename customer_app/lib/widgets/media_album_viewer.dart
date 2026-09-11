import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MediaAlbumViewer extends StatefulWidget {
  final List<String> photos;
  final String? videoUrl;
  final String title;

  const MediaAlbumViewer({
    super.key,
    required this.photos,
    this.videoUrl,
    required this.title,
  });

  @override
  State<MediaAlbumViewer> createState() => _MediaAlbumViewerState();
}

class _MediaAlbumViewerState extends State<MediaAlbumViewer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Hero Image with PageView & Video Play Button
        Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surfaceDark,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: PageView.builder(
                  itemCount: widget.photos.length,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemBuilder: (context, index) {
                    return Image.network(
                      widget.photos[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceDark,
                        child: const Center(
                          child: Icon(Icons.flight_takeoff, size: 48, color: AppColors.primary),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Video Play Overlay Badge (if video is available)
            if (widget.videoUrl != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Row(
                          children: [
                            const Icon(Icons.videocam, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Flight Experience Video',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.network(
                                    widget.photos.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: AppColors.primary,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Watch real footage captured over Luxor Valley of Kings and temples at sunrise.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.play_circle_fill, color: AppColors.primary, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Watch Video',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Photo Count Badge (e.g. 1/4)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentIndex + 1}/${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Thumbnail strip (if multiple photos)
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.photos[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
