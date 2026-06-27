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

Admins create and manage challenges from the admin panel: **Profile → Admin Panel → CHALLENGES**.

The list screen groups challenges into THIS WEEK / UPCOMING / PAST. Tap **CREATE NEW CHALLENGE** for a fresh form, or tap any existing challenge to edit or delete it.

The form has:
- **Skill picker** with tier label (Beginner/Intermediate/Advanced) for each option
- **Title** (60 chars) and **description** (240 chars)
- **Week** (1–53), **year** (defaults to next ISO week), **XP** (defaults to 100)
- **CREATE CHALLENGE** / **SAVE CHANGES** / **DELETE CHALLENGE** actions
- Duplicate (skill+week+year) inserts are caught via Postgres `23505` and surfaced as "A challenge for this skill + week already exists."

Routes: `/admin/challenges` (list), `/admin/challenges/new` (create), `/admin/challenges/edit` (with `Challenge` as `extra`).

If you prefer SQL, the existing INSERT pattern still works:

```sql
INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward)
VALUES ('cross_overs', 'Cross Over Kings', 'Show us your smoothest Cross Overs.', 25, 2026, 100);
```

### Active vs Past vs Upcoming

- **Active:** `week_number` and `week_year` match the current ISO week (`isCurrentWeek`)
- **Upcoming:** challenge week is in the future (`isUpcoming`) — surfaced as a teaser card
- **Past:** challenge week has already passed (`isPast`)
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

### 4. Live Activity Strip

Between My Challenge Stats and Top 3 Podium, a "LIVE ACTIVITY" section shows the 3 most recent submissions for the active challenge:
- Green pulse dot + "LIVE ACTIVITY" header
- Each row: avatar (username initial), "@username submitted · 2h ago", 🔥 score
- Tappable rows → opens the video detail screen
- Hidden when the leaderboard is empty

Reuses `challengeLeaderboardProvider` data (no extra DB query). Relative time stamps (`just now / 12m ago / 3h ago / 2d ago`) keep the feel current even between visits.

Additionally, the active hero card shows a green "+X today" badge inline with the participant count when there are approved submissions today.

### 5. Top 3 Podium
- Shows the top 3 approved community videos for the challenge's skill+week
- Ranked by fire score (descending)
- Each row shows: rank badge (gold #1, dark #2-3), @username, 🔥 score
- Tapping a row navigates to `/community-video` detail screen
- **"SEE ALL"** link navigates to the dedicated challenge leaderboard screen (`/challenge-leaderboard`)
- Empty state: "No approved videos yet — be the first!"

### 6. Upcoming Challenge Teaser

If a challenge exists with a future `week_number` (computed from `Challenge.isUpcoming`), a teaser card appears below the active challenge sections:
- "⏳ COMING UP" blue badge + countdown ("starts today" / "in 1 day" / "in X days")
- Challenge title
- Skill pill (e.g. "CROSS OVERS")

Sorted by soonest first if multiple upcoming challenges exist (only the closest is shown). Hidden when no upcoming challenges exist in the DB. Gives users a reason to push toward mastering the next skill in advance.

### 7. Last Week's Winner Spotlight

The most recent past challenge's winner is highlighted in a dedicated card above the past challenges list:
- 🏆 "LAST WEEK'S WINNER" badge with orange accent
- Avatar (username initial), @username
- Skill + fire score (e.g. "CROSS OVERS · 42 🔥")
- Play button on the right
- Free users see a lock icon and tap → `/paywall`
- Premium users tap → opens the winner's video detail screen
- Hidden if there's no past challenge or no approved videos in its leaderboard

Reuses the existing `challengeLeaderboardProvider` — no extra DB query.

### 8. Past Challenges
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

## Multi-tier Weekly Challenges

To keep competition fair across skill levels, challenges are bucketed into three tiers based on the linked skill:

| Tier | Tier indexes | Skills |
|------|--------------|--------|
| Beginner | 0-1 | Basic Bounce, Forward Jump, Backward Jump, Alternating Steps |
| Intermediate | 2 | Double Unders, Cross Overs, Side Swing |
| Advanced | 3-4 | Triple Unders, Cross Double, Releases, Freestyle |

Tier is derived purely from `SkillNode.tier` in `skill_tree_data.dart` — no DB schema change required.

### User's tier
A user's tier = the highest tier they've mastered any skill in. New users default to Beginner.

### Tier selector
When **2 or more active challenges exist this week** (one per tier), a segmented tab selector appears at the top of the Challenges tab:
- All three tier tabs visible
- Tabs without an active challenge are muted and unclickable
- User's tier shows a small "FOR YOU" badge under the label
- Default selection = user's tier (with fallback if no challenge for that tier)
- Switching tabs changes which active challenge feeds the hero, recent activity, top 3, and live placement
- When only 1 active challenge exists, the selector is hidden (single-card layout)

### Tier-locked submissions (Option 1)
Users can **only submit to challenges in their own tier**. An advanced user can spectate a Beginner challenge but cannot enter it — preventing high-skill users from dominating lower-tier leaderboards.

- The CTA shows "🔒 [TIER] TIER ONLY" (gray) and is disabled
- A "RESERVED FOR [TIER]" panel above the CTA explains why and points to the user's own tier
- The submit video screen has a safety guard that blocks direct URL access ("RESERVED FOR [TIER] — submissions limited to your tier")
- Spectating, fire reactions, and viewing leaderboards remain open across tiers

### Persistence
`selectedChallengeTierProvider` is invalidated on auth state change (login/logout/account switch) to prevent cross-account state bleed.

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

## XP Rewards

Users earn XP for participating in challenges. Rewards are persisted via two Postgres triggers (`SECURITY DEFINER`) and reflected in `user_xp`.

| Event | XP Awarded | Triggered by |
|-------|-----------|--------------|
| Submit challenge video | +25 (flat) | `community_videos` AFTER INSERT |
| Admin approves video | +`challenge.xp_reward` (admin-configured per challenge, default 50) | `community_videos` BEFORE UPDATE OF status |
| Top 3 placement on finalize | +`challenge.xp_reward` bonus | Admin clicks "FINALIZE" on a past challenge → RPC `finalize_challenge(uuid)` |

### Finalizing a challenge

The admin challenges screen shows a "🏆 FINALIZE · AWARD TOP 3" button on every past challenge that isn't yet finalized. Clicking it:
1. Calls the `finalize_challenge(p_challenge_id)` RPC (SECURITY DEFINER)
2. Awards `+challenge.xp_reward` XP to the user_ids of the top 3 approved challenge videos for that skill+week
3. Sends each top-3 user a `challenge_placed` notification with their rank
4. Sets `challenges.finalized_at = now()` so the button disappears and a green "FINALIZED" pill is shown instead

Finalizing is idempotent at the row level — the RPC checks `finalized_at IS NULL` before doing anything. Reverting requires a manual `UPDATE challenges SET finalized_at = NULL WHERE id = ?` (no UI for this).

### Auto-finalize via pg_cron

A weekly cron job runs every Monday at 00:30 UTC and auto-finalizes any past challenge whose `finalized_at IS NULL`. The job calls a wrapper function `finalize_past_challenges()` which loops through eligible challenges and invokes `finalize_challenge(id)` on each. The wrapper uses `EXTRACT(isoyear FROM now())` and `EXTRACT(week FROM now())` so ISO-week year boundaries are handled correctly.

The admin FINALIZE button still works — the cron is a backstop that catches anything you forgot to finalize manually. If a challenge is finalized before Monday by the admin, the cron skips it (idempotency via `finalized_at IS NULL`).

### SQL needed for auto-finalize
```sql
-- 1. Enable pg_cron from Supabase: Database → Extensions → search "pg_cron" → enable.
--    (Cannot be done via SQL on most Supabase tiers — use the dashboard.)

-- 2. Wrapper that finalizes all past unfinalized challenges
CREATE OR REPLACE FUNCTION public.finalize_past_challenges()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_row record;
BEGIN
  FOR v_row IN
    SELECT id
      FROM public.challenges
      WHERE finalized_at IS NULL
        AND (
          week_year < EXTRACT(isoyear FROM now())
          OR (week_year = EXTRACT(isoyear FROM now())
              AND week_number < EXTRACT(week FROM now()))
        )
  LOOP
    PERFORM public.finalize_challenge(v_row.id);
  END LOOP;
END; $$;

-- 3. Schedule weekly on Monday at 00:30 UTC
SELECT cron.schedule(
  'finalize-past-challenges-weekly',
  '30 0 * * 1',
  $$SELECT public.finalize_past_challenges();$$
);
```

To verify the job is registered: `SELECT * FROM cron.job;`
To inspect runs: `SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 20;`
To unschedule: `SELECT cron.unschedule('finalize-past-challenges-weekly');`

### Locking finalized challenges from edits

Once finalized, the edit form goes into **locked mode**:
- A green "FINALIZED" banner explains the state
- Skill picker, week, year, XP fields are visually muted and uneditable
- Delete button is hidden
- Title and description remain editable (so admins can fix typos or wording without affecting placement / XP that was already paid out)

This prevents accidentally rewriting the criteria of a challenge whose top 3 XP has already been awarded. Reverting `finalized_at` via SQL re-enables the full edit form.

### Idempotency
- Submit trigger fires once per row insert (naturally idempotent).
- Approval trigger checks `xp_awarded` boolean column on `community_videos` and skips if already awarded. Reverting a video to pending and re-approving will NOT double-pay.

### Notification on approval
A notification is inserted (`type = 'challenge_approved'`) with the video id + xp amount. The notifications screen renders an `emoji_events_outlined` icon for this type.

### Client-side display
The submit success screen shows "+25 XP earned · more if approved" so the user sees the immediate reward. The DB trigger persists; we also bump local `xpProvider` by 25 so the home/profile XP counter updates without a refetch.

### SQL needed
```sql
ALTER TABLE public.community_videos
  ADD COLUMN IF NOT EXISTS xp_awarded boolean NOT NULL DEFAULT false;

ALTER TABLE public.challenges
  ADD COLUMN IF NOT EXISTS finalized_at timestamptz;

CREATE OR REPLACE FUNCTION public.finalize_challenge(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_challenge record;
  v_row record;
  v_rank integer := 0;
BEGIN
  SELECT * INTO v_challenge FROM public.challenges WHERE id = p_challenge_id;
  IF v_challenge IS NULL OR v_challenge.finalized_at IS NOT NULL THEN
    RETURN;
  END IF;

  FOR v_row IN
    SELECT user_id, score
      FROM public.community_videos
      WHERE is_challenge = true
        AND status = 'approved'
        AND skill_id = v_challenge.skill_id
        AND week_number = v_challenge.week_number
        AND week_year = v_challenge.week_year
      ORDER BY score DESC, submitted_at ASC
      LIMIT 3
  LOOP
    v_rank := v_rank + 1;
    INSERT INTO public.user_xp (user_id, total_xp, updated_at)
    VALUES (v_row.user_id, v_challenge.xp_reward, now())
    ON CONFLICT (user_id) DO UPDATE
      SET total_xp = public.user_xp.total_xp + v_challenge.xp_reward,
          updated_at = now();

    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      v_row.user_id,
      'challenge_placed',
      CASE v_rank
        WHEN 1 THEN '🥇 You won the challenge!'
        WHEN 2 THEN '🥈 You placed #2!'
        ELSE '🥉 You placed #3!'
      END,
      'You earned a +' || v_challenge.xp_reward || ' XP bonus on "' || v_challenge.title || '"',
      jsonb_build_object('challenge_id', p_challenge_id, 'rank', v_rank, 'xp', v_challenge.xp_reward)
    );
  END LOOP;

  UPDATE public.challenges SET finalized_at = now() WHERE id = p_challenge_id;
END; $$;

GRANT EXECUTE ON FUNCTION public.finalize_challenge(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.handle_challenge_video_submit()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.is_challenge = true THEN
    INSERT INTO public.user_xp (user_id, total_xp, updated_at)
    VALUES (NEW.user_id, 25, now())
    ON CONFLICT (user_id) DO UPDATE
      SET total_xp = public.user_xp.total_xp + 25,
          updated_at = now();
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS challenge_video_submit_trigger ON public.community_videos;
CREATE TRIGGER challenge_video_submit_trigger
  AFTER INSERT ON public.community_videos
  FOR EACH ROW EXECUTE FUNCTION public.handle_challenge_video_submit();

CREATE OR REPLACE FUNCTION public.handle_challenge_video_approval()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_reward integer;
BEGIN
  IF NEW.is_challenge = true
     AND NEW.status = 'approved'
     AND (OLD.status IS NULL OR OLD.status != 'approved')
     AND NEW.xp_awarded = false THEN
    SELECT xp_reward INTO v_reward
      FROM public.challenges
      WHERE skill_id = NEW.skill_id
        AND week_number = NEW.week_number
        AND week_year = NEW.week_year
      LIMIT 1;
    IF v_reward IS NOT NULL THEN
      INSERT INTO public.user_xp (user_id, total_xp, updated_at)
      VALUES (NEW.user_id, v_reward, now())
      ON CONFLICT (user_id) DO UPDATE
        SET total_xp = public.user_xp.total_xp + v_reward,
            updated_at = now();

      INSERT INTO public.notifications (user_id, type, title, body, data)
      VALUES (
        NEW.user_id,
        'challenge_approved',
        'Challenge Approved! 🏆',
        'Your video is live on the leaderboard. You earned +' || v_reward || ' XP',
        jsonb_build_object('video_id', NEW.id, 'xp', v_reward)
      );

      NEW.xp_awarded := true;
    END IF;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS challenge_video_approval_trigger ON public.community_videos;
CREATE TRIGGER challenge_video_approval_trigger
  BEFORE UPDATE OF status ON public.community_videos
  FOR EACH ROW EXECUTE FUNCTION public.handle_challenge_video_approval();
```

---

## Admin Constraints

### One challenge per tier per week
The admin form validates that no other challenge already exists for the same `(tier, week, year)` before saving. Tier is derived from the linked skill. If a conflict exists, the form rejects with a message naming the existing challenge so the admin can decide to edit it or pick a different tier/week.

This is an **app-side check** — not enforced by the DB. If you bypass the form (raw SQL), you can still create duplicates. The unique constraint at the DB level is `(skill_id, week_number, week_year)`.

The check is **skipped for no-op edits**: if the admin is editing an existing challenge and doesn't change tier/week/year, the uniqueness check doesn't run. This lets admins freely tweak title/description/XP on past challenges (including ones that pre-date the constraint and may legitimately have tier siblings).

---

## Notification Deep-Linking

Tapping a notification row in the notifications screen now routes the user to the most relevant destination based on `notification.type`:

| Type | Destination | Lookup |
|------|-------------|--------|
| `challenge_new` | Challenges tab on home | `homeTabIndexProvider.state = 2` |
| `challenge_approved` | Video detail | `fetchVideoById(data['video_id'])` → `/community-video` |
| `challenge_placed` | Challenge leaderboard | `fetchChallengeById(data['challenge_id'])` → `/challenge-leaderboard` |
| `comment` | Video detail | `fetchVideoById(data['video_id'])` → `/community-video` |
| unknown | (no nav, just marks read) | — |

Tap also marks the row as read first (before navigation) so the bell badge / profile tab dot update without waiting for the lookup. If the lookup returns `null` (e.g., the video was deleted), a snack bar reports it and no navigation happens.

Repository methods used:
- `CommunityVideoRepository.fetchVideoById(String id)` — single-row select on `community_videos`
- `ChallengeRepository.fetchChallengeById(String id)` — single-row select on `challenges`

---

## New Challenge Notifications

When an admin creates a new challenge, every non-banned user receives a notification ("🏆 New challenge dropped!" with the challenge title in the body). The notification renders with a `celebration_outlined` icon and counts toward the unread bell badge + profile tab dot we already wired.

### Why
Without this, the entire participation funnel only works for users who happen to open the app. The notification pulls them back in the moment a new challenge goes live.

### How
A Postgres AFTER INSERT trigger on `challenges` fans out one notification per non-banned user via a SECURITY DEFINER function. The reuse of the existing notifications table means no new tables, no new providers — the bell badge and profile tab dot update via the realtime stream we already hardened.

### SQL needed
```sql
CREATE OR REPLACE FUNCTION public.handle_new_challenge()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, body, data)
  SELECT
    p.id,
    'challenge_new',
    '🏆 New challenge dropped!',
    NEW.title || ' is live this week — submit your video!',
    jsonb_build_object(
      'challenge_id', NEW.id,
      'skill_id', NEW.skill_id,
      'week_number', NEW.week_number,
      'week_year', NEW.week_year
    )
  FROM public.profiles p
  WHERE p.is_banned IS DISTINCT FROM true;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS challenge_new_trigger ON public.challenges;
CREATE TRIGGER challenge_new_trigger
  AFTER INSERT ON public.challenges
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_challenge();
```

### Caveats
- The admin who created the challenge **also** gets the notification (the `challenges` row doesn't track the creator). Minor annoyance, no real consequence.
- Banned users (`is_banned = true`) are excluded; users with `is_banned IS NULL` are included.
- Push notifications (OS-level banner) are not wired — this only inserts a row that drives the in-app bell + tab dot + notifications screen. If/when we add APNs / FCM, the row insert is the natural trigger.

---

## Future Enhancements (Not Yet Built)

- ~~**Top 3 end-of-week bonus**~~ — shipped 2026-06-27 via admin FINALIZE button (manual instead of cron, see XP Rewards)
- ~~**Admin UI for creating challenges**~~ — shipped 2026-06-16: see Creating a Challenge above
- ~~**XP rewards on submit and approval**~~ — shipped 2026-06-16: see XP Rewards above
- ~~**Notifications when video is approved**~~ — shipped 2026-06-16
- ~~**Notifications when a new challenge drops**~~ — shipped 2026-06-27: see New Challenge Notifications above
- **Auto-rotation:** automatically create next week's challenge from a pool
- **Challenge history on profile:** show past challenge placements
- **Multiple challenges per week per tier:** current admin form prevents this; if needed, drop the tier uniqueness check
- **Push notifications (OS-level):** wire APNs/FCM so users get notified even with the app closed; the in-app notification rows are already in place
- ~~**pg_cron auto-finalize**~~ — shipped 2026-06-27 (Monday 00:30 UTC; see Finalizing a challenge → Auto-finalize via pg_cron)
