import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/tutorial.dart';

class TutorialCard extends StatelessWidget {
  final Tutorial tutorial;

  const TutorialCard({super.key, required this.tutorial});

  Color get _levelColor {
    switch (tutorial.level) {
      case 'beginner':
        return AppColors.levelBeginner;
      case 'intermediate':
        return AppColors.levelIntermediate;
      case 'advanced':
        return AppColors.levelAdvanced;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tutorial/${tutorial.id}'),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail with badges
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: tutorial.thumbnailUrl,
                  width: 200,
                  height: 112,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 200,
                    height: 112,
                    color: const Color(0xFF27272A),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 200,
                    height: 112,
                    color: const Color(0xFF27272A),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // Level badge — top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _levelColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tutorial.level[0].toUpperCase() +
                          tutorial.level.substring(1),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Duration badge — top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${tutorial.durationMinutes}m',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorial.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tutorial.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
