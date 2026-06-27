# Rayse — Jump Rope Learning App

Mobile app built around @samsjump (Samy Sieber, 279K followers).
Free social content + premium courses, skill trees, and challenges.

## Commands
```bash
flutter run -d chrome     # Run in browser (fast dev)
flutter run               # Run on Android emulator
flutter analyze           # Check for errors
flutter pub get           # Install dependencies
```

## Brand & Design Language
Rayse uses a cinematic, sport-tech aesthetic — dark, bold, high-contrast.

- App name: Rayse
- Tagline: "Fall seven times, Rayse eight."
- Background: #09090b (zinc-950)
- Surface: #18181b (zinc-900)
- Border: rgba(255,255,255,0.06)
- Primary accent: #f97316 (orange-500)
- Text primary: #ffffff
- Text secondary: #a1a1aa (zinc-400)
- Text muted: #52525b (zinc-600)
- Font headings: Poppins Black — bold, uppercase, tight tracking
- Font body: Inter — clean, readable
- Corner radius: 24px cards, 12px buttons, 999px pills
- NO gradients on surfaces — flat zinc fills only
- Active tab / selected state always uses #f97316

## Stack
- Flutter 3.44.1 + Dart
- Supabase (auth + database + storage)
- RevenueCat (subscriptions)
- flutter_riverpod 2.x (state management)
- go_router (navigation)
- google_fonts (Poppins + Inter)
- cached_network_image (video thumbnails)
- youtube_player_flutter (free content embeds)

## Project structure
lib/
main.dart
core/
theme/
app_colors.dart
app_theme.dart
router/
app_router.dart
widgets/
rayse_button.dart
rayse_card.dart
features/
auth/screens/
splash_screen.dart
onboarding_screen.dart
login_screen.dart
content/screens/
home_screen.dart
skill_tree/
challenges/
profile/

## Conventions
- Feature-first folder structure
- Riverpod providers for ALL state — no setState except purely local UI
- Repository pattern: all Supabase calls in lib/features/*/repository/
- Screens end in Screen, widgets end in Widget
- All colors from AppColors — never hardcode hex in widgets
- All text styles from Theme.of(context).textTheme — never hardcode font sizes

## Design rules (follow strictly)
- Background is always #09090b — never white, never grey
- Cards: #18181b fill + 1px border rgba(255,255,255,0.06)
- Buttons: #f97316 fill, white text, bold uppercase, tracking wide
- Subtle grid overlay (opacity 0.04) on section backgrounds
- Headings: uppercase, tight letter spacing, bold weight
- Feel: premium sports app — Nike Training Club meets Duolingo

## After every task (mandatory)
1. Check off completed items in "What's built" below
2. Append a dated entry to DEVLOG.md (date, what changed, files touched, gotchas)
3. git add . && git commit -m "type: description" && git push

Commit types: feat / fix / chore / style / refactor

## Supabase changes (mandatory)
The `supabase/` folder must always reflect what's actually in production.

Whenever you propose SQL — `CREATE/ALTER/DROP TABLE`, `CREATE FUNCTION`, `CREATE/DROP POLICY`, `CREATE TRIGGER`, new index, RPC, storage policy, realtime subscription, cron job, anything schema-level — you MUST:

1. **Update `supabase/setup.sql`** so a fresh project produces the post-change state. Use idempotent forms (`IF NOT EXISTS`, `CREATE OR REPLACE`, `DROP POLICY IF EXISTS … CREATE POLICY`).
2. Mention this in the same response. The user runs the SQL once on production; `setup.sql` already reflects the new shape so future fresh setups stay in sync.
3. For documentation-worthy changes (new feature, new RPC, new trigger), also update `supabase/SETUP.md` if it explains a new operation, and the relevant doc in `documentation/`.

If the user runs SQL directly without going through you, re-run `supabase/audit.sql` and reconcile `setup.sql` against the live state.

NEVER deliver a SQL block to the user without first updating `supabase/setup.sql`. Drift between live and `setup.sql` defeats the whole point of having a setup file.

## Demo seed (mandatory)
The `supabase/seed_demo_data.sql` script is what the user runs to populate a clean demo before showing the app. If you ship a feature whose UX requires data to be visible (a new notification type, a new admin view, a new on-profile widget, a new piece of seedable state), update `seed_demo_data.sql` so demos always reflect the latest surface. If you add a new persona-level capability (e.g., a new role flag, a new mastery state), update `seed_personas.sql` too.

## What's built
- [x] Project scaffolded
- [x] Git + GitHub configured (yasuke0x0/rayse-app)
- [x] Makefile (web / android / phone / save)
- [x] Phase 1 — theme, splash, onboarding, home placeholder
- [x] Phase 2 — Auth (Supabase login / signup)
- [x] Phase 3 — Home + content library
- [x] Phase 4 — Skill tree
- [x] Phase 5 — Challenges + leaderboard
- [x] Phase 6 — Programs (workout groups with premium gating)
- [ ] Phase 7 — Subscriptions (RevenueCat)