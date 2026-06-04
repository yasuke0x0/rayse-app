import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabConfig(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _TabConfig(
      label: 'Learn',
      icon: Icons.play_circle_outline,
      activeIcon: Icons.play_circle,
    ),
    _TabConfig(
      label: 'Challenges',
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
    ),
    _TabConfig(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _TabBody(tab: _tabs[_currentIndex]),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top border
          Container(
            height: 1,
            color: AppColors.border,
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textMuted,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
            items: _tabs
                .map(
                  (tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    activeIcon: Icon(tab.activeIcon),
                    label: tab.label,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  final _TabConfig tab;

  const _TabBody({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab.activeIcon,
            size: 48,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          Text(
            tab.label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
