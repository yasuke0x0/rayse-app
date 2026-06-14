import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/community_video.dart';
import '../providers/community_provider.dart';
import '../repository/community_video_repository.dart';

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
        body: Center(
            child: Text('Error', style: TextStyle(color: Colors.white))),
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
        return const _AdminPanelBody();
      },
    );
  }
}

class _AdminPanelBody extends ConsumerStatefulWidget {
  const _AdminPanelBody();

  @override
  ConsumerState<_AdminPanelBody> createState() => _AdminPanelBodyState();
}

class _AdminPanelBodyState extends ConsumerState<_AdminPanelBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      'ADMIN PANEL',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: AppColors.textPrimary),
                    onPressed: () {
                      ref.invalidate(pendingVideosProvider);
                      ref.invalidate(adminFilteredVideosProvider);
                    },
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
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.all(3),
                tabs: const [
                  Tab(text: 'PENDING'),
                  Tab(text: 'ALL VIDEOS'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _PendingTab(),
                  _AllVideosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pending tab (existing behavior) ──────────────────────────────────────────

class _PendingTab extends ConsumerWidget {
  const _PendingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingVideosProvider);

    return pendingAsync.when(
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: videos.length,
              itemBuilder: (context, index) =>
                  _PendingCard(video: videos[index]),
            ),
    );
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  final CommunityVideo video;
  const _PendingCard({required this.video});

  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _processing = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _handleApprove() async {
    setState(() => _processing = true);
    try {
      await ref
          .read(pendingVideosProvider.notifier)
          .approve(widget.video.id);
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _handleReject() async {
    setState(() => _processing = true);
    try {
      await ref
          .read(pendingVideosProvider.notifier)
          .reject(widget.video.id);
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }
    if (mounted) setState(() => _processing = false);
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
                    _SkillPill(skillId: video.skillId),
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
                // Video preview
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
                            color:
                                AppColors.accent.withValues(alpha: 0.8),
                            size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to preview video',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '✅ APPROVE',
                        color: const Color(0xFF166534),
                        onTap:
                            _processing ? null : () => _handleApprove(),
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
                  ],
                ),
              ],
            ),
          ),
          if (_processing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── All Videos tab with filters ──────────────────────────────────────────────

class _AllVideosTab extends ConsumerStatefulWidget {
  const _AllVideosTab();

  @override
  ConsumerState<_AllVideosTab> createState() => _AllVideosTabState();
}

class _AllVideosTabState extends ConsumerState<_AllVideosTab> {
  String? _statusFilter; // null = all
  String? _skillFilter; // null = all
  int _weekIndex = 0; // 0 = this week, 1+ = previous weeks
  late final List<({int week, int year})> _weeks;

  @override
  void initState() {
    super.initState();
    _weeks = _buildWeekList();
  }

  List<({int week, int year})> _buildWeekList() {
    final now = DateTime.now().toUtc();
    final currentWeek = CommunityVideoRepository.isoWeek(now);
    // "ALL TIME" + current + last 4 weeks
    return [
      // index 0 = ALL TIME (no week filter)
      (week: 0, year: 0),
      // index 1 = this week
      ...List.generate(5, (i) {
        var week = currentWeek - i;
        var year = now.year;
        if (week <= 0) {
          week += 52;
          year -= 1;
        }
        return (week: week, year: year);
      }),
    ];
  }

  AdminVideoFilter get _currentFilter => (
        status: _statusFilter,
        skillId: _skillFilter,
        weekNumber: _weekIndex == 0 ? null : _weeks[_weekIndex].week,
        weekYear: _weekIndex == 0 ? null : _weeks[_weekIndex].year,
      );

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(adminFilteredVideosProvider(_currentFilter));

    return Column(
      children: [
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _filterChip('ALL', _statusFilter == null,
                  () => setState(() => _statusFilter = null)),
              _filterChip('APPROVED', _statusFilter == 'approved',
                  () => setState(() => _statusFilter = 'approved')),
              _filterChip('REJECTED', _statusFilter == 'rejected',
                  () => setState(() => _statusFilter = 'rejected')),
              _filterChip('PENDING', _statusFilter == 'pending',
                  () => setState(() => _statusFilter = 'pending')),
            ],
          ),
        ),
        // Week filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(_weeks.length, (i) {
              final label =
                  i == 0 ? 'ALL TIME' : i == 1 ? 'THIS WEEK' : 'WK ${_weeks[i].week}';
              return _filterChip(label, _weekIndex == i,
                  () => setState(() => _weekIndex = i));
            }),
          ),
        ),
        // Skill filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              _filterChip('ALL SKILLS', _skillFilter == null,
                  () => setState(() => _skillFilter = null)),
              ..._skillLabels.entries.map((e) => _filterChip(
                    e.value.toUpperCase(),
                    _skillFilter == e.key,
                    () => setState(() => _skillFilter = e.key),
                  )),
            ],
          ),
        ),
        const Divider(color: AppColors.border, height: 1),
        // Stats bar
        videosAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (videos) {
            final approved =
                videos.where((v) => v.status == VideoStatus.approved).length;
            final rejected =
                videos.where((v) => v.status == VideoStatus.rejected).length;
            final pending =
                videos.where((v) => v.status == VideoStatus.pending).length;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${videos.length} total',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _statDot(const Color(0xFF4ADE80), '$approved approved'),
                  const SizedBox(width: 10),
                  _statDot(const Color(0xFFF87171), '$rejected rejected'),
                  const SizedBox(width: 10),
                  _statDot(AppColors.textSecondary, '$pending pending'),
                ],
              ),
            );
          },
        ),
        // Video list
        Expanded(
          child: videosAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
            data: (videos) {
              if (videos.isEmpty) {
                return Center(
                  child: Text(
                    'No videos match these filters',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                itemCount: videos.length,
                itemBuilder: (_, i) => _AllVideoRow(video: videos[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _statDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  static const _skillLabels = {
    'basic_bounce': 'Basic Bounce',
    'forward_jump': 'Forward Jump',
    'backward_jump': 'Backward Jump',
    'alt_steps': 'Alt Steps',
    'double_unders': 'Double Unders',
    'cross_overs': 'Cross Overs',
    'side_swing': 'Side Swing',
    'triple_unders': 'Triple Unders',
    'cross_double': 'Cross Double',
    'releases': 'Releases',
    'freestyle': 'Freestyle',
  };
}

// ─── All Videos row ───────────────────────────────────────────────────────────

class _AllVideoRow extends ConsumerWidget {
  final CommunityVideo video;
  const _AllVideoRow({required this.video});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (statusLabel, statusBg, statusFg) = switch (video.status) {
      VideoStatus.pending => (
          'PENDING',
          const Color(0xFF3F3F46),
          AppColors.textSecondary
        ),
      VideoStatus.approved => (
          'APPROVED',
          const Color(0xFF14532D),
          const Color(0xFF4ADE80)
        ),
      VideoStatus.rejected => (
          'REJECTED',
          const Color(0xFF450A0A),
          const Color(0xFFF87171)
        ),
    };

    return GestureDetector(
      onTap: () => context.push('/community-video', extra: video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: username, skill, status, time
            Row(
              children: [
                Text(
                  '@${video.username}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                _SkillPill(skillId: video.skillId),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: statusFg,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (video.caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                video.caption,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            // Bottom row: submitted time, reviewer info, scores
            Row(
              children: [
                Text(
                  'Submitted ${_timeAgo(video.submittedAt)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
                if (video.reviewedBy != null) ...[
                  Text(' · ',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textMuted)),
                  Text(
                    'by @${video.reviewedBy}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (video.reviewedAt != null) ...[
                    Text(' ${_timeAgo(video.reviewedAt!)}',
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ],
                const Spacer(),
                if (video.status == VideoStatus.approved) ...[
                  const Text('🔥', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    '${video.score}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ],
            ),
            // Actions for non-pending (revert)
            if (video.status != VideoStatus.pending) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await ref
                          .read(communityVideoRepositoryProvider)
                          .revertToPending(video.id);
                      final now = DateTime.now().toUtc();
                      final week = CommunityVideoRepository.isoWeek(now);
                      ref.invalidate(pendingVideosProvider);
                      ref.invalidate(adminFilteredVideosProvider);
                      ref.invalidate(
                          approvedVideosProvider((week, now.year)));
                      ref.invalidate(topSkillVideosProvider);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'REVERT TO PENDING',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SkillPill extends StatelessWidget {
  final String skillId;
  const _SkillPill({required this.skillId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF3F3F46),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        skillId.replaceAll('_', ' '),
        style: GoogleFonts.inter(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
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
