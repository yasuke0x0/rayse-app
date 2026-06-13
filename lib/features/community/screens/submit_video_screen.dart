import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/community_provider.dart';

class SubmitVideoScreen extends ConsumerStatefulWidget {
  final String skillId;
  const SubmitVideoScreen({super.key, required this.skillId});

  @override
  ConsumerState<SubmitVideoScreen> createState() => _SubmitVideoScreenState();
}

class _SubmitVideoScreenState extends ConsumerState<SubmitVideoScreen> {
  int _step = 1;
  XFile? _pickedFile;
  String _videoExtension = 'mp4';
  String _caption = '';
  bool _uploading = false;
  bool _submitted = false;

  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _videoExtension = file.path.split('.').last;
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
      );
      await repo.submitVideo(
        userId: userId,
        skillId: widget.skillId,
        videoUrl: videoUrl,
        caption: _caption,
      );
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

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD A CAPTION',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _captionController,
          maxLength: 150,
          maxLines: 4,
          onChanged: (v) => setState(() => _caption = v),
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Describe your technique...',
            hintStyle:
                GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
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
          ),
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
}
