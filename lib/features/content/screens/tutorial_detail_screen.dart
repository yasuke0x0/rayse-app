import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/content_provider.dart';
import '../widgets/tutorial_card.dart';

class TutorialDetailScreen extends ConsumerStatefulWidget {
  final String id;

  const TutorialDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TutorialDetailScreen> createState() =>
      _TutorialDetailScreenState();
}

class _TutorialDetailScreenState
    extends ConsumerState<TutorialDetailScreen> {
  YoutubePlayerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Color _levelColor(String level) {
    switch (level) {
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
    final tutorialAsync = ref.watch(tutorialByIdProvider(widget.id));
    final allTutorialsAsync = ref.watch(tutorialsProvider);

    return tutorialAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2),
        ),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Failed to load tutorial.',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ),
      ),
      data: (tutorial) {
        if (tutorial == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Tutorial not found.',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
          );
        }

        _controller ??= YoutubePlayerController(
          initialVideoId: tutorial.youtubeId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: false,
          ),
        );

        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.accent,
            progressColors: const ProgressBarColors(
              playedColor: AppColors.accent,
              handleColor: AppColors.accent,
              bufferedColor: Color(0x4DF97316),
              backgroundColor: Color(0x1AFFFFFF),
            ),
          ),
          builder: (context, player) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Column(
                children: [
                  // Video + back button overlay
                  Stack(
                    children: [
                      player,
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Scrollable content below video
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges row
                          Row(
                            children: [
                              _LevelBadge(
                                label: tutorial.level[0].toUpperCase() +
                                    tutorial.level.substring(1),
                                color: _levelColor(tutorial.level),
                              ),
                              const SizedBox(width: 8),
                              _Pill(
                                label: tutorial.category.toUpperCase(),
                                color: AppColors.surface,
                                textColor: AppColors.textSecondary,
                                border: true,
                              ),
                              const SizedBox(width: 8),
                              if (tutorial.isFree)
                                const _Pill(
                                  label: 'FREE',
                                  color: AppColors.surface,
                                  textColor: AppColors.accent,
                                  border: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            tutorial.title,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Duration
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${tutorial.durationMinutes} minutes',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Description
                          Text(
                            tutorial.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 36),

                          // More like this
                          Text(
                            'MORE LIKE THIS',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          allTutorialsAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (all) {
                              final related = all
                                  .where((t) =>
                                      t.category == tutorial.category &&
                                      t.id != tutorial.id)
                                  .take(3)
                                  .toList();
                              if (related.isEmpty) return const SizedBox.shrink();
                              return SizedBox(
                                height: 228,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: related.length,
                                  itemBuilder: (context, i) => Padding(
                                    padding: EdgeInsets.only(
                                        right: i < related.length - 1 ? 12 : 0),
                                    child: TutorialCard(tutorial: related[i]),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _LevelBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool border;

  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: border ? Border.all(color: AppColors.border) : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

