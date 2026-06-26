import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/repository/community_video_repository.dart';
import '../../skill_tree/data/skill_tree_data.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../utils/tier_utils.dart';

class AdminChallengesScreen extends ConsumerWidget {
  const AdminChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(adminChallengesProvider);

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
                      'MANAGE CHALLENGES',
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
                    onPressed: () => ref.invalidate(adminChallengesProvider),
                  ),
                ],
              ),
            ),
            // Create button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: GestureDetector(
                onTap: () => context.push('/admin/challenges/new'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'CREATE NEW CHALLENGE',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            // List
            Expanded(
              child: challengesAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted)),
                ),
                data: (challenges) {
                  if (challenges.isEmpty) {
                    return Center(
                      child: Text('No challenges yet',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textMuted)),
                    );
                  }
                  final active =
                      challenges.where((c) => c.isCurrentWeek).toList();
                  final upcoming = challenges
                      .where((c) => c.isUpcoming)
                      .toList()
                    ..sort((a, b) {
                      final y = a.weekYear.compareTo(b.weekYear);
                      return y != 0
                          ? y
                          : a.weekNumber.compareTo(b.weekNumber);
                    });
                  final past = challenges.where((c) => c.isPast).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      if (active.isNotEmpty) ...[
                        _sectionLabel('THIS WEEK'),
                        ...active.map((c) => _ChallengeRow(challenge: c)),
                        const SizedBox(height: 20),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _sectionLabel('UPCOMING'),
                        ...upcoming.map((c) => _ChallengeRow(challenge: c)),
                        const SizedBox(height: 20),
                      ],
                      if (past.isNotEmpty) ...[
                        _sectionLabel('PAST'),
                        ...past.map((c) => _ChallengeRow(challenge: c)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
      );
}

class _ChallengeRow extends ConsumerWidget {
  final Challenge challenge;
  const _ChallengeRow({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = tierForSkill(challenge.skillId);
    final tierLabel = tierLabels[tier]!;
    final skillNode = kSkillTree
        .where((n) => n.id == challenge.skillId)
        .firstOrNull;
    final skillTitle = skillNode?.title ?? challenge.skillId;

    return GestureDetector(
      onTap: () => context.push('/admin/challenges/edit', extra: challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'WK ${challenge.weekNumber} ${challenge.weekYear} · $skillTitle · $tierLabel',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF7C2D12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${challenge.xpReward} XP',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Create / edit form ──────────────────────────────────────────────────────

class ChallengeFormScreen extends ConsumerStatefulWidget {
  final Challenge? existing;
  const ChallengeFormScreen({super.key, this.existing});

  @override
  ConsumerState<ChallengeFormScreen> createState() =>
      _ChallengeFormScreenState();
}

class _ChallengeFormScreenState extends ConsumerState<ChallengeFormScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _weekController;
  late TextEditingController _yearController;
  late TextEditingController _xpController;
  String? _skillId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now().toUtc();
    final currentWeek = CommunityVideoRepository.isoWeek(now);

    _titleController =
        TextEditingController(text: existing?.title ?? '');
    _descController =
        TextEditingController(text: existing?.description ?? '');
    _weekController = TextEditingController(
        text: (existing?.weekNumber ?? currentWeek + 1).toString());
    _yearController = TextEditingController(
        text: (existing?.weekYear ?? now.year).toString());
    _xpController =
        TextEditingController(text: (existing?.xpReward ?? 100).toString());
    _skillId = existing?.skillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _weekController.dispose();
    _yearController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final week = int.tryParse(_weekController.text);
    final year = int.tryParse(_yearController.text);
    final xp = int.tryParse(_xpController.text);
    final skillId = _skillId;

    if (skillId == null ||
        title.isEmpty ||
        desc.isEmpty ||
        week == null ||
        year == null ||
        xp == null) {
      _showSnack('Please fill in all fields.', isError: true);
      return;
    }
    if (week < 1 || week > 53) {
      _showSnack('Week must be 1-53.', isError: true);
      return;
    }

    // Tier uniqueness check: one challenge per tier per week
    final chosenTier = tierForSkill(skillId);
    final existing = ref.read(adminChallengesProvider).valueOrNull ?? [];
    final conflict = existing.firstWhere(
      (c) =>
          c.weekNumber == week &&
          c.weekYear == year &&
          tierForSkill(c.skillId) == chosenTier &&
          (widget.existing == null || c.id != widget.existing!.id),
      orElse: () => Challenge(
        id: '',
        skillId: '',
        title: '',
        description: '',
        weekNumber: 0,
        weekYear: 0,
        xpReward: 0,
      ),
    );
    if (conflict.id.isNotEmpty) {
      _showSnack(
        'A ${tierLabels[chosenTier]} challenge already exists for week $week ("${conflict.title}"). Edit it or pick a different tier/week.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(challengeRepositoryProvider);
      if (widget.existing == null) {
        await repo.createChallenge(
          skillId: skillId,
          title: title,
          description: desc,
          weekNumber: week,
          weekYear: year,
          xpReward: xp,
        );
      } else {
        await repo.updateChallenge(
          id: widget.existing!.id,
          skillId: skillId,
          title: title,
          description: desc,
          weekNumber: week,
          weekYear: year,
          xpReward: xp,
        );
      }
      ref.invalidate(adminChallengesProvider);
      ref.invalidate(challengesProvider);
      if (mounted) {
        _showSnack(widget.existing == null
            ? 'Challenge created'
            : 'Challenge updated');
        context.pop();
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('23505')) {
        _showSnack('A challenge for this skill + week already exists.',
            isError: true);
      } else {
        _showSnack('Save failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete challenge?',
            style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        content: Text(
          'This will permanently delete "${existing.title}". Submitted videos for this skill+week are unaffected.',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('DELETE',
                style: GoogleFonts.inter(
                    color: const Color(0xFFF87171),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(challengeRepositoryProvider)
          .deleteChallenge(existing.id);
      ref.invalidate(adminChallengesProvider);
      ref.invalidate(challengesProvider);
      if (mounted) {
        _showSnack('Challenge deleted');
        context.pop();
      }
    } catch (e) {
      _showSnack('Delete failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  Text(
                    isEdit ? 'EDIT CHALLENGE' : 'NEW CHALLENGE',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skill picker
                    _label('SKILL'),
                    const SizedBox(height: 6),
                    _SkillPicker(
                      selectedSkillId: _skillId,
                      onSelected: (id) => setState(() => _skillId = id),
                    ),
                    const SizedBox(height: 20),

                    _label('TITLE'),
                    const SizedBox(height: 6),
                    _field(_titleController, 'e.g. Double Under Showdown',
                        maxLength: 60),
                    const SizedBox(height: 20),

                    _label('DESCRIPTION'),
                    const SizedBox(height: 6),
                    _field(_descController,
                        'Briefly describe the challenge',
                        maxLines: 3, maxLength: 240),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('WEEK'),
                              const SizedBox(height: 6),
                              _field(_weekController, '26',
                                  numeric: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('YEAR'),
                              const SizedBox(height: 6),
                              _field(_yearController, '2026',
                                  numeric: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('XP'),
                              const SizedBox(height: 6),
                              _field(_xpController, '100',
                                  numeric: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.5),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEdit ? 'SAVE CHANGES' : 'CREATE CHALLENGE',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                      ),
                    ),

                    // Delete
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saving ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFF87171)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'DELETE CHALLENGE',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF87171),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1,
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    int? maxLength,
    bool numeric = false,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: false)
            : TextInputType.text,
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      );
}

class _SkillPicker extends StatelessWidget {
  final String? selectedSkillId;
  final ValueChanged<String> onSelected;

  const _SkillPicker({
    required this.selectedSkillId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...kSkillTree]..sort((a, b) => a.tier.compareTo(b.tier));

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: sorted.map((skill) {
          final selected = skill.id == selectedSkillId;
          final tier = tierForSkill(skill.id);
          final tierLabel = tierLabels[tier]!;
          return GestureDetector(
            onTap: () => onSelected(skill.id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textMuted,
                        width: 2,
                      ),
                      color: selected
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      skill.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      tierLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
