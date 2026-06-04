# Rayse — Jump Rope Learning App

Mobile app built around @samsjump (Samy Sieber, 279K followers).
Free social content + premium courses, skill trees, and challenges.

## Commands
```bash
flutter run -d chrome          # Run in browser (fast dev)
flutter run                    # Run on Android emulator  
flutter analyze                # Check for errors
flutter pub get                # Install dependencies
```

## Brand & Design Language
Rayse uses a cinematic, sport-tech aesthetic — dark, bold, high-contrast.
Match the energy of the ecommerce site exactly.

- App name: Rayse
- Tagline: "Fall seven times, Rayse eight."
- Background: #09090b (zinc-950)
- Surface: #18181b (zinc-900)
- Border: rgba(255,255,255,0.06)
- Primary accent: #f97316 (orange-500) — used for CTAs, highlights, active states
- Text primary: #ffffff
- Text secondary: #a1a1aa (zinc-400)
- Text muted: #52525b (zinc-600)
- Font headings: Bebas Neue or Poppins Black — bold, uppercase, tight tracking
- Font body: Inter — clean, readable
- Corner radius: 24px for cards, 12px for buttons, 999px for pills
- NO gradients on surfaces — flat zinc fills only
- Accent lines, dashed SVG paths, subtle grid overlays as decoration (like the web app)
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
app_theme.dart       # All colors, text styles, component themes
app_colors.dart      # Color constants
router/
app_router.dart      # go_router config
widgets/
rayse_button.dart    # Primary CTA button (orange)
rayse_card.dart      # Dark card with border
features/
auth/
screens/
splash_screen.dart
onboarding_screen.dart
login_screen.dart
content/
screens/
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
- Use subtle grid overlay (opacity 0.04) on section backgrounds
- Dashed orange accent lines as decorative elements where fitting
- Headings: uppercase, tight letter spacing, bold weight
- All screens feel like a premium sports app — think Nike Training Club meets Duolingo

## Devlog

After completing any task (feature, fix, refactor), append an entry to `DEVLOG.md` at the project root with:
- Date and short title
- What was built or changed
- Files touched
- Any gotchas or decisions made


## Build order
1. Foundation + theme + splash + onboarding  ← START HERE
2. Auth (login / signup with Supabase)
3. Home + content library (free YouTube embeds)
4. Skill tree
5. Subscriptions (RevenueCat)
6. Challenges + leaderboard
7. Daily workout program


## What's built
- [x] Project scaffolded