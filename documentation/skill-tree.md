# Skill Tree

The skill tree is the core learning progression system. Users unlock skills in a branching graph, practice each one through timed sessions, and earn XP as they progress from beginner to expert.

---

## Skill Map

11 skills organized in 5 tiers, connected by unlock dependencies.

```
                      TIER 0
                  [Basic Bounce]
                   /     |     \
              TIER 1     |      
       [Forward Jump] [Backward Jump] [Alt Steps]
            |    \         |              |
         TIER 2   \        |              |
    [Double Unders] [Cross Overs]   [Side Swing]
         |    \          |              |
      TIER 3   \         |              |
 [Triple Unders] [Cross Double]   [Releases]
              \        |           /
               \       |          /
                   TIER 4
                 [Freestyle]
```

### All Skills

| Skill | Tier | XP | Free | Unlocked By |
|-------|------|----|------|-------------|
| Basic Bounce | 0 | 50 | Yes | -- (starting skill) |
| Forward Jump | 1 | 75 | Yes | Basic Bounce |
| Backward Jump | 1 | 75 | Yes | Basic Bounce |
| Alternating Steps | 1 | 75 | No | Basic Bounce |
| Double Unders | 2 | 100 | No | Forward Jump |
| Cross Overs | 2 | 100 | No | Forward Jump + Alt Steps |
| Side Swing | 2 | 150 | No | Backward Jump |
| Triple Unders | 3 | 175 | No | Double Unders |
| Cross Double | 3 | 200 | No | Double Unders + Cross Overs |
| Releases | 3 | 175 | No | Side Swing |
| Freestyle | 4 | 500 | No | Triple Unders + Cross Double + Releases |

**Free skills:** Basic Bounce, Forward Jump, Backward Jump. Everything else requires Premium.

---

## Skill Statuses

Each skill has one of four statuses that determines what the user can do with it.

| Status | Meaning | Tree Visual | Detail Screen CTA |
|--------|---------|-------------|-------------------|
| Locked | Prerequisites not mastered (or premium-gated) | Gray circle + lock icon | "UNLOCK WITH PREMIUM" or disabled |
| Available | Ready to practice | Gray circle + orange glow border | "START PRACTICE" (after watching video) |
| Completed | 1-2 sessions done | Gray circle + progress arc (1/3 or 2/3) | "START PRACTICE" |
| Mastered | 3 sessions done | Orange circle + gold star | "PRACTICE AGAIN" |

---

## Mastery Progression

Each skill requires **3 practice sessions** to master.

```
Available (0/3) --> Completed (1/3) --> Completed (2/3) --> Mastered (3/3)
```

### Practice Session Flow

1. **Skill Detail Screen** -- user watches the tutorial video (must watch 80% before practice unlocks, unless they've already completed a session)
2. **Practice Screen** -- 60-second countdown timer with rotating coaching tips (tips swap every 12 seconds)
3. **Result Screen** -- user logs their rep count and confirms:
   - "I GOT IT!" -- saves the session, awards XP, advances progress
   - "NEEDS MORE PRACTICE" -- goes back without saving
4. **Mastered Screen** (on 3rd session) -- celebration with confetti, animated XP count, share-to-Instagram card, and community challenge CTA

### What Happens on Mastery

When a skill reaches 3/3 sessions:
- Status changes to **mastered**
- All skills in its `unlockIds` list change from **locked** to **available**
- XP is awarded
- User sees the mastered celebration screen
- Community video submission becomes available for that skill

---

## XP System

| Event | XP Earned |
|-------|-----------|
| Complete any practice session | Skill's `xpReward` value |

XP is cumulative and never decreases. Displayed in the skill tree header as a total.

XP values range from 50 (Basic Bounce) to 500 (Freestyle). Full mastery of all 11 skills = 1,475 XP.

---

## My Videos (Personal Recordings)

Each mastered skill has a **"MY VIDEOS"** section in its detail screen — a personal library of all practice recordings for that skill.

### How It Works

- Videos are **private** — only visible to the user who recorded them
- Videos are **auto-approved** — no admin review needed
- Videos are **all-time** — every recording ever made for that skill, not weekly
- No premium gate — any user with a mastered skill can record videos

### Challenge Banner

If this skill is the **active weekly challenge**, a highlighted banner appears at the top of the section: "THIS WEEK'S CHALLENGE SKILL" with a "VIEW" link that navigates to the Challenges tab.

### Before Mastery (Locked State)

For available/completed skills (not yet mastered), a locked teaser section shows:
- "Complete X more session(s) to unlock video recording."
- Progress bar (1/3, 2/3)
- Session counter

The result screen snackbar also reminds users: "X sessions to unlock video recording"

### Record Video

"RECORD VIDEO" button navigates to the 3-step upload flow (pick video, add caption, submit). The video is saved with `is_challenge = false` and `status = 'approved'` immediately.

---

## Premium Gating

| User Tier | Access |
|-----------|--------|
| Free | Basic Bounce, Forward Jump, Backward Jump only. Locked skills show paywall. Video overlays show "UNLOCK WITH PREMIUM". |
| Premium | All 11 skills. |

Personal video recording is available to all users on mastered skills (no premium gate). Challenge video submissions require premium for premium-gated skills.

Premium check uses `userTierProvider` which returns `'premium'` if the user has `is_premium` or `is_creator` set in their profile.

---

## Unlock Logic

When a skill is mastered, the provider checks its `unlockIds` list and sets each target skill from `locked` to `available`. Multi-prerequisite skills (like Cross Overs, which needs both Forward Jump and Alt Steps) only unlock when **all** prerequisites are mastered -- the unlock check runs on each mastery event and only transitions skills whose entire prerequisite chain is satisfied.

---

## Tree Visualization

The skill tree screen renders a scrollable canvas with:
- **Grid overlay** at 80px spacing (very low opacity)
- **5 horizontal tiers** with 150px vertical gap
- **Connection lines** between prerequisite and dependent nodes, colored by progress:
  - Both mastered/completed: orange (80% opacity)
  - Parent completed: orange (40% opacity)
  - Neither: gray
- **Node circles** (72x72px) styled per status
- Tap a node to navigate to its detail screen

---

## Data & Persistence

### Local State
- `skillsProvider` (StateNotifier) holds the full skill list with current statuses
- `xpProvider` (StateNotifier) holds total XP
- State updates are optimistic (immediate UI update)

### Supabase Tables

**`user_skill_progress`** -- one row per user per skill
- `user_id`, `skill_id`, `sessions_completed`, `status`, `updated_at`

**`user_xp`** -- one row per user
- `user_id`, `total_xp`, `updated_at`

### Sync Behavior
- On app load: fetches from Supabase and merges with local skill definitions
- On session completion: updates local state immediately, writes to DB asynchronously (fire-and-forget)
- Network errors are silently ignored (local state preserved)

---

## File Structure

```
lib/features/skill_tree/
  screens/
    skill_tree_screen.dart        -- Main tree canvas with nodes and connections
    skill_detail_screen.dart      -- Video, tips, community, practice CTA
    practice_screen.dart          -- 60-second timer with coaching tips
    result_screen.dart            -- Rep logging and session confirmation
    mastered_screen.dart          -- Celebration, share, community challenge
  models/
    skill.dart                    -- Skill entity (id, title, status, xpReward, etc.)
    skill_node.dart               -- Tree layout data (tier, position, connections)
    skill_session.dart            -- Session history record
  providers/
    skill_provider.dart           -- SkillsNotifier, XPNotifier, completeSession logic
    skill_tree_provider.dart      -- Tree selection state
  repository/
    skill_progress_repository.dart -- Supabase CRUD for progress and XP
  data/
    skill_tree_data.dart          -- Hardcoded tree structure (tiers, positions, connections)
    mock_skills.dart              -- 11 skill definitions with tips, videos, unlock chains
```

---

## Navigation Paths

```
Skill Tree Tab
  |-- tap node --> /skill-detail/{skillId}
  |                   |-- "START PRACTICE" --> /skill-practice/{skillId}
  |                   |                          |-- timer ends --> /skill-result/{skillId}
  |                   |                                              |-- "I GOT IT!" --> /skill-mastered/{skillId}
  |                   |                                              |                     |-- "CONTINUE" --> /home
  |                   |                                              |-- "NEEDS MORE PRACTICE" --> back to detail
  |                   |-- "RECORD VIDEO" --> /submit-video/{skillId} (personal, auto-approved)
  |                   |-- challenge banner "VIEW" --> Challenges tab
  |                   |-- premium lock --> /paywall
```
