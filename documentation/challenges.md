# Challenges

Weekly skill challenges that leverage the community video system. Each week features a specific skill — participating means submitting a video, and the leaderboard is ranked by fire score.

---

## How It Works

Challenges are a **curated lens on top of community videos**, not a separate system.

```
Admin creates challenge row (skill + week)
        ↓
User sees challenge in Challenges tab
        ↓
User submits video via existing upload flow
        ↓
Video goes through admin approval
        ↓
Approved video appears on challenge leaderboard
        ↓
Community votes with 🔥 fire reactions
        ↓
Leaderboard ranks by fire score
```

No separate "join" or "entry" mechanism — your submission IS your participation.

---

## Database

### `challenges` table

| Column | Type | Description |
|--------|------|-------------|
| id | uuid (PK) | Auto-generated |
| skill_id | text | Links to skill system (e.g. `double_unders`) |
| title | text | Display title (e.g. "Double Under Showdown") |
| description | text | Challenge description shown in hero card |
| week_number | integer | ISO week number |
| week_year | integer | Year |
| xp_reward | integer | XP bonus (default 50, reserved for future use) |
| created_at | timestamptz | Auto-generated |

**Unique constraint:** `(skill_id, week_number, week_year)` — one challenge per skill per week.

No `challenge_participants` or `challenge_entries` tables needed. Participation data comes from `community_videos` (filtered by `skill_id` + `week_number` + `week_year` + `is_challenge = true`).

### `community_videos.is_challenge` flag

| Value | Meaning | Approval | Visibility |
|-------|---------|----------|------------|
| `true` | Challenge submission | Admin review (pending → approved/rejected) | Public leaderboard |
| `false` | Personal skill recording | Auto-approved | Private to user |

---

## Challenge Lifecycle

### Creating a Challenge

Challenges are created manually by inserting a row into the `challenges` table with the target `skill_id`, `week_number`, and `week_year`. There is no admin UI for this yet — use the Supabase SQL editor.

```sql
INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward)
VALUES ('cross_overs', 'Cross Over Kings', 'Show us your smoothest Cross Overs.', 25, 2026, 100);
```

### Active vs Past

- **Active:** `week_number` and `week_year` match the current ISO week
- **Past:** any challenge where the week has already passed
- Only one challenge should be active per week (enforced by convention, not constraint)

### Days Left

Computed from the current day's position in the ISO week. Sunday = 0 days left.

---

## Challenges Screen Layout

### 1. Header
"CHALLENGES" title + subtitle "Compete with the community every week"

### 2. Active Challenge Hero Card
- "THIS WEEK'S CHALLENGE" badge + days left countdown
- Challenge title and description
- Skill pill badge (e.g. "DOUBLE UNDERS")
- Participant count (total video submissions for that skill+week)
- CTA button:

| User State | Button | Action |
|------------|--------|--------|
| Hasn't submitted + mastered | "SUBMIT YOUR VIDEO" (orange) | → `/submit-video/{skillId}?challenge=true` |
| Already submitted | **Live placement card** with rank, fires-to-next, accent border for top 3 | → `/challenge-leaderboard` |
| Skill not mastered | "GO PRACTICE →" (muted orange) | → `/skill-detail/{skillId}` |
| Free user, premium skill | "🔒 PREMIUM — SUBMIT VIDEO" | → `/paywall` |

When the user has submitted to the active challenge, the CTA transforms into a live placement card showing:
- Medal badge (🥇/🥈/🥉) or rank number circle
- "YOU'RE CURRENTLY #N" as primary text
- Context-aware subtitle:
  - At #1 with others below: "🔥 Holding #1 by X fires"
  - At #1 alone: "🔥 Standing alone at the top"
  - At any other rank: "X 🔥 from #N-1 · See leaderboard"
  - Pending/no data yet: "Pending review or building your score"
- Top 3 get an accent border for emphasis
- Card is tappable → opens the full leaderboard screen

When the user has not mastered the challenge's skill, a **"NOT ELIGIBLE YET"** progress panel appears between the description and the CTA showing:
- Current sessions count (X/3)
- "Complete X practice sessions on [Skill] to unlock this challenge"
- Progress bar

This replaces the previous flat "🔒 MASTER THE SKILL FIRST" with an actionable path forward.

### 3. My Challenge Stats

Between the active hero card and the Top 3 podium, a "MY CHALLENGE STATS" section shows three tiles aggregating the user's lifetime challenge participation:
- 🏆 **JOINED** — count of distinct challenges entered (any status counts)
- 🔥 **TOTAL FIRES** — sum of fire scores across approved challenge submissions
- 🎖️ **BEST** — best (lowest) placement across all entered challenges (e.g. "#3")

Hidden entirely when the user has never joined a challenge.

### 4. Top 3 Podium
- Shows the top 3 approved community videos for the challenge's skill+week
- Ranked by fire score (descending)
- Each row shows: rank badge (gold #1, dark #2-3), @username, 🔥 score
- Tapping a row navigates to `/community-video` detail screen
- **"SEE ALL"** link navigates to the dedicated challenge leaderboard screen (`/challenge-leaderboard`)
- Empty state: "No approved videos yet — be the first!"

### 5. Past Challenges
- List of previous week challenges
- Each card shows: title, week number, skill name, **placement chip**
- Placement chip surfaces the user's history with each challenge:
  - 🥇 #1 — YOU WON (gold accent border on card)
  - 🥈 #2 / 🥉 #3 (medal pill, accent border)
  - "YOU PLACED #X" (regular pill) for ranks 4+
  - "You didn't enter" (muted pill) if no submission
- **Free users:** locked with "🔒 PREMIUM" badge, tapping → `/paywall`. Placement chip is hidden.
- **Premium users:** can browse past challenges with their placement context

### Empty States
- No challenges in DB: "NO CHALLENGES YET — Challenges are coming soon!"
- No active challenge this week: "NO CHALLENGE THIS WEEK — Check back soon"

---

## Two Types of Videos

The app distinguishes between **personal recordings** and **challenge submissions**:

| Aspect | Personal (Skill Node) | Challenge |
|--------|----------------------|-----------|
| Submitted from | Skill detail "RECORD VIDEO" | Challenge hero card "SUBMIT YOUR VIDEO" |
| `is_challenge` | `false` | `true` |
| Approval | Auto-approved | Admin review required |
| Visibility | Private (only the user) | Public (leaderboard + reactions) |
| Weekly context | No (all-time) | Yes (ISO week) |
| Fire reactions | No | Yes |
| Comments | No | Yes |
| Fields | Title + notes (editable) | Caption |

### Where videos appear

| Place | Shows |
|-------|-------|
| **Skill node "MY VIDEOS"** | All personal recordings for that skill (all-time, title displayed) |
| **Challenges top 3 podium** | Top 3 approved challenge videos for the week |
| **Challenge leaderboard screen** | Full ranked list of approved challenge videos (up to 50) |
| **Past challenge cards** | Premium users tap to view that week's full leaderboard |
| **Profile "MY VIDEOS"** | All user videos (personal + challenge) |

### Video Detail Screen

The video detail screen adapts based on video type:
- **Personal:** shows title, skill label, notes card, edit button (owner only). No fire button, no comments.
- **Challenge:** shows @username, skill, caption, fire button, fire score, comments section.

### Admin Panel (User Detail)

In the admin user detail videos section:
- **Challenge videos:** approve/reject buttons (pending), fire score + revert button (approved/rejected)
- **Personal videos:** "PERSONAL" label, no admin actions

Video list and XP are fetched fresh every time the admin opens a user's detail screen.

---

## Home Screen Integration

The home tab shows a **featured challenge card** that dynamically pulls from `activeChallengeProvider`:
- Shows challenge title + days left
- Tapping switches to the Challenges tab (index 2)
- Hidden entirely if no active challenge exists this week

---

## Data Flow

### What's Reused from Community Videos

| Data | Source | How It's Used |
|------|--------|---------------|
| Top 3 podium | `fetchTopVideosForSkill` filtered by `is_challenge=true` | Top 3 in challenges tab, full list in leaderboard screen |
| Participant count | Count of `community_videos` rows for skill+week with `is_challenge=true` | Shown in hero card |
| Submission check | `fetchMyVideos(userId, skillId)` filtered by week + `isChallenge` | Determines CTA button state |

**Important:** All challenge-related queries must filter `is_challenge=true`. Personal videos and challenge videos live in the same `community_videos` table, both can have `status='approved'`. Without the filter, personal videos leak into challenge leaderboards, participant counts, and the "SUBMITTED ✓" state.
| Video upload | `/submit-video/{skillId}?challenge=true` | 3-step flow with `is_challenge = true` |
| Video detail | `/community-video` screen | Tap leaderboard row to watch + react |
| Fire reactions | `toggle_reaction` RPC + `myReactionsProvider` | Voting mechanism = leaderboard ranking |
| Admin approval | Admin panel pending videos flow | Videos must be approved to appear on leaderboard |

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `challengesProvider` | StreamProvider | Fetches challenges from Supabase with realtime updates |
| `activeChallengeProvider` | Provider | Derives current week's challenge from the list |
| `challengeLeaderboardProvider(id)` | FutureProvider.family | Top 10 approved videos for the challenge |
| `hasSubmittedChallengeProvider(id)` | FutureProvider.family | Whether current user submitted this week |
| `challengeParticipantCountProvider(id)` | FutureProvider.family | Total submissions for the challenge |
| `myChallengePlacementProvider(id)` | FutureProvider.family | The user's 1-indexed rank in the challenge (null if not entered). Derived from `challengeLeaderboardProvider`. |
| `myChallengeStatsProvider` | FutureProvider | Aggregate stats: total challenges joined, total fires received, best placement. Fans out across recent challenge leaderboards to find the best rank. |

---

## Premium Gating

| Content | Free | Premium |
|---------|------|---------|
| View active challenge | Yes | Yes |
| View leaderboard | Yes | Yes |
| Submit video (free skill, mastered) | Yes | Yes |
| Submit video (premium skill) | No → paywall | Yes |
| Submit video (skill not mastered) | No → skill detail | No → skill detail |
| View past challenges | No → paywall | Yes |

Premium check uses `userTierProvider` (returns `'premium'` if `is_premium` or `is_creator`). Skill premium check uses `skill.isFreeNode` from the skill tree data.

**Mastery gate:** Users must complete 3 practice sessions (mastered status) for a skill before they can submit a challenge video for it. The CTA shows "🔒 MASTER THE SKILL FIRST" and taps navigate to the skill detail screen. The submit video screen also has a safety guard — if someone navigates directly to `/submit-video/{skillId}?challenge=true` without mastery, they see a full-screen message with a "GO TO SKILL" button.

---

## Week System

Uses the same ISO week calculation as community videos: `CommunityVideoRepository.isoWeek(DateTime)`.

- Challenge week matches community video `week_number` + `week_year`
- This means a challenge's leaderboard is exactly the community video rankings for that skill+week
- No duplication of data — single source of truth

---

## File Structure

```
lib/features/challenges/
  models/
    challenge.dart              -- Challenge entity (maps to DB table)
  providers/
    challenge_provider.dart     -- All providers (active, leaderboard, submission, participants)
  repository/
    challenge_repository.dart   -- Supabase queries (challenges table + participant count)
  screens/
    challenges_screen.dart              -- Main screen: hero card, top 3 podium, past challenges
    challenge_leaderboard_screen.dart   -- Full leaderboard for a challenge (all ranked videos)
```

Integration points:
- `lib/features/content/screens/home_screen.dart` — dynamic featured challenge card
- `lib/features/skill_tree/screens/skill_detail_screen.dart` — challenge banner when skill matches active challenge
- `lib/features/community/screens/submit_video_screen.dart` — shared upload flow, `isChallenge` param distinguishes type
- `lib/features/community/providers/community_provider.dart` — invalidates challenge providers on approve/reject

---

## Future Enhancements (Not Yet Built)

- **XP rewards:** `xp_reward` column exists but isn't wired. Tiers: submit = 25 XP, approved = 75 XP, top 3 = 150 XP
- **Admin UI for creating challenges:** currently manual SQL inserts
- **Auto-rotation:** automatically create next week's challenge from a pool
- **Challenge history on profile:** show past challenge placements
- **Notifications:** alert users when a new challenge drops
- **Multiple challenges per week:** current design supports it but UI shows one hero
