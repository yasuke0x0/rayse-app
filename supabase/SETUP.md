# Supabase Setup

How to spin up a fresh Supabase project for Rayse. The runnable SQL lives in [`setup.sql`](./setup.sql); this doc walks through the dashboard steps that have to happen before and after running it, plus how to verify everything wired up correctly.

---

## 1. Create the project

In the Supabase dashboard, create a new project. Pick the region nearest to your users. Copy the **Project URL** and **anon key** from Project Settings → API into the app's environment config.

---

## 2. Enable required extensions (dashboard)

Most Supabase tiers don't let you enable extensions via SQL, so do this from the dashboard before running `setup.sql`:

- **Database → Extensions** → search for `pg_cron` → click **Enable**.

`pgcrypto` is usually pre-enabled; if it isn't, `setup.sql` enables it for you.

---

## 3. Create the storage buckets (dashboard)

Buckets can't be created via SQL, so do this from the dashboard:

- **Storage → New bucket** → name: `avatars` → **Public bucket: ON** → Create.
- **Storage → New bucket** → name: `community-videos` → **Public bucket: ON** → Create.

The bucket *policies* (who can read/write) are set by `setup.sql`. You only need to create the bucket shells here.

---

## 4. Run `setup.sql`

Open **SQL Editor**, paste the entire contents of [`setup.sql`](./setup.sql), and run. It is idempotent (safe to re-run).

The script creates:

| Layer | What's set up |
|-------|---------------|
| Tables | `profiles`, `user_skill_progress`, `user_xp`, `challenges`, `community_videos`, `community_reactions`, `video_comments`, `notifications` |
| Indexes | Hot query paths (user×time, status×time, challenge×score, unread, comments) |
| RLS | Enabled on every table with owner-only / creator-elevated policies |
| Functions / triggers | `handle_new_user`, `toggle_reaction`, both XP triggers, `finalize_challenge`, `finalize_past_challenges`, `handle_new_challenge` |
| Storage policies | Public read + scoped write per user folder (avatars + community-videos) |
| Realtime | Adds `notifications`, `challenges`, `profiles` to the `supabase_realtime` publication |
| pg_cron | Schedules `finalize-past-challenges-weekly` for Monday 00:30 UTC |

---

## 5. Enable realtime on the new tables (dashboard)

`setup.sql` adds the tables to the realtime publication, but the Supabase dashboard surfaces a separate per-table toggle that has to be on too:

- **Database → Publications** → click on **`supabase_realtime`** → toggle ON for:
  - `notifications`
  - `challenges`
  - `profiles`

> Note: the path is **Database → Publications**, *not* Database → Replication.

---

## 6. Verify

Run these in the SQL editor — each should return rows.

```sql
-- Should list challenges, notifications, profiles (and possibly more).
SELECT * FROM pg_publication_tables
  WHERE pubname = 'supabase_realtime';

-- One row for the auto-finalize cron job.
SELECT * FROM cron.job;

-- 8 tables with their RLS policies.
SELECT schemaname, tablename, policyname
  FROM pg_policies
  WHERE schemaname = 'public'
  ORDER BY tablename, policyname;

-- All Rayse RPCs / triggers should be listed.
SELECT proname FROM pg_proc
  WHERE pronamespace = 'public'::regnamespace
  ORDER BY proname;

-- Both buckets should be public.
SELECT id, name, public FROM storage.buckets;
```

---

## 7. Create the first admin (manual)

The signup flow creates a regular profile (free, non-creator). To bootstrap your admin account, sign up via the app once, then run:

```sql
UPDATE public.profiles
   SET is_creator = true,
       is_premium = true
 WHERE email = '<your-email@example.com>';
```

That account can now see the admin panel and create challenges from inside the app.

---

## Common operations (after setup)

### Adding a new weekly challenge
Use the in-app admin: **Profile → Admin Panel → CHALLENGES → CREATE NEW CHALLENGE**. The `handle_new_challenge` trigger fans out a notification to every non-banned user.

### Manually finalizing a challenge
**Profile → Admin Panel → CHALLENGES → tap a past challenge → FINALIZE**. The cron also catches anything you forget every Monday 00:30 UTC.

### Manually re-running auto-finalize
```sql
SELECT public.finalize_past_challenges();
```

### Reverting a finalized challenge (rare)
```sql
UPDATE public.challenges SET finalized_at = NULL WHERE id = '<challenge_id>';
```

### Unscheduling the cron job
```sql
SELECT cron.unschedule('finalize-past-challenges-weekly');
```

### Inspecting cron run history
```sql
SELECT * FROM cron.job_run_details
  ORDER BY start_time DESC
  LIMIT 20;
```

---

## Preparing a demo

Two scripts populate the database with realistic, story-driven data so you can demo every feature without setting anything up manually:

- [`seed_personas.sql`](./seed_personas.sql) — creates 5 named demo accounts + 10 fake community jumpers. **Run once** (or any time you want to wipe & recreate all demo users).
- [`seed_demo_data.sql`](./seed_demo_data.sql) — wipes any prior demo data and reseeds challenges, videos, reactions, comments, and notifications, **anchored to today's ISO week**. **Re-run before every demo** so this week's challenges are always "this week".

### Demo accounts
All use password `212324` (matches the dev password prefilled in `login_screen.dart`).

| Email | Premium | Creator | Mastery | What to demo |
|-------|---------|---------|---------|--------------|
| `admin@rayse.demo`        | yes | **yes** | all 11      | Admin panel: approve pending videos, manage users, create/finalize challenges |
| `advanced@rayse.demo`     | yes | no  | all 11      | Top-tier user: 🥇/🥈/🥉 placements on profile history, big XP, all features unlocked |
| `intermediate@rayse.demo` | yes | no  | tier 0–2    | "FOR YOU" Intermediate tier, eligible to submit double_unders |
| `beginner@rayse.demo`     | yes | no  | tier 0–1    | Eligibility-aware hero, "GO PRACTICE →" for higher tiers |
| `free@rayse.demo`         | no  | no  | basic_bounce | Paywall flows and premium gating |
| `jumper1…jumper10@rayse.demo` | yes | no | mixed | Populates leaderboards and notification fanout |

### What `seed_demo_data.sql` creates
- 3 active-week challenges (Beginner / Intermediate / Advanced), with `week_number` = today's ISO week
- 1 next-week challenge (the upcoming teaser)
- 3 past finalized challenges with realistic placements (advanced placed 1/2/3 in them, populating their profile history)
- ~25 approved challenge videos with varied scores
- **2 pending videos** sitting in the admin queue so you can demo the approval flow
- ~5 personal videos (so the "PERSONAL" pill appears in MY VIDEOS)
- ~80 fire reactions across top videos
- ~7 comments from premium personas
- ~25 notifications mixing read and unread states across all 4 notification types

### One-time bucket setup (so videos actually play)
The seed script makes every demo video point at one shared public URL. To set this up:

1. Dashboard → **Storage → New bucket** → name: `for-demo-only` → **Public bucket: ON** → Create.
2. Upload a short MP4 (≤ 60 seconds) named `for-rayse-demo.mp4` to the root of that bucket.
3. The public URL should be:
   `https://<your-project-ref>.supabase.co/storage/v1/object/public/for-demo-only/for-rayse-demo.mp4`
4. If your project ref differs from the URL hard-coded in `seed_demo_data.sql`, edit the `c_demo_video` constant near the top of the DO block.

When users tap any card in the demo, the same video plays. Cheap, looks real.

### Running the demo seed
```
1. Open Supabase SQL editor
2. Paste contents of seed_personas.sql (one time) → Run
3. Paste contents of seed_demo_data.sql → Run
4. Demo
```

Both scripts are idempotent — safe to re-run.

### Resetting between demos
If you used the app to add real data and want to wipe it before a fresh demo:
```sql
-- Wipe everything from the @rayse.demo accounts (cascades cleanly)
DELETE FROM auth.users WHERE email LIKE '%@rayse.demo';
```
Then re-run both seed scripts.

### When to update the seed scripts
Per [`CLAUDE.md`](../CLAUDE.md): if you ship a new feature that needs data to be visible (e.g., a new notification type, a new admin view, a new on-profile widget), update `seed_demo_data.sql` so the demo always shows the latest feature surface.

---

## Verifying an existing project matches `setup.sql`

If you already have a live Supabase project and want to confirm it matches the schema in `setup.sql` (e.g. after months of ad-hoc dashboard tweaks), run [`audit.sql`](./audit.sql) in the SQL editor. It returns one big table covering every schema-level object: tables, columns, constraints, indexes, RLS state and policies, functions, triggers, extensions, storage buckets, realtime publication, and pg_cron jobs.

Copy the result and diff against `setup.sql`. Anything in the audit that isn't in `setup.sql` is local drift; anything in `setup.sql` that's missing from the audit is something to apply via a focused migration.

If `cron.job` doesn't exist on your project (pg_cron not installed), the `cron_` CTE at the bottom of `audit.sql` will fail — comment out both lines that reference it and rerun.

---

## What's NOT in `setup.sql`

- **Tutorials and daily workouts** — these currently use mock data in `lib/features/{content,workout}/data/`. If you wire them to Supabase later, add the tables to `setup.sql` so future fresh setups pick them up.
- **RevenueCat / payment data** — Phase 7 of the project. When subscriptions ship, they may live in RevenueCat (not the Supabase DB) — verify before adding anything here.
- **Push notification tokens** — only in-app notifications are wired today. If you add APNs/FCM, a `device_tokens` table with the FCM/APNs token per device will be needed.

---

## Troubleshooting

| Problem | Cause / Fix |
|---------|------|
| `ALTER PUBLICATION` fails | Publication `supabase_realtime` doesn't exist yet. Visit Database → Publications once to initialize it, then rerun. |
| `cron.schedule` errors with "schema does not exist" | `pg_cron` not enabled. Enable from Database → Extensions, then rerun the `pg_cron` DO block in `setup.sql`. |
| New users don't get a profile row | `handle_new_user` trigger missing. Confirm with `SELECT tgname FROM pg_trigger WHERE tgname = 'on_auth_user_created'`. |
| Bell badge stays at 0 for a user that has unread rows | Realtime not enabled for the `notifications` table (step 5). Visit Database → Publications → toggle ON. |
| Admin can't create a challenge ("new row violates RLS") | Profile isn't marked as creator. Run the UPDATE from step 7. |
