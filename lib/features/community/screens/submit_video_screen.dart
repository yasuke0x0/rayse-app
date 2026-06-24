import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../challenges/utils/tier_utils.dart';
import '../../skill_tree/models/skill.dart';
import '../../skill_tree/providers/skill_provider.dart';
import '../providers/community_provider.dart';

class SubmitVideoScreen extends ConsumerStatefulWidget {
  final String skillId;
  final bool isChallenge;
  const SubmitVideoScreen({
    super.key,
    required this.skillId,
    this.isChallenge = false,
  });

  @override
  ConsumerState<SubmitVideoScreen> createState() => _SubmitVideoScreenState();
}

class _SubmitVideoScreenState extends ConsumerState<SubmitVideoScreen> {
  int _step = 1;
  XFile? _pickedFile;
  String _videoExtension = 'mp4';
  String _mimeType = 'video/mp4';
  String _title = '';
  String _caption = '';
  String _notes = '';
  bool _uploading = false;
  bool _submitted = false;

  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file != null) {
      // On web, file.path is a blob URL — use file.name for the real extension
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'mp4';
      setState(() {
        _pickedFile = file;
        _videoExtension = ext;
        _mimeType = file.mimeType ?? 'video/mp4';
      });
    }
  }

  Future<void> _submitVideo() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to submit.')),
        );
      }
      return;
    }
    if (_pickedFile == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await _pickedFile!.readAsBytes();
      final repo = ref.read(communityVideoRepositoryProvider);
      final videoUrl = await repo.uploadVideo(
        userId: userId,
        skillId: widget.skillId,
        bytes: bytes,
        extension: _videoExtension,
        mimeType: _mimeType,
      );
      if (widget.isChallenge) {
        await repo.submitVideo(
          userId: userId,
          skillId: widget.skillId,
          videoUrl: videoUrl,
          caption: _caption,
        );
      } else {
        await repo.submitPersonalVideo(
          userId: userId,
          skillId: widget.skillId,
          videoUrl: videoUrl,
          title: _title,
          caption: _caption,
          notes: _notes,
        );
      }
      // Refresh video lists so skill node + profile show the new submission
      ref.invalidate(mySkillVideosProvider);
      ref.invalidate(myAllVideosProvider);
      ref.invalidate(myTotalSubmissionsProvider);
      ref.invalidate(pendingVideosProvider);
      ref.invalidate(hasSubmittedChallengeProvider);
      ref.invalidate(challengeParticipantCountProvider);
      setState(() {
        _submitted = true;
        _uploading = false;
      });
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  String get _skillDisplayName =>
      widget.skillId.replaceAll('_', ' ').toUpperCase();

  String get _fileName => _pickedFile?.path.split('/').last ?? '';

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i + 1 == _step;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : const Color(0xFF3F3F46),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PICK YOUR VIDEO',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Max 60 seconds · show your best technique',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _pickVideo,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF52525B),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _pickedFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_camera_back_outlined,
                          color: Color(0xFF71717A), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'TAP TO SELECT FROM GALLERY',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF71717A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF22C55E), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _fileName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _pickedFile == null
                ? null
                : () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: const Color(0xFF3F3F46),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'NEXT →',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      );

  Widget _buildStep2() {
    final isPersonal = !widget.isChallenge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isPersonal ? 'ADD DETAILS' : 'ADD A CAPTION',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),

        // Title (personal videos only)
        if (isPersonal) ...[
          Text(
            'TITLE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            maxLength: 60,
            onChanged: (v) => setState(() => _title = v),
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: _inputDecoration('e.g. "First clean Double Under"'),
          ),
          const SizedBox(height: 16),
          Text(
            'NOTES',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLength: 500,
            maxLines: 4,
            onChanged: (v) => setState(() => _notes = v),
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration:
                _inputDecoration('Progress notes, what you worked on...'),
          ),
          const SizedBox(height: 8),
        ],

        // Caption (always shown)
        if (!isPersonal) ...[
          TextField(
            controller: _captionController,
            maxLength: 150,
            maxLines: 4,
            onChanged: (v) => setState(() => _caption = v),
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: _inputDecoration('Describe your technique...'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_caption.length} / 150',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],

        const SizedBox(height: 24),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 3),
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = 3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'NEXT →',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'READY TO SUBMIT?',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Column(
            children: [
              _infoRow('Skill', _skillDisplayName),
              const SizedBox(height: 12),
              _infoRow(
                'Caption',
                _caption.isEmpty ? 'No caption' : _caption,
                valueMuted: _caption.isEmpty,
              ),
              const SizedBox(height: 12),
              _infoRow('Video', _fileName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '⏳ Your video will be reviewed before going live',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _uploading ? null : _submitVideo,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'SUBMIT VIDEO',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool valueMuted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: valueMuted ? AppColors.textMuted : AppColors.textPrimary,
              fontWeight: valueMuted ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text(
            'VIDEO SUBMITTED!',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "We'll review it and let you know when it's live.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'BACK TO SKILL',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isChallenge) {
      final skills = ref.watch(skillsProvider);
      final skill =
          skills.where((s) => s.id == widget.skillId).firstOrNull;
      final challengeTier = tierForSkill(widget.skillId);
      final myTier = highestMasteredTier(skills);
      final isWrongTier = challengeTier != myTier;

      if (isWrongTier) {
        return _buildBlocker(
          icon: Icons.workspace_premium_outlined,
          title: 'RESERVED FOR ${tierLabels[challengeTier]}',
          message:
              'You can spectate this challenge, but submissions are limited to your tier (${tierLabels[myTier]}). Look for a ${tierLabels[myTier]} challenge to enter.',
          primaryLabel: 'BACK TO CHALLENGES',
          onPrimaryTap: () => context.pop(),
        );
      }

      if (skill == null || skill.status != SkillStatus.mastered) {
        return _buildBlocker(
          icon: Icons.lock_outline_rounded,
          title: 'MASTER THIS SKILL FIRST',
          message:
              'Complete 3 practice sessions for ${widget.skillId.replaceAll('_', ' ')} to unlock challenge submissions.',
          primaryLabel: 'GO TO SKILL',
          onPrimaryTap: () {
            context.pop();
            context.push('/skill-detail/${widget.skillId}');
          },
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _submitted
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: _buildSuccess(),
              )
            : Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.textPrimary),
                          onPressed: () {
                            if (_step > 1) {
                              setState(() => _step--);
                            } else {
                              context.pop();
                            }
                          },
                        ),
                        const Spacer(),
                        _buildProgressDots(),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: _step == 1
                          ? _buildStep1()
                          : _step == 2
                              ? _buildStep2()
                              : _buildStep3(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBlocker({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback onPrimaryTap,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPrimaryTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    primaryLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'BACK',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
