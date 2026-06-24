
## 2026-06-16 — Multi-tier weekly challenges with tier-locked submissions

### What changed (A from the challenges tab enhancement plan)
- Challenges now bucketed into Beginner / Intermediate / Advanced based on the linked skill's tier (no DB schema change — derived from `SkillNode.tier`)
- New segmented tab selector at top of challenges tab when 2+ active challenges exist this week; "FOR YOU" badge marks user's tier
- Default selection = user's tier (highest mastered tier across all skills)
- Selecting a tab swaps the hero, recent activity, top 3, and live placement to that tier's challenge
- **Option 1 strict tier matching:** users can only submit to challenges in their own tier — prevents advanced users from dominating beginner leaderboards
- "RESERVED FOR [TIER]" panel + grayed-out CTA on out-of-tier challenges; spectating/voting still allowed
- Submit video screen got a tier safety guard for direct URL access
- New `tier_utils.dart` with `tierForSkill`, `highestMasteredTier`, `tierLabels` shared between challenges screen + submit screen
- New `ChallengeTier` enum + `selectedChallengeTierProvider` in `challenge_provider.dart`, invalidated on auth state change

### Files touched
- `lib/features/challenges/utils/tier_utils.dart` — NEW: tier mapping and helpers
- `lib/features/challenges/providers/challenge_provider.dart` — added `ChallengeTier` enum + `selectedChallengeTierProvider`
- `lib/features/challenges/screens/challenges_screen.dart` — `_TierSelector`, `_WrongTierPanel` widgets; multi-tier body logic
- `lib/features/community/screens/submit_video_screen.dart` — tier guard + extracted `_buildBlocker` helper
- `lib/features/content/screens/home_screen.dart`, login_screen.dart, signup_screen.dart — invalidate `selectedChallengeTierProvider` on auth changes
- `documentation/challenges.md` — new "Multi-tier Weekly Challenges" section

### SQL needed to test
```sql
DELETE FROM public.challenges WHERE week_number = 26 AND week_year = 2026;

INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward) VALUES
  ('basic_bounce', 'Bounce Marathon', 'Show your cleanest basic bounce.', 26, 2026, 50),
  ('double_unders', 'Double Under Showdown', 'Smooth, controlled double unders.', 26, 2026, 100),
  ('freestyle', 'Freestyle Flow', 'Show your most creative freestyle.', 26, 2026, 200);
```

### Gotchas
- Tier helpers live in `tier_utils.dart` (not in `_skillLabels`-style maps) so submit_video_screen and challenges_screen share the same logic
- Without `selectedChallengeTierProvider` in auth invalidation lists, a user's selected tier persists across account switches

## 2026-06-16 — Challenges tab: live signals (recent activity strip + today badge)

### What changed (E from challenges tab enhancement plan)
- **LIVE ACTIVITY section:** New section between My Stats and Top 3 podium showing the 3 most recent submissions for the active challenge (avatar + "@username submitted · 2h ago" + 🔥 score). Tappable rows open the video detail. Hidden when leaderboard is empty.
- **"+X today" badge on hero card:** Inline with the participant count, a green pulse dot + "+X today" pill appears when there are approved submissions today. Hidden when zero.
- Both signals derive from the existing `challengeLeaderboardProvider` — no new DB queries.
- Relative time stamps: just now / Xm ago / Xh ago / Xd ago / Xw ago

### Files touched
- `lib/features/challenges/screens/challenges_screen.dart` — added `_RecentActivityStrip` widget, "+X today" badge, `_countSubmittedToday` helper
- `documentation/challenges.md` — new section 4, renumbered following sections

## 2026-06-16 — Challenges tab: upcoming teaser + last week's winner spotlight

### What changed (F + G from challenges tab enhancement plan)
- **Upcoming challenge teaser (G):** New blue-accented card appearing below the active sections when a challenge exists with a future week. Shows title, skill pill, countdown ("in X days"). Sorted by soonest first when multiple exist.
- **Last week's winner spotlight (F):** New orange-accented card above the past challenges list showing the #1 video from the most recent past challenge — avatar, @username, skill + fires, play button. Free users hit paywall, premium tap through to the video. Reuses existing leaderboard provider (no new query).
- Added `Challenge.isUpcoming`, `Challenge.isPast`, `Challenge.daysUntilStart` getters
- `_ChallengesBody` now splits challenges into three buckets: active, upcoming, past
- Layout order: header → active hero → my stats → top 3 → **upcoming teaser** → **last winner spotlight** → past list

### Files touched
- `lib/features/challenges/models/challenge.dart` — isUpcoming/isPast/daysUntilStart getters
- `lib/features/challenges/screens/challenges_screen.dart` — `_UpcomingChallengeCard`, `_LastWinnerSpotlight` widgets, updated body layout
- `documentation/challenges.md` — added sections 5 and 6, updated lifecycle states

## 2026-06-16 — Fix: stale challenge state when switching accounts

### What changed
- Added `challengesProvider`, `myChallengePlacementProvider`, and `myChallengeStatsProvider` to the auth state invalidation lists in: home screen listener, login screen, signup screen
- Without these, switching accounts (logout → other login → logout → original login) showed "SUBMIT YOUR VIDEO" on the active challenge even though the user had already submitted and appeared in the top 3

### Root cause
The challenge providers added in recent enhancements (placement/stats) and the upstream `challengesProvider` (StreamProvider) weren't part of the cross-account invalidation. The cached `false` from a previous account session leaked into the new session's hero card before the underlying data caught up.

### Files touched
- `lib/features/content/screens/home_screen.dart` — extended auth state listener invalidations
- `lib/features/auth/screens/login_screen.dart` — added challenge provider invalidations
- `lib/features/auth/screens/signup_screen.dart` — added challenge provider invalidations

### Gotchas
- Every time we add a new user-specific provider (anything that reads `currentUser?.id`), it MUST be added to all three invalidation sites: `home_screen.dart` listener, `login_screen.dart`, and `signup_screen.dart`. Forgetting one creates subtle cross-account bleed.

## 2026-06-16 — Challenges tab: my stats section + live placement card

### What changed (C + H from challenges tab enhancement plan)
- **My Challenge Stats section (C):** Three stat tiles between the active hero and the Top 3 podium: Joined (count of distinct challenges entered), Total Fires (sum of approved scores), Best (lowest placement). Hidden when user has zero participation.
- **Live placement card (H):** When the user has submitted to the active challenge, the CTA transforms into a rich placement card: medal badge / rank circle, "YOU'RE CURRENTLY #N", and a context-aware subtitle showing fires-to-next-rank or "Holding #1 by X fires"
- Top 3 placement gets accent border + 1.5px width for emphasis
- Card is tappable and opens the full leaderboard
- New `myChallengeStatsProvider` aggregates by fanning out across recent leaderboards

### Files touched
- `lib/features/challenges/providers/challenge_provider.dart` — added `MyChallengeStats` model + `myChallengeStatsProvider`
- `lib/features/challenges/screens/challenges_screen.dart` — `_MyStatsSection`, `_StatTile`, `_LivePlacementCTA` widgets; replaced static "SUBMITTED ✓" button with live card
- `documentation/challenges.md` — updated screen layout numbering, CTA table, providers table

### Gotchas
- `myChallengeStatsProvider` only considers challenges visible in `challengesProvider` (recent 10) when computing best placement — older challenges aren't in scope. For lifetime stats across all history, we'd need a dedicated query that joins user videos with leaderboard ranks (likely an RPC).

## 2026-06-16 — Challenges tab: eligibility-aware hero + placement on past challenges

### What changed (B + D from challenges tab enhancement plan)
- **Eligibility-aware hero (B):** When the user hasn't mastered the challenge's skill, the hero card now shows a "NOT ELIGIBLE YET" panel with the actual mastery progress (X/3 sessions + progress bar) and "Complete X sessions on [Skill] to unlock this challenge" copy
- Hero CTA changed from grayed "🔒 MASTER THE SKILL FIRST" to actionable "GO PRACTICE →" (muted orange) — same destination (skill detail) but framed as an action, not a wall
- **Past challenge placement (D):** Each past challenge card now shows the user's placement: 🥇 #1 YOU WON / 🥈 #2 / 🥉 #3 / YOU PLACED #X / You didn't enter
- Top 3 placements get an orange-tinted card border for visual emphasis
- Placement hidden for free users (they see the premium lock)
- New `myChallengePlacementProvider` derives rank from existing `challengeLeaderboardProvider` (no extra DB calls)

### Files touched
- `lib/features/challenges/providers/challenge_provider.dart` — added `myChallengePlacementProvider`
- `lib/features/challenges/screens/challenges_screen.dart` — `_MasteryProgressPanel` widget, `_placementChip` helper, updated CTA logic
- `documentation/challenges.md` — updated CTA table, past challenges section, providers table

## 2026-06-16 — Personal vs challenge video isolation, mastery unlock messaging

### What changed
- Fixed personal videos leaking into challenge leaderboards: added `is_challenge=true` filter to `fetchTopVideosForSkill`, `fetchParticipantCount`, and `hasSubmittedChallengeProvider` (without it, an auto-approved personal video for the same skill+week made the challenge show "SUBMITTED ✓" and counted as a participant)
- Skill detail locked teaser renamed "MY VIDEOS" → "UNLOCKS AT MASTERY" — now shows both unlocks explicitly (record videos + join weekly challenges) so users understand what mastery enables
- Mastered "WHAT'S NEXT" reordered: record personal video first, join weekly challenge second (practice before competition)
- Result screen snackbar mentions both unlocks: "X sessions to unlock videos & weekly challenge"

### Files touched
- `lib/features/community/repository/community_video_repository.dart` — is_challenge filter on leaderboard query
- `lib/features/challenges/repository/challenge_repository.dart` — is_challenge filter on participant count
- `lib/features/challenges/providers/challenge_provider.dart` — is_challenge filter on submission check
- `lib/features/skill_tree/screens/skill_detail_screen.dart` — locked teaser with both unlock benefits
- `lib/features/skill_tree/screens/mastered_screen.dart` — swap order in WHAT'S NEXT
- `lib/features/skill_tree/screens/result_screen.dart` — updated snackbar copy
- `documentation/challenges.md` — clarified is_challenge filter requirement
- `documentation/skill-tree.md` — updated locked teaser and mastered flow docs

### Gotchas
- Personal videos and challenge videos share the same `community_videos` table — every challenge-side query MUST filter `is_challenge=true` or personal recordings will pollute the data
- Realtime sync for new tables (e.g. `challenges`) requires adding the table to `supabase_realtime` publication: `ALTER PUBLICATION supabase_realtime ADD TABLE public.challenges;` or via Database → Replication in Supabase dashboard

## 2026-06-16 — Admin user search

### What changed
- Added search bar to Manage Users screen (searches first name, last name, username, email)
- Matches any order: "Yassine Ksabi", "Ksabi Yassine", "yassine", "ksabi", "@username", "email@..."
- User count updates to show "X of Y users" when filtering
- Empty state when no users match the query
- User cards now show full name as primary text, @username + email as subtitle
- Clear button (×) to reset search

### Files touched
- `lib/features/community/screens/admin_users_screen.dart` — search bar, local filtering, updated card layout

## 2026-06-16 — User profiles: first/last name, username, avatar upload, edit screen

### What changed
- Registration now collects first name, last name, username (was single "full name" field that was discarded)
- Username validated: min 3 chars, alphanumeric + underscores, unique (DB constraint)
- Home greeting uses first name from profile ("GOOD MORNING, YASSINE") instead of email prefix
- Profile screen shows avatar image, full name, @username, edit icon (tappable → edit screen)
- New Edit Profile screen (`/edit-profile`): first name, last name, username, email change, avatar upload
- Avatar upload: pick from gallery (512x512, 80% quality), uploads to Supabase `avatars` bucket
- Email change via Supabase auth (sends confirmation to new address)
- Avatar fallback: first name initial → username initial → "?"

### Database changes
```sql
ALTER TABLE profiles ADD COLUMN first_name text NOT NULL DEFAULT '';
ALTER TABLE profiles ADD COLUMN last_name text NOT NULL DEFAULT '';
ALTER TABLE profiles ADD CONSTRAINT profiles_username_unique UNIQUE (username);
-- avatar_url column already existed
-- Supabase storage bucket "avatars" (public) created
```

### Files touched
- `lib/features/auth/repository/auth_repository.dart` — signUp now saves first_name, last_name, username
- `lib/features/auth/screens/signup_screen.dart` — split name into first/last + username field + validation
- `lib/features/content/screens/home_screen.dart` — greeting uses first_name from profileProvider
- `lib/features/profile/screens/profile_screen.dart` — avatar image, full name, edit button
- `lib/features/profile/screens/edit_profile_screen.dart` — NEW: edit profile + avatar upload
- `lib/core/router/app_router.dart` — added /edit-profile route

### Gotchas
- Avatar URL needs cache-bust timestamp query param (`?t=...`) or browsers show stale image after re-upload
- Supabase unique constraint violation is error code `23505` — catch `PostgrestException` specifically

## 2026-06-16 — Mastery gates, prerequisites, unlock fixes, fire reaction sync

### What changed
- Challenge submissions require skill mastery — CTA shows "🔒 MASTER THE SKILL FIRST" if not mastered
- Submit video screen has safety guard for unmastered challenge attempts (full-screen blocker with "GO TO SKILL" button)
- Locked skill nodes are now tappable — detail screen shows locked video placeholder, skill info preview, and prerequisites list
- Prerequisites section shows mastery status of each required skill (tappable to navigate)
- Skill detail CTA for premium users with locked skill shows "MASTER PREREQUISITES FIRST" instead of "UNLOCK WITH PREMIUM"
- Fixed `isPremiumLocked` defaulting to true while `userTierProvider` is loading (was showing premium lock for premium users)
- Fixed `alt_steps` missing `cross_overs` in `unlockIds` — Cross Overs now correctly requires both Forward Jump AND Alt Steps
- Fixed `double_unders` missing `cross_double` in `unlockIds` — Cross Double now correctly requires both Double Unders AND Cross Overs
- Fixed unlock logic: multi-prerequisite skills only unlock when ALL parents are mastered (was unlocking on first parent)
- Fixed challenge submission cache: `hasSubmittedChallengeProvider`, `challengeLeaderboardProvider`, `challengeParticipantCountProvider` now invalidated on auth state change
- Fire reactions now invalidate `challengeLeaderboardProvider` so top 3 and full leaderboard update after voting
- Mastered celebration screen: replaced "COMMUNITY CHALLENGE" section with "WHAT'S NEXT" (join challenge / record personal video)

### Files touched
- `lib/features/challenges/screens/challenges_screen.dart` — mastery gate on CTA
- `lib/features/community/screens/submit_video_screen.dart` — mastery guard for challenge uploads
- `lib/features/skill_tree/screens/skill_tree_screen.dart` — locked nodes now navigate to detail
- `lib/features/skill_tree/screens/skill_detail_screen.dart` — locked video placeholder, prerequisites, premium fix
- `lib/features/skill_tree/screens/mastered_screen.dart` — replaced community CTA with "WHAT'S NEXT"
- `lib/features/skill_tree/providers/skill_provider.dart` — multi-prerequisite unlock logic
- `lib/features/skill_tree/data/mock_skills.dart` — fixed unlockIds for alt_steps and double_unders
- `lib/features/community/providers/community_provider.dart` — fire reaction invalidates challenge leaderboard
- `lib/features/content/screens/home_screen.dart` — invalidate challenge providers on auth change
- `documentation/challenges.md` — mastery gate docs
- `documentation/skill-tree.md` — locked detail screen, prerequisites, unlock logic docs

### Gotchas
- `userTierProvider.valueOrNull ?? 'free'` causes false premium locks while provider is loading — use null check instead of defaulting to 'free'
- `unlockIds` defines what a skill unlocks (children), not what it needs — prerequisites are derived by reverse lookup

## 2026-06-13 — Comments on community videos + in-app notifications

### What changed
- Premium/creator users can comment on community videos (500 char max)
- Free users see comments but get "Upgrade to Premium" prompt
- Admins can delete any comment; users can delete their own
- Posting a comment sends an in-app notification to the video owner
- Notification bell on profile screen with unread count badge
- Notifications screen at /notifications with mark-as-read and mark-all-read
- Auth logout/login invalidates notification providers

### Files created
- lib/features/community/models/video_comment.dart
- lib/features/community/repository/comment_repository.dart
- lib/features/community/providers/comment_provider.dart
- lib/features/community/widgets/comments_section_widget.dart
- lib/features/notifications/models/app_notification.dart
- lib/features/notifications/repository/notification_repository.dart
- lib/features/notifications/providers/notification_provider.dart
- lib/features/notifications/screens/notifications_screen.dart

### Files modified
- lib/features/community/screens/community_video_detail_screen.dart (embedded comments)
- lib/features/profile/screens/profile_screen.dart (notification bell)
- lib/features/content/screens/home_screen.dart (provider invalidation)
- lib/core/router/app_router.dart (/notifications route)

### Gotchas
- User must create `video_comments` and `notifications` tables in Supabase (see SQL below)
- RLS policies needed for both tables
- The FK `video_comments_user_id_fkey` must exist for the PostgREST join

---

## 2026-06-13 — Admin panel redesign: All Videos tab with filters, audit trail, reviewer info

### What changed
- Redesigned admin panel with two tabs: PENDING (quick review) and ALL VIDEOS (full management)
- ALL VIDEOS tab: filter chips for status (all/pending/approved/rejected), week (current/previous), and skill
- Each video row shows submitter, skill pill, status pill, caption, submitted time, reviewer name + reviewed time, fire score, samy badge
- Reviewer audit trail: approve/reject now records `reviewed_by` UUID; video model includes `reviewedBy` (username) and `reviewedAt`
- Repository: added `fetchFilteredVideos()` with optional filters, `_selectWithReviewer` PostgREST FK alias join
- Provider: added `AdminVideoFilter` typedef and `adminFilteredVideosProvider` family provider
- Revert-to-pending action available on approved/rejected videos in All Videos tab
- Stats summary bar shows total/pending/approved/rejected counts

### Files touched
- lib/features/community/models/community_video.dart (reviewedBy, reviewedAt fields)
- lib/features/community/repository/community_video_repository.dart (fetchFilteredVideos, reviewer join, _parseList)
- lib/features/community/providers/community_provider.dart (AdminVideoFilter, adminFilteredVideosProvider)
- lib/features/community/screens/admin_panel_screen.dart (complete rewrite with TabBar)

### Gotchas
- User must run SQL: `ALTER TABLE community_videos ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES profiles(id);`
- PostgREST FK alias syntax: `reviewer:profiles!community_videos_reviewed_by_fkey(username)`

---

## 2026-06-13 — Admin UX: SAMY button, video preview, timestamps + admin gets premium access

### What changed
- Added SAMY approve button to pending videos in admin user detail (was missing — only had APPROVE/REJECT)
- Video rows now show upload timestamp ("2d ago", "5h ago", etc.)
- Tapping a video row navigates to the video player screen (`/community-video`)
- Admin panel main view: "Tap to copy video URL" replaced with "Tap to preview video" that opens the player
- `userTierProvider` now treats admins (`is_creator`) as premium — admins can access all premium features

### Files touched
- lib/features/skill_tree/providers/skill_provider.dart (userTierProvider checks is_creator)
- lib/features/community/screens/admin_user_detail_screen.dart (SAMY btn, timestamps, tap-to-play)
- lib/features/community/screens/admin_panel_screen.dart (tap-to-preview video)

---

## 2026-06-13 — Admin: Revert approved/rejected videos to pending

### What changed
- Added `revertToPending(id)` method to `CommunityVideoRepository` — resets status to pending, clears samy_approved and reviewed_at
- Updated `admin_user_detail_screen.dart` — approved/rejected videos now show a "REVERT TO PENDING" button
- Invalidates both `adminUserVideosProvider` and `pendingVideosProvider` after revert to keep all admin views in sync

### Files touched
- lib/features/community/repository/community_video_repository.dart
- lib/features/community/screens/admin_user_detail_screen.dart

### Gotchas
- Must invalidate `pendingVideosProvider` too so the main admin panel shows the reverted video in the queue

---

## 2026-06-13 — Phase B: Community Videos — Top 10 Feed, Reactions, Weekly Tabs, Archive Lock

### What was built
- `CommunityScreen` — main community tab with scrollable week tabs (THIS WEEK + last 4 weeks), top 10 approved videos per week
- `CommunityVideoDetailScreen` — full-screen video player (Chewie) + reaction count + FIRE IT button
- Fire reactions — optimistic local state via `MyReactionsNotifier`; score updates immediately in both list and detail without loading flash
- `ApprovedVideosNotifier` — `FamilyAsyncNotifier` parameterized by `(weekNumber, weekYear)`, exposes `updateScore()` for optimistic score mutation
- Archive lock — free users see a lock screen + paywall CTA when tapping any past-week tab
- Samy Approved badge shown on card thumbnails and detail screen
- Rank badge (`#1` accent-colored, rest semi-transparent black)
- Community added as 4th tab in bottom nav (`Icons.people`)
- Routes added: `/community`, `/community-video` (uses `GoRouterState.extra` to pass `CommunityVideo`)

### Files touched
- lib/features/community/models/community_video.dart (added copyWith)
- lib/features/community/repository/community_video_repository.dart (fetchApprovedVideos, toggleReaction, fetchMyReactions; _isoWeek→isoWeek public)
- lib/features/community/providers/community_provider.dart (ApprovedVideosNotifier, MyReactionsNotifier)
- lib/features/community/screens/community_screen.dart (new)
- lib/features/community/screens/community_video_detail_screen.dart (new)
- lib/core/router/app_router.dart (2 new routes)
- lib/features/content/screens/home_screen.dart (Community tab added)

### Gotchas
- `FamilyAsyncNotifier<T, (int, int)>` family uses Dart 3 records as key — works correctly because records implement == and hashCode by value
- Optimistic score update: `updateScore()` mutates the notifier's state directly (no re-fetch), avoiding loading flash in the list when user reacts
- `_localScore` in detail screen tracks score independently so the fire count updates instantly even though the widget.video is immutable
- `toggle_reaction` Postgres RPC needed — see SQL below

### SQL to run in Supabase SQL editor
```sql
create table if not exists community_reactions (
  user_id uuid references auth.users(id) on delete cascade,
  video_id uuid references community_videos(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, video_id)
);
alter table community_reactions enable row level security;
create policy "Read reactions" on community_reactions for select using (true);
create policy "Manage own reactions" on community_reactions for all using (auth.uid() = user_id);

create or replace function toggle_reaction(p_video_id uuid)
returns boolean language plpgsql security definer as $$
declare
  reacted boolean;
begin
  select exists(
    select 1 from community_reactions
    where video_id = p_video_id and user_id = auth.uid()
  ) into reacted;
  if reacted then
    delete from community_reactions where video_id = p_video_id and user_id = auth.uid();
    update community_videos set score = greatest(0, score - 1) where id = p_video_id;
    return false;
  else
    insert into community_reactions (user_id, video_id) values (auth.uid(), p_video_id);
    update community_videos set score = score + 1 where id = p_video_id;
    return true;
  end if;
end;
$$;
```

## 2026-06-13 — Phase A: Community Videos — Submit Flow + Admin Panel

### What was built
- `image_picker: ^1.1.2` added to pubspec.yaml
- `lib/features/community/models/community_video.dart` — CommunityVideo model with VideoStatus enum and `fromMap` factory (handles joined `profiles` table)
- `lib/features/community/repository/community_video_repository.dart` — uploadVideo (Supabase Storage), submitVideo (insert pending row), fetchPendingVideos, approveVideo, rejectVideo, fetchMyVideos; ISO week helper
- `lib/features/community/providers/community_provider.dart` — communityVideoRepositoryProvider, profileProvider, isCreatorProvider, PendingVideosNotifier (AsyncNotifier with approve/reject/invalidateSelf)
- `lib/features/community/screens/submit_video_screen.dart` — 3-step flow (pick video → caption → confirm), image_picker gallery pick max 60s, upload to Supabase Storage, insert row, success state
- `lib/features/community/screens/admin_panel_screen.dart` — gated admin panel, pendingVideosProvider.when, _VideoReviewCard StatefulWidget with approve/reject/samy_approved actions, clipboard copy for video URL, loading overlay
- `lib/features/skill_tree/screens/mastered_screen.dart` — added "COMMUNITY CHALLENGE" CTA card with SUBMIT YOUR VIDEO button pushing `/submit-video/:skillId`
- `lib/core/router/app_router.dart` — added `/submit-video/:skillId` and `/admin` routes

### Files touched
- pubspec.yaml
- lib/features/community/models/community_video.dart (new)
- lib/features/community/repository/community_video_repository.dart (new)
- lib/features/community/providers/community_provider.dart (new)
- lib/features/community/screens/submit_video_screen.dart (new)
- lib/features/community/screens/admin_panel_screen.dart (new)
- lib/features/skill_tree/screens/mastered_screen.dart (modified)
- lib/core/router/app_router.dart (modified)

### Gotchas
- Supabase `maybeSingle()` already returns `Map<String, dynamic>?` — no cast needed (flutter analyze caught it)
- `image_picker` 1.1.2 resolved to 1.2.2 (compatible)
- url_launcher not in deps — used `Clipboard.setData` for video URL in admin panel instead

## 2026-06-04 — Phase 1: Theme + Splash + Onboarding

### What was built
- Full dark theme system (AppColors + AppTheme) with zinc-950 background, orange accent, Poppins headings, Inter body
- go_router with /splash → /onboarding → /home routes
- ProviderScope + Supabase.initialize wired in main.dart
- Splash screen: animated fade-in wordmark, grid CustomPainter overlay, 2.5s auto-navigate
- Onboarding: 3-page PageView (Level / Goal / Challenge) with animated pill selectors and dot indicators
- Home screen: 4-tab BottomNavigationBar placeholder (Home / Learn / Challenges / Profile)

### Files touched
- pubspec.yaml (added flutter_riverpod, go_router, google_fonts, supabase_flutter)
- lib/main.dart
- lib/core/theme/app_colors.dart
- lib/core/theme/app_theme.dart
- lib/core/router/app_router.dart
- lib/features/auth/screens/splash_screen.dart
- lib/features/auth/screens/onboarding_screen.dart
- lib/features/content/screens/home_screen.dart
- test/widget_test.dart (replaced stale counter test)

### Decisions
- Used `publishableKey` instead of deprecated `anonKey` in Supabase.initialize
- Unselected onboarding pills keep orange 1px border (matches the brand energy even when inactive)
- Grid painter uses `withValues(alpha:)` (null-safe modern API) instead of deprecated `withOpacity`

## 2026-06-04 — Phase 2: Supabase Auth

### What was built
- SupabaseService: static client getter wrapping Supabase.instance.client
- AuthRepository: signIn / signUp / signOut / getCurrentUser with AuthException handling
- authRepositoryProvider + authStateProvider (StreamProvider on onAuthStateChange)
- AuthGateScreen: watches auth state, redirects to /home or /login
- LoginScreen: email + password fields, sign-in CTA, forgot password, "create account" outlined button, loading + error states
- SignupScreen: name + email + password fields, create account CTA, terms text, back arrow
- Router updated: /auth-gate, /login, /signup routes added
- Splash now navigates to /auth-gate (not /onboarding) — returning users skip onboarding
- Onboarding "LET'S GO" navigates to /login instead of /home

### Files touched
- lib/core/services/supabase_service.dart (new)
- lib/features/auth/repository/auth_repository.dart (new)
- lib/features/auth/providers/auth_provider.dart (new)
- lib/features/auth/screens/auth_gate.dart (new)
- lib/features/auth/screens/login_screen.dart (new)
- lib/features/auth/screens/signup_screen.dart (new)
- lib/core/router/app_router.dart (updated)
- lib/features/auth/screens/splash_screen.dart (updated nav target)
- lib/features/auth/screens/onboarding_screen.dart (updated nav target)
- CLAUDE.md (Phase 2 checked off)

### Gotchas
- supabase_flutter v2 uses onAuthStateChange stream returning AuthState objects; session != null means signed in
- AuthGate uses ref.listen (not ref.watch) for navigation side-effects — avoids calling context.go during build

## 2026-06-04 — Phase 3: Home screen + Content library

### What was built
- Tutorial model with fromJson/toJson
- 6 mock tutorials (placeholder @samsjump YouTube IDs — replace when verified)
- ContentRepository: getTutorials / getTutorialsByLevel / getTutorialById (mock data, Supabase-ready)
- Riverpod providers: tutorialsProvider, tutorialsByLevelProvider, tutorialByIdProvider (family)
- TutorialCard widget: 200px wide, YouTube thumbnail via cached_network_image, level badge, duration badge, tap → /tutorial/:id
- HomeScreen rebuilt: greeting header, featured challenge card, "Free Tutorials" horizontal scroll, "Your Level" filtered scroll, IndexedStack for tab persistence
- TutorialDetailScreen: YoutubePlayerBuilder + YoutubePlayer, back arrow overlay, badges, description, "More Like This" related cards
- Router: /tutorial/:id route added
- AppColors: levelBeginner / levelIntermediate / levelAdvanced added

### Files touched
- pubspec.yaml (added youtube_player_flutter, cached_network_image)
- lib/core/theme/app_colors.dart
- lib/core/router/app_router.dart
- lib/features/content/models/tutorial.dart (new)
- lib/features/content/data/mock_tutorials.dart (new)
- lib/features/content/repository/content_repository.dart (new)
- lib/features/content/providers/content_provider.dart (new)
- lib/features/content/widgets/tutorial_card.dart (new)
- lib/features/content/screens/home_screen.dart (rewritten)
- lib/features/content/screens/tutorial_detail_screen.dart (new)
- CLAUDE.md

### Gotchas
- youtube_player_flutter uses flutter_inappwebview which prints a Swift Package Manager warning on iOS — not an error, safe to ignore until plugin updates
- Video playback works on Android/iOS only; web shows a blank player area
- Mock YouTube IDs are placeholders — user should replace with real @samsjump video IDs
- Dart 3 wildcard `_` can be repeated in param lists; `(_, __)` → `(_, _)` to satisfy unnecessary_underscores lint

## 2026-06-10 — Phase 4: Skill tree + Profile tab

### What was built
- SkillNode model with id, title, description, level, isUnlocked, isCompleted, prerequisiteIds
- skill_tree_data.dart: static list of mock skill nodes (beginner → intermediate → advanced progression)
- skillTreeProvider (Riverpod): exposes skill node list, unlock/complete actions
- SkillTreeScreen: scrollable visual skill tree with node cards, lock/unlock states, progress indicators
- _ProfileTab wired into HomeScreen (Profile tab): shows current user email + LOG OUT button using authRepositoryProvider.signOut()
- Auth listener added to HomeScreen: redirects to /login when session ends
- Makefile: added `phone` target pointing to physical device ID; fixed missing newline at EOF

### Files touched
- lib/features/skill_tree/models/skill_node.dart (new)
- lib/features/skill_tree/data/skill_tree_data.dart (new)
- lib/features/skill_tree/providers/skill_tree_provider.dart (new)
- lib/features/skill_tree/screens/skill_tree_screen.dart (new)
- lib/features/content/screens/home_screen.dart (added SkillTreeScreen, _ProfileTab, auth listener)
- Makefile (added phone target, fixed EOF newline)
- CLAUDE.md (Phase 4 checked off)

### Gotchas
- SkillTreeScreen imported directly into home_screen.dart; no new router route needed (tab uses IndexedStack)
- Auth redirect uses ref.listen in build — consistent with the pattern established in Phase 2 (avoids calling context.go during build phase)

## 2026-06-10 — Phase 5: Challenges + Leaderboard

### What was built
- Challenge model with id, title, description, type (reps/time/streak), targetValue, unit, durationDays, startDate, participantCount, isActive; computed daysLeft and endDate
- LeaderboardEntry model with rank, username, score, unit, isCurrentUser flag
- 4 mock challenges: "100 Double Unders" (active), "30-Day Jump Streak", "500 Single Bounces", "Speed DU — Under 60s"
- Mock leaderboard with 5 entries including a "You" row highlighted in orange
- ChallengeRepository: getChallenges, getLeaderboard, joinChallenge, submitEntry (mock, Supabase-ready)
- challengesProvider (FutureProvider), leaderboardProvider (FutureProvider.family), joinedChallengesProvider (NotifierProvider<Set<String>>)
- ChallengesScreen: hero active challenge card (orange accent border, countdown, participant count, JOIN button), top-5 leaderboard with gold/silver/bronze rank colors, "More Challenges" list with per-card JOIN pills
- Removed _PlaceholderTab (fully unused after Phases 4 and 5)
- Wired ChallengesScreen into HomeScreen IndexedStack (tab index 2)

### Files touched
- lib/features/challenges/models/challenge.dart (new)
- lib/features/challenges/models/leaderboard_entry.dart (new)
- lib/features/challenges/data/mock_challenges.dart (new)
- lib/features/challenges/repository/challenge_repository.dart (new)
- lib/features/challenges/providers/challenge_provider.dart (new)
- lib/features/challenges/screens/challenges_screen.dart (new)
- lib/features/content/screens/home_screen.dart (wire ChallengesScreen, remove _PlaceholderTab)
- CLAUDE.md (Phase 5 checked off)

### Gotchas
- Leaderboard rank colors use `switch` expression (Dart 3) — gold #FBBF24, silver #94A3B8, bronze #D97706
- joinedChallengesProvider is in-memory only until Supabase challenge_participants table is wired in Phase 7+ work

## 2026-06-11 — Phase 6: Daily Workout Program

### What was built
- Exercise model: name, instruction, sets, reps (nullable), durationSeconds (nullable), restSeconds; computed targetLabel
- Workout model: id, title, description, weekday (1=Mon–7=Sun), durationMinutes, difficulty, focusArea, exercises list
- 7 mock workouts (Mon–Sun): Foundation, Endurance, Technique, Power, Flow, Challenge Day, Active Recovery — each with 3 exercises
- getTodayWorkout() helper that selects by DateTime.now().weekday
- WorkoutRepository: getWorkouts, getTodayWorkout, getWorkoutById (Supabase-ready)
- allWorkoutsProvider, todayWorkoutProvider, workoutByIdProvider (FutureProvider.family), completedWorkoutsProvider (NotifierProvider<Set<String>>)
- DailyWorkoutScreen: today's hero card (orange/green accent, exercise list, START WORKOUT CTA) + week overview rows with day labels, duration, and completion dot
- WorkoutPlayerScreen: step-through player with progress bar + dots, set counter, rest view (shows rest duration + "up next"), completion dialog; state managed with _exerciseIndex / _currentSet / _isResting
- _TodayWorkoutBanner widget on HomeScreen: tappable banner showing today's workout name, duration, and done/not-done state
- Router: /workout and /workout/play/:id routes added

### Files touched
- lib/features/workout/models/exercise.dart (new)
- lib/features/workout/models/workout.dart (new)
- lib/features/workout/data/mock_workouts.dart (new)
- lib/features/workout/repository/workout_repository.dart (new)
- lib/features/workout/providers/workout_provider.dart (new)
- lib/features/workout/screens/daily_workout_screen.dart (new)
- lib/features/workout/screens/workout_player_screen.dart (new)
- lib/core/router/app_router.dart (added /workout and /workout/play/:id)
- lib/features/content/screens/home_screen.dart (added _TodayWorkoutBanner)
- CLAUDE.md (Phase 6 checked off)

### Gotchas
- WorkoutRepository.getTodayWorkout() uses a namespaced import (data.getTodayWorkout()) to avoid infinite recursion with identically-named method
- completedWorkoutsProvider is in-memory only — needs Supabase workout_completions table before Phase 7
- WorkoutPlayerScreen uses setState (local UI state) — acceptable per conventions since _exerciseIndex/_currentSet/_isResting are purely local player state

## 2026-06-13 — Skill tree full flow with XP and mastery system

### What was built
- Skill model (lib/features/skill_tree/models/skill.dart): SkillStatus enum + immutable Skill with copyWith
- SkillSession model (lib/features/skill_tree/models/skill_session.dart)
- mock_skills.dart: buildMockSkills() with 11 full skills — YouTube IDs, 5 coaching tips each, unlock graph, XP rewards, free/premium flags
- skill_provider.dart: XPNotifier/xpProvider, userTierProvider (stubbed 'free'), SkillsNotifier/skillsProvider — completeSession() handles sessions 1→2→3, auto-unlocks downstream skills, awards XP
- SkillDetailScreen: YouTube embed with 80% watch gate, staggered tip animations, session progress dots, status badge, premium lock overlay
- PracticeScreen: 60-second circular countdown timer with CustomPainter arc, rotating coaching tip via FadeTransition, haptic on completion
- ResultScreen: animated trophy icon, rep counter +/- widget, session progress dots, XP float animation, "I GOT IT" → completeSession → mastered or snackbar flow
- MasteredScreen: confetti CustomPainter, elastic star scale animation, XP count-up (IntTween), share card, Share.share() via share_plus
- PaywallScreen: pricing card, feature list, grid overlay, RevenueCat stub snackbar
- Updated skill_tree_screen.dart: uses skillsProvider + xpProvider + userTierProvider, XP badge in header, 4-state node visuals (locked/available/completed/mastered), taps navigate to /skill-detail or /paywall
- Router: 5 new routes — /skill-detail/:skillId, /skill-practice/:skillId, /skill-result/:skillId, /skill-mastered/:skillId, /paywall

### Files touched
- lib/features/skill_tree/models/skill.dart (new)
- lib/features/skill_tree/models/skill_session.dart (new)
- lib/features/skill_tree/data/mock_skills.dart (new)
- lib/features/skill_tree/providers/skill_provider.dart (new)
- lib/features/skill_tree/screens/skill_detail_screen.dart (new)
- lib/features/skill_tree/screens/practice_screen.dart (new)
- lib/features/skill_tree/screens/result_screen.dart (new)
- lib/features/skill_tree/screens/mastered_screen.dart (new)
- lib/features/skill_tree/screens/skill_tree_screen.dart (rewritten)
- lib/features/subscription/screens/paywall_screen.dart (new)
- lib/core/router/app_router.dart (5 new routes added)
- pubspec.yaml (share_plus: ^10.0.0 added)
- DEVLOG.md

### Gotchas
- share_plus v10 uses static Share.share(text) API — not SharePlus.instance.share(ShareParams(...)) which is v13+ syntax
- AnimatedBuilder builder: (_, __) triggers unnecessary_underscores lint in Dart 3 — use (_, child) or named second param instead
- ScaffoldMessenger.of(context) must be captured before context.pop() to avoid deactivated context exception in result_screen
- SkillsNotifier stores Ref internally (not WidgetRef) to call xpProvider from inside StateNotifier
