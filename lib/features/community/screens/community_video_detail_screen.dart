import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../models/community_video.dart';
import '../providers/community_provider.dart';
import '../widgets/comments_section_widget.dart';

class CommunityVideoDetailScreen extends ConsumerStatefulWidget {
  final CommunityVideo video;

  const CommunityVideoDetailScreen({super.key, required this.video});

  @override
  ConsumerState<CommunityVideoDetailScreen> createState() =>
      _CommunityVideoDetailScreenState();
}

class _CommunityVideoDetailScreenState
    extends ConsumerState<CommunityVideoDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  late int _localScore;

  @override
  void initState() {
    super.initState();
    _localScore = widget.video.score;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo());
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    );
    _videoController = controller;
    await controller.initialize();
    if (!mounted) return;
    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      placeholder: Container(color: AppColors.surface),
    );
    setState(() => _videoInitialized = true);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  bool get _isOwner =>
      Supabase.instance.client.auth.currentUser?.id == widget.video.userId;

  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: widget.video.title);
    final notesCtrl = TextEditingController(text: widget.video.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'EDIT VIDEO',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TITLE',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: titleCtrl,
              maxLength: 60,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('NOTES',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: notesCtrl,
              maxLength: 500,
              maxLines: 4,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(communityVideoRepositoryProvider)
                  .updateVideoDetails(
                    widget.video.id,
                    title: titleCtrl.text,
                    notes: notesCtrl.text,
                  );
              ref.invalidate(mySkillVideosProvider);
              ref.invalidate(myAllVideosProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Video updated',
                        style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.pop();
              }
            },
            child: Text('SAVE',
                style: GoogleFonts.inter(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final myReactions = ref.watch(myReactionsProvider).valueOrNull ?? {};
    final hasReacted = myReactions.contains(video.id);
    final weekKey = (video.weekNumber, video.weekYear);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Video player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _videoInitialized && _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : Container(
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info section
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal video: title + edit button
                    if (!video.isChallenge) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              video.title.isNotEmpty
                                  ? video.title
                                  : _skillLabel(video.skillId),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_isOwner)
                            GestureDetector(
                              onTap: () => _showEditDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: AppColors.border),
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: AppColors.textSecondary,
                                    size: 16),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _skillLabel(video.skillId),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                      if (video.notes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOTES',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                video.notes,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    // Challenge video: username + skill + caption
                    if (video.isChallenge) ...[
                      Row(
                        children: [
                          Text(
                            '@${video.username}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('·',
                              style: GoogleFonts.inter(
                                  color: AppColors.textMuted)),
                          const SizedBox(width: 8),
                          Text(
                            _skillLabel(video.skillId),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      if (video.caption.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          video.caption,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],

                    // Reactions + comments (challenge videos only)
                    if (video.isChallenge) ...[
                      const SizedBox(height: 24),

                      // Reactions row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_localScore',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  color: hasReacted
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'fires',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              final adding =
                                  !myReactions.contains(video.id);
                              setState(() {
                                _localScore += adding ? 1 : -1;
                                if (_localScore < 0) _localScore = 0;
                              });
                              ref
                                  .read(myReactionsProvider.notifier)
                                  .toggle(video.id, weekKey);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              decoration: BoxDecoration(
                                color: hasReacted
                                    ? AppColors.accent
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: hasReacted
                                      ? AppColors.accent
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text(
                                    hasReacted ? 'FIRED!' : 'FIRE IT',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: hasReacted
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Comments section
                      CommentsSectionWidget(videoId: video.id),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _skillLabels = {
    'basic_bounce': 'Basic Bounce',
    'forward_jump': 'Forward Jump',
    'backward_jump': 'Backward Jump',
    'alt_steps': 'Alternating Steps',
    'double_unders': 'Double Unders',
    'cross_overs': 'Cross Overs',
    'side_swing': 'Side Swing',
    'triple_unders': 'Triple Unders',
    'cross_double': 'Cross Double',
    'releases': 'Releases',
    'freestyle': 'Freestyle',
  };

  String _skillLabel(String id) => _skillLabels[id] ?? id;
}
