import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String? _selectedLevel;
  String? _selectedGoal;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _LevelPage(
                    selected: _selectedLevel,
                    onSelect: (v) => setState(() => _selectedLevel = v),
                    onNext: _nextPage,
                  ),
                  _GoalPage(
                    selected: _selectedGoal,
                    onSelect: (v) => setState(() => _selectedGoal = v),
                    onNext: _nextPage,
                  ),
                  _ChallengePage(
                    onStart: () => context.go('/home'),
                  ),
                ],
              ),
            ),
            _DotIndicator(currentPage: _currentPage, totalPages: 3),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _LevelPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  const _LevelPage({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      heading: "WHAT'S YOUR\nLEVEL?",
      subtext: "Choose where you start. No judgment.",
      options: const ['Beginner', 'Intermediate', 'Advanced'],
      selected: selected,
      onSelect: onSelect,
      buttonLabel: 'NEXT',
      onButton: onNext,
    );
  }
}

class _GoalPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  const _GoalPage({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      heading: "WHAT'S YOUR\nGOAL?",
      subtext: "We'll build your path around it.",
      options: const ['Learn Tricks', 'Get Fit', 'Full Program'],
      selected: selected,
      onSelect: onSelect,
      buttonLabel: 'NEXT',
      onButton: onNext,
    );
  }
}

class _ChallengePage extends StatelessWidget {
  final VoidCallback onStart;

  const _ChallengePage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            'JOIN THE\nCHALLENGE',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Weekly community challenges. Compete. Progress. Rayse.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          // Challenge card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.accent,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Challenge',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'New challenge every Monday. Top jumpers get featured.',
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
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onStart,
            child: const Text("LET'S GO"),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String heading;
  final String subtext;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;
  final String buttonLabel;
  final VoidCallback onButton;

  const _OnboardingPage({
    required this.heading,
    required this.subtext,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.buttonLabel,
    required this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Text(
            heading,
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtext,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((option) {
              final isSelected = selected == option;
              return GestureDetector(
                onTap: () => onSelect(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.accent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onButton,
            child: Text(buttonLabel),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _DotIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : const Color(0xFF3F3F46),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
