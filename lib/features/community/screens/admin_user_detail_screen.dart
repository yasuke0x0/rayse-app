import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/community_video.dart';
import '../providers/community_provider.dart';
import '../repository/community_video_repository.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  late bool _isPremium;
  late bool _isCreator;
  late bool _isBanned;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isPremium = widget.user['is_premium'] == true;
    _isCreator = widget.user['is_creator'] == true;
    _isBanned = widget.user['is_banned'] == true;
    // Force fresh fetch every time the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(adminUserVideosProvider(_userId));
      ref.invalidate(adminUserXPProvider(_userId));
    });
  }

  String get _userId => widget.user['id'] as String;
  String get _username =>
      widget.user['username'] as String? ?? 'unknown';
  String get _email => widget.user['email'] as String? ?? '';

  String get _currentRole {
    if (_isBanned) return 'BANNED';
    if (_isCreator) return 'ADMIN';
    if (_isPremium) return 'PREMIUM';
    return 'FREE';
  }

  Future<void> _setRole(String role) async {
    setState(() => _saving = true);
    try {
      final notifier = ref.read(allUsersProvider.notifier);
      switch (role) {
        case 'free':
          await notifier.updateRole(_userId,
              isPremium: false, isCreator: false);
          setState(() {
            _isPremium = false;
            _isCreator = false;
          });
        case 'premium':
          await notifier.updateRole(_userId,
              isPremium: true, isCreator: false);
          setState(() {
            _isPremium = true;
            _isCreator = false;
          });
        case 'admin':
          await notifier.updateRole(_userId,
              isPremium: true, isCreator: true);
          setState(() {
            _isPremium = true;
            _isCreator = true;
          });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _toggleBan() async {
    setState(() => _saving = true);
    try {
      final notifier = ref.read(allUsersProvider.notifier);
      if (_isBanned) {
        await notifier.unban(_userId);
        setState(() => _isBanned = false);
      } else {
        await notifier.ban(_userId);
        setState(() => _isBanned = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _approveVideo(String videoId) async {
    await ref
        .read(pendingVideosProvider.notifier)
        .approve(videoId);
    ref.invalidate(adminUserVideosProvider(_userId));
  }

  Future<void> _rejectVideo(String videoId) async {
    await ref.read(pendingVideosProvider.notifier).reject(videoId);
    ref.invalidate(adminUserVideosProvider(_userId));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _revertToPending(String videoId) async {
    await ref
        .read(communityVideoRepositoryProvider)
        .revertToPending(videoId);
    ref.invalidate(adminUserVideosProvider(_userId));
    ref.invalidate(pendingVideosProvider);
    // Refresh community tab
    final now = DateTime.now().toUtc();
    final week = CommunityVideoRepository.isoWeek(now);
    ref.invalidate(approvedVideosProvider((week, now.year)));
    ref.invalidate(topSkillVideosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final xpAsync = ref.watch(adminUserXPProvider(_userId));
    final videosAsync = ref.watch(adminUserVideosProvider(_userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'USER DETAIL',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserCard(),
                    const SizedBox(height: 12),
                    _buildStats(xpAsync),
                    const SizedBox(height: 20),
                    _buildRoleSection(),
                    const SizedBox(height: 20),
                    _buildBanSection(),
                    const SizedBox(height: 24),
                    _buildVideosSection(videosAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isBanned
              ? const Color(0xFFF87171).withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _isBanned
                  ? const Color(0xFF450A0A)
                  : AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isBanned
                    ? const Color(0xFFF87171).withValues(alpha: 0.4)
                    : AppColors.accent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: _isBanned
                  ? const Icon(Icons.block,
                      color: Color(0xFFF87171), size: 22)
                  : Text(
                      _username.isNotEmpty
                          ? _username[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$_username',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_email.isNotEmpty)
                  Text(
                    _email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 6),
                _buildRoleBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    final (label, bg, fg) = switch (_currentRole) {
      'BANNED' => (
          'BANNED',
          const Color(0xFF450A0A),
          const Color(0xFFF87171)
        ),
      'ADMIN' => (
          'ADMIN',
          const Color(0xFF1E3A5F),
          const Color(0xFF60A5FA)
        ),
      'PREMIUM' => ('PREMIUM', const Color(0xFF7C2D12), AppColors.accent),
      _ => ('FREE', const Color(0xFF27272A), AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildStats(AsyncValue<int> xpAsync) {
    final xp = xpAsync.valueOrNull ?? 0;
    return Row(
      children: [
        Expanded(
          child: _statBox(Icons.bolt, '$xp', 'XP'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            Icons.videocam,
            ref
                    .watch(adminUserVideosProvider(_userId))
                    .valueOrNull
                    ?.length
                    .toString() ??
                '—',
            'VIDEOS',
          ),
        ),
      ],
    );
  }

  Widget _statBox(IconData icon, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5)),
          ],
        ),
      );

  Widget _buildRoleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROLE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _roleButton('FREE', 'free', !_isPremium && !_isCreator),
            const SizedBox(width: 8),
            _roleButton('PREMIUM', 'premium', _isPremium && !_isCreator),
            const SizedBox(width: 8),
            _roleButton('ADMIN', 'admin', _isCreator),
          ],
        ),
      ],
    );
  }

  Widget _roleButton(String label, String role, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: _saving ? null : () => _setRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBanSection() {
    return GestureDetector(
      onTap: _saving
          ? null
          : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    _isBanned ? 'Unban @$_username?' : 'Ban @$_username?',
                    style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                  content: Text(
                    _isBanned
                        ? 'This user will regain access to the app.'
                        : 'This user will be blocked from using the app.',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('CANCEL',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        _isBanned ? 'UNBAN' : 'BAN',
                        style: GoogleFonts.inter(
                          color: _isBanned
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFF87171),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) _toggleBan();
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isBanned ? const Color(0xFF14532D) : const Color(0xFF450A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isBanned
                ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                : const Color(0xFFF87171).withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isBanned ? Icons.check_circle_outline : Icons.block,
                color: _isBanned
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFFF87171),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _isBanned ? 'UNBAN USER' : 'BAN USER',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _isBanned
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFF87171),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideosSection(
      AsyncValue<List<CommunityVideo>> videosAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VIDEOS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        videosAsync.when(
          loading: () => const Center(
            child:
                CircularProgressIndicator(color: AppColors.accent),
          ),
          error: (e, st) => Text('Failed to load videos',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textMuted)),
          data: (videos) {
            if (videos.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text('No videos submitted',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted)),
                ),
              );
            }
            return Column(
              children: videos.map((v) => _videoRow(v)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _videoRow(CommunityVideo video) {
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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    video.skillId.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(video.submittedAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
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
              const SizedBox(height: 8),
              Text(
                video.caption,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Personal vs challenge label
            if (!video.isChallenge) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PERSONAL',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            // Challenge video actions
            if (video.isChallenge) ...[
              // Approve/reject buttons for pending challenge videos
              if (video.status == VideoStatus.pending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _approveVideo(video.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14532D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('✅ APPROVE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF4ADE80),
                                  letterSpacing: 0.5,
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _rejectVideo(video.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF450A0A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text('❌ REJECT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF87171),
                                  letterSpacing: 0.5,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              // Fires + revert for approved/rejected challenge videos
              if (video.status == VideoStatus.approved ||
                  video.status == VideoStatus.rejected) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (video.status == VideoStatus.approved) ...[
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '${video.score} fires',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _revertToPending(video.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'REVERT TO PENDING',
                          style: GoogleFonts.inter(
                            fontSize: 10,
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
          ],
        ),
      ),
    );
  }
}
