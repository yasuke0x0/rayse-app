-- ════════════════════════════════════════════════════════════════════════════
-- create_weekly_challenge.sql
-- ────────────────────────────────────────────────────────────────────────────
-- Drops "this week's" challenge set — one per tier (BEGINNER / INTERMEDIATE /
-- ADVANCED) — anchored to the CURRENT ISO week. Run any time you want a live
-- weekly challenge without re-running the full demo seed.
--
-- Safe & idempotent:
--   * Anchors to the current ISO week via EXTRACT(week/isoyear FROM now()) —
--     the exact pairing rayse_seed_week(0) / the Flutter app use, so the app's
--     `isCurrentWeek` check lights these up as active.
--   * ON CONFLICT (skill_id, week_number, week_year) refreshes an existing row
--     instead of erroring, so re-running is a no-op-then-update.
--   * The `challenge_new_trigger` (AFTER INSERT) fans a 🏆 notification out to
--     every user ONLY for genuinely new rows. Re-runs hit the UPDATE branch and
--     do NOT re-notify, so the bell never gets spammed.
--
-- One challenge PER TIER, matching the app's tier rule (tierForSkill):
--   forward_jump  → BEGINNER      (tier ≤ 1)
--   double_unders → INTERMEDIATE  (tier = 2)
--   freestyle     → ADVANCED      (tier ≥ 3)
-- These are the same skills the demo seed uses for the active week, so this
-- script and seed_demo_data.sql stay in sync (upsert, never a second row).
-- ════════════════════════════════════════════════════════════════════════════

WITH wk AS (
  SELECT EXTRACT(week    FROM now())::int AS week_number,
         EXTRACT(isoyear FROM now())::int AS week_year
),
new_challenges (skill_id, title, description, xp_reward) AS (
  VALUES
    ('forward_jump',  'Forward Flow',
     'Clean forward jumps — how long can you stay on rhythm this week? Post your longest unbroken set.', 75),
    ('double_unders', 'Double Under Showdown',
     'Most consecutive double unders — smooth and controlled. Show us your best set.', 100),
    ('freestyle',     'Freestyle Friday',
     'Your most creative 30-second freestyle combo. Impress the crew.', 200)
)
INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward)
SELECT nc.skill_id, nc.title, nc.description, wk.week_number, wk.week_year, nc.xp_reward
FROM new_challenges nc CROSS JOIN wk
ON CONFLICT (skill_id, week_number, week_year) DO UPDATE
  SET title       = EXCLUDED.title,
      description = EXCLUDED.description,
      xp_reward   = EXCLUDED.xp_reward;

-- Verify what's now live for the current week:
SELECT skill_id, title, week_number, week_year, xp_reward, finalized_at
FROM public.challenges
WHERE week_number = EXTRACT(week    FROM now())::int
  AND week_year   = EXTRACT(isoyear FROM now())::int
ORDER BY xp_reward;
