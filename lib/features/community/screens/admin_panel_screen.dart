import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/community_video.dart';
import '../providers/community_provider.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreatorAsync = ref.watch(isCreatorProvider);

    return isCreatorAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, st) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error', style: TextStyle(color: Colors.white))),
      ),
      data: (isCreator) {
        if (!isCreator) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text('Access denied.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.textMuted)),
            ),
          );
        }
        return _buildPanel(context, ref);
      },
    );
  }

  Widget _buildPanel(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingVideosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMIN PANEL',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Pending community videos',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                    onPressed: () => ref.invalidate(pendingVideosProvider),
                  ),
                ],
              ),
            ),
            // Manage Users button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: GestureDetector(
                onTap: () => context.push('/admin/users'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          color: AppColors.accent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'MANAGE USERS',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          color: AppColors.textMuted, size: 14),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: pendingAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $e',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (videos) => videos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✅', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              'All caught up!',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No pending videos.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        itemCount: videos.length,
                        itemBuilder: (context, index) =>
                            _VideoReviewCard(video: videos[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoReviewCard extends ConsumerStatefulWidget {
  final CommunityVideo video;
  const _VideoReviewCard({required this.video});

  @override
  ConsumerState<_VideoReviewCard> createState() => _VideoReviewCardState();
}

class _VideoReviewCardState extends ConsumerState<_VideoReviewCard> {
  bool _processing = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _handleApprove({bool samy = false}) async {
    setState(() => _processing = true);
    try {
      await ref
          .read(pendingVideosProvider.notifier)
          .approve(widget.video.id, samyApproved: samy);
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleReject() async {
    setState(() => _processing = true);
    try {
      await ref.read(pendingVideosProvider.notifier).reject(widget.video.id);
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: username + skill pill + time
                Row(
                  children: [
                    Text(
                      video.username,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        video.skillId,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _timeAgo(video.submittedAt),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (video.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    video.caption,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Video preview — tap to play
                GestureDetector(
                  onTap: () =>
                      context.push('/community-video', extra: video),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_filled_rounded,
                            color: AppColors.accent.withValues(alpha: 0.8),
                            size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap to preview video',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '✅ APPROVE',
                        color: const Color(0xFF166534),
                        onTap: _processing ? null : () => _handleApprove(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: '❌ REJECT',
                        color: const Color(0xFF7F1D1D),
                        onTap: _processing ? null : _handleReject,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: '🔥 SAMY',
                        color: AppColors.accent,
                        onTap: _processing
                            ? null
                            : () => _handleApprove(samy: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_processing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
