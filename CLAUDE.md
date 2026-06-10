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

## What's built
- [x] Project scaffolded
- [x] Git + GitHub configured (yasuke0x0/rayse-app)
- [x] Makefile (web / android / phone / save)
- [x] Phase 1 — theme, splash, onboarding, home placeholder
- [x] Phase 2 — Auth (Supabase login / signup)
- [x] Phase 3 — Home + content library
- [x] Phase 4 — Skill tree
- [x] Phase 5 — Challenges + leaderboard
- [ ] Phase 6 — Daily workout program
- [ ] Phase 7 — Subscriptions (RevenueCat)