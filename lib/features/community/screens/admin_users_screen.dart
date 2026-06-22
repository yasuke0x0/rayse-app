import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/community_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> users) {
    if (_query.isEmpty) return users;
    final q = _query.toLowerCase();
    return users.where((u) {
      final username = (u['username'] as String? ?? '').toLowerCase();
      final email = (u['email'] as String? ?? '').toLowerCase();
      final first = (u['first_name'] as String? ?? '').toLowerCase();
      final last = (u['last_name'] as String? ?? '').toLowerCase();
      return username.contains(q) ||
          email.contains(q) ||
          first.contains(q) ||
          last.contains(q) ||
          '$first $last'.contains(q) ||
          '$last $first'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MANAGE USERS',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      usersAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, st) => const SizedBox.shrink(),
                        data: (users) {
                          final filtered = _filter(users);
                          final label = _query.isEmpty
                              ? '${users.length} registered user${users.length == 1 ? '' : 's'}'
                              : '${filtered.length} of ${users.length} users';
                          return Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.invalidate(allUsersProvider),
                    child: const Icon(Icons.refresh_rounded,
                        color: AppColors.textSecondary, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, username or email',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.accent, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User list
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, st) => Center(
                  child: Text('Failed to load users',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted)),
                ),
                data: (users) {
                  final filtered = _filter(users);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'No users yet'
                            : 'No users match "$_query"',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _UserCard(user: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final username = user['username'] as String? ?? 'unknown';
    final email = user['email'] as String? ?? '';
    final firstName = user['first_name'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final isCreator = user['is_creator'] == true;
    final isPremium = user['is_premium'] == true;
    final isBanned = user['is_banned'] == true;

    return GestureDetector(
      onTap: () => context.push('/admin/user-detail', extra: user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isBanned
                ? const Color(0xFFF87171).withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isBanned
                    ? const Color(0xFF450A0A)
                    : AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isBanned
                    ? const Icon(Icons.block, color: Color(0xFFF87171), size: 18)
                    : Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fullName.isNotEmpty ? fullName : '@$username',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isBanned
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            decoration: isBanned
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _roleBadge(
                          isCreator: isCreator,
                          isPremium: isPremium,
                          isBanned: isBanned),
                    ],
                  ),
                  Text(
                    '@$username${email.isNotEmpty ? ' · $email' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge({
    required bool isCreator,
    required bool isPremium,
    required bool isBanned,
  }) {
    if (isBanned) {
      return _pill('BANNED', const Color(0xFF450A0A), const Color(0xFFF87171));
    }
    if (isCreator) {
      return _pill('ADMIN', const Color(0xFF1E3A5F), const Color(0xFF60A5FA));
    }
    if (isPremium) {
      return _pill('PREMIUM', const Color(0xFF7C2D12), AppColors.accent);
    }
    return _pill('FREE', const Color(0xFF27272A), AppColors.textSecondary);
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.5,
          ),
        ),
      );
}
