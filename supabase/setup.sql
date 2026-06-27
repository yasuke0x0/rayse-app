-- ════════════════════════════════════════════════════════════════════════════
-- RAYSE — Supabase setup
-- ════════════════════════════════════════════════════════════════════════════
-- Runnable top-to-bottom in the Supabase SQL editor on a FRESH project.
-- Idempotent where possible (CREATE OR REPLACE / IF NOT EXISTS).
--
-- Before running:
--   1. Enable pg_cron from Supabase dashboard → Database → Extensions
--      (cannot be enabled via SQL on most tiers).
--   2. Create two storage buckets from Supabase dashboard → Storage:
--        - 'avatars'          (public)
--        - 'community-videos' (public)
--      Storage policies are set further down this file.
--
-- After running:
--   - Confirm Supabase Database → Replication has these tables published on
--     supabase_realtime: notifications, challenges, profiles
--     (the script ALTER PUBLICATION calls below should handle it, but verify).
--   - Confirm cron job is registered: SELECT * FROM cron.job;
-- ════════════════════════════════════════════════════════════════════════════


-- ─── EXTENSIONS ─────────────────────────────────────────────────────────────

-- pg_cron is enabled via the dashboard (see note above).
-- pgcrypto provides gen_random_uuid() (usually pre-installed).
CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ════════════════════════════════════════════════════════════════════════════
-- TABLES (created in FK dependency order)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── profiles ──────────────────────────────────────────────────────────────
-- One row per auth.users row, auto-created by handle_new_user trigger.
CREATE TABLE IF NOT EXISTS public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text,
  username    text NOT NULL DEFAULT '',
  first_name  text NOT NULL DEFAULT '',
  last_name   text NOT NULL DEFAULT '',
  avatar_url  text,
  is_premium  boolean NOT NULL DEFAULT false,
  is_creator  boolean NOT NULL DEFAULT false,
  is_banned   boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- Unique constraint on username (skipped via SET CONSTRAINTS during signup)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_username_unique'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_username_unique UNIQUE (username);
  END IF;
END $$;


-- ─── user_skill_progress ───────────────────────────────────────────────────
-- One row per (user, skill) pair tracking practice sessions and mastery.
CREATE TABLE IF NOT EXISTS public.user_skill_progress (
  user_id            uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skill_id           text NOT NULL,
  sessions_completed integer NOT NULL DEFAULT 0,
  status             text NOT NULL DEFAULT 'available'
                     CHECK (status IN ('locked', 'available', 'completed', 'mastered')),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, skill_id)
);


-- ─── user_xp ───────────────────────────────────────────────────────────────
-- One row per user holding cumulative XP.
CREATE TABLE IF NOT EXISTS public.user_xp (
  user_id    uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_xp   integer NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);


-- ─── challenges ────────────────────────────────────────────────────────────
-- Weekly skill challenges. One per (skill, week, year) by constraint.
CREATE TABLE IF NOT EXISTS public.challenges (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  skill_id      text NOT NULL,
  title         text NOT NULL,
  description   text NOT NULL,
  week_number   integer NOT NULL,
  week_year     integer NOT NULL,
  xp_reward     integer NOT NULL DEFAULT 50,
  finalized_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT challenges_skill_id_week UNIQUE (skill_id, week_number, week_year)
);


-- ─── community_videos ──────────────────────────────────────────────────────
-- Combined table for personal recordings and challenge submissions.
-- Distinguished by `is_challenge`. Personal videos are auto-approved+private;
-- challenge videos go through admin review and appear on leaderboards.
CREATE TABLE IF NOT EXISTS public.community_videos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skill_id      text NOT NULL,
  video_url     text NOT NULL,
  title         text NOT NULL DEFAULT '',
  caption       text NOT NULL DEFAULT '',
  notes         text NOT NULL DEFAULT '',
  status        text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'rejected')),
  is_challenge  boolean NOT NULL DEFAULT false,
  week_number   integer NOT NULL,
  week_year     integer NOT NULL,
  score         integer NOT NULL DEFAULT 0,
  xp_awarded    boolean NOT NULL DEFAULT false,
  reviewed_by   uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at   timestamptz,
  submitted_at  timestamptz NOT NULL DEFAULT now()
);


-- ─── community_reactions ───────────────────────────────────────────────────
-- One row per (user, video) pair representing a 🔥 reaction.
-- Score on community_videos is the count of these rows for that video.
CREATE TABLE IF NOT EXISTS public.community_reactions (
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  video_id   uuid NOT NULL REFERENCES public.community_videos(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, video_id)
);


-- ─── video_comments ────────────────────────────────────────────────────────
-- Comments on challenge videos (personal videos don't show comments in UI).
CREATE TABLE IF NOT EXISTS public.video_comments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id   uuid NOT NULL REFERENCES public.community_videos(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);


-- ─── notifications ─────────────────────────────────────────────────────────
-- In-app notifications. Type values currently used:
--   'comment', 'challenge_new', 'challenge_approved', 'challenge_placed'
CREATE TABLE IF NOT EXISTS public.notifications (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type       text NOT NULL DEFAULT 'comment',
  title      text NOT NULL,
  body       text NOT NULL,
  data       jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_read    boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);


-- ════════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ════════════════════════════════════════════════════════════════════════════

-- Speed up the most common filter combinations.
CREATE INDEX IF NOT EXISTS community_videos_user_idx
  ON public.community_videos (user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS community_videos_status_idx
  ON public.community_videos (status, submitted_at DESC);
CREATE INDEX IF NOT EXISTS community_videos_challenge_week_idx
  ON public.community_videos (is_challenge, skill_id, week_number, week_year, score DESC);

CREATE INDEX IF NOT EXISTS challenges_week_idx
  ON public.challenges (week_year DESC, week_number DESC);

CREATE INDEX IF NOT EXISTS notifications_user_unread_idx
  ON public.notifications (user_id, is_read, created_at DESC);

CREATE INDEX IF NOT EXISTS video_comments_video_idx
  ON public.video_comments (video_id, created_at);


-- ════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ════════════════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_skill_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_xp             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_videos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_comments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications       ENABLE ROW LEVEL SECURITY;


-- ─── profiles policies ─────────────────────────────────────────────────────
-- Read: any authenticated user can see any profile (needed for username joins
-- in leaderboards, comments, etc.). If you want to hide banned users from
-- search, drop this and replace with a NOT is_banned policy.
DROP POLICY IF EXISTS "profiles_read_all" ON public.profiles;
CREATE POLICY "profiles_read_all" ON public.profiles
  FOR SELECT TO authenticated USING (true);

-- Update: users can update their own row.
DROP POLICY IF EXISTS "profiles_update_self" ON public.profiles;
CREATE POLICY "profiles_update_self" ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Insert: only via the handle_new_user trigger (SECURITY DEFINER). No direct
-- policy needed because trigger bypasses RLS.


-- ─── user_skill_progress policies ──────────────────────────────────────────
DROP POLICY IF EXISTS "skill_progress_self_all" ON public.user_skill_progress;
CREATE POLICY "skill_progress_self_all" ON public.user_skill_progress
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Creators can read everyone's progress (for the admin user detail screen).
DROP POLICY IF EXISTS "skill_progress_creator_read" ON public.user_skill_progress;
CREATE POLICY "skill_progress_creator_read" ON public.user_skill_progress
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── user_xp policies ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "user_xp_self_read_update" ON public.user_xp;
CREATE POLICY "user_xp_self_read_update" ON public.user_xp
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "user_xp_creator_read" ON public.user_xp;
CREATE POLICY "user_xp_creator_read" ON public.user_xp
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );
-- XP awards from triggers are SECURITY DEFINER so they bypass these policies.


-- ─── challenges policies ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "challenges_read_all" ON public.challenges;
CREATE POLICY "challenges_read_all" ON public.challenges
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "challenges_creator_insert" ON public.challenges;
CREATE POLICY "challenges_creator_insert" ON public.challenges
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

DROP POLICY IF EXISTS "challenges_creator_update" ON public.challenges;
CREATE POLICY "challenges_creator_update" ON public.challenges
  FOR UPDATE TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

DROP POLICY IF EXISTS "challenges_creator_delete" ON public.challenges;
CREATE POLICY "challenges_creator_delete" ON public.challenges
  FOR DELETE TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── community_videos policies ─────────────────────────────────────────────
-- Read: own videos always; approved challenge videos to everyone; creators see
-- all. Personal videos by other users are not visible.
DROP POLICY IF EXISTS "community_videos_read" ON public.community_videos;
CREATE POLICY "community_videos_read" ON public.community_videos
  FOR SELECT TO authenticated USING (
    user_id = auth.uid()
    OR (is_challenge = true AND status = 'approved')
    OR EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

-- Insert: only your own video.
DROP POLICY IF EXISTS "community_videos_self_insert" ON public.community_videos;
CREATE POLICY "community_videos_self_insert" ON public.community_videos
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Update: owner can edit title/notes; creators can change any column.
DROP POLICY IF EXISTS "community_videos_self_update" ON public.community_videos;
CREATE POLICY "community_videos_self_update" ON public.community_videos
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "community_videos_creator_update" ON public.community_videos;
CREATE POLICY "community_videos_creator_update" ON public.community_videos
  FOR UPDATE TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

-- Delete: creator only (admins moderate).
DROP POLICY IF EXISTS "community_videos_creator_delete" ON public.community_videos;
CREATE POLICY "community_videos_creator_delete" ON public.community_videos
  FOR DELETE TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── community_reactions policies ──────────────────────────────────────────
-- Read: own reactions (used to derive "did I fire this video"). All writes go
-- through the toggle_reaction RPC (SECURITY DEFINER), so no insert/delete
-- policy is needed for direct client writes.
DROP POLICY IF EXISTS "community_reactions_self_read" ON public.community_reactions;
CREATE POLICY "community_reactions_self_read" ON public.community_reactions
  FOR SELECT TO authenticated USING (user_id = auth.uid());


-- ─── video_comments policies ───────────────────────────────────────────────
DROP POLICY IF EXISTS "video_comments_read_all" ON public.video_comments;
CREATE POLICY "video_comments_read_all" ON public.video_comments
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "video_comments_self_insert" ON public.video_comments;
CREATE POLICY "video_comments_self_insert" ON public.video_comments
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Delete: own comment or creator.
DROP POLICY IF EXISTS "video_comments_delete" ON public.video_comments;
CREATE POLICY "video_comments_delete" ON public.video_comments
  FOR DELETE TO authenticated USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── notifications policies ────────────────────────────────────────────────
-- Read: only your own notifications.
DROP POLICY IF EXISTS "notifications_self_read" ON public.notifications;
CREATE POLICY "notifications_self_read" ON public.notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- Update: only your own notifications (for mark-as-read).
DROP POLICY IF EXISTS "notifications_self_update" ON public.notifications;
CREATE POLICY "notifications_self_update" ON public.notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Insert: open to any authenticated user. Required because the comment flow
-- inserts a notification for the video owner (different user). All other
-- inserts happen via SECURITY DEFINER triggers. If this is too permissive for
-- you, move the comment notification into a SECURITY DEFINER RPC and remove
-- this policy.
DROP POLICY IF EXISTS "notifications_authenticated_insert" ON public.notifications;
CREATE POLICY "notifications_authenticated_insert" ON public.notifications
  FOR INSERT TO authenticated WITH CHECK (true);


-- ════════════════════════════════════════════════════════════════════════════
-- FUNCTIONS, TRIGGERS, AND RPCs
-- ════════════════════════════════════════════════════════════════════════════

-- ─── handle_new_user ───────────────────────────────────────────────────────
-- Create a matching profiles row whenever a new auth.users row is created.
-- Signup screen then UPDATEs first_name, last_name, username. Default username
-- is unique-ish so the unique constraint doesn't reject the auto-create.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    SPLIT_PART(COALESCE(NEW.email, ''), '@', 1) || '_' || SUBSTRING(NEW.id::text, 1, 4),
    NEW.created_at
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ─── toggle_reaction RPC ───────────────────────────────────────────────────
-- Atomically toggle a 🔥 reaction on a video AND adjust the cached score.
-- Returns true if the reaction was added, false if removed.
CREATE OR REPLACE FUNCTION public.toggle_reaction(p_video_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_found   boolean;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.community_reactions
      WHERE user_id = v_user_id AND video_id = p_video_id
  ) INTO v_found;

  IF v_found THEN
    DELETE FROM public.community_reactions
      WHERE user_id = v_user_id AND video_id = p_video_id;
    UPDATE public.community_videos
      SET score = GREATEST(score - 1, 0)
      WHERE id = p_video_id;
    RETURN false;
  ELSE
    INSERT INTO public.community_reactions (user_id, video_id)
      VALUES (v_user_id, p_video_id);
    UPDATE public.community_videos
      SET score = score + 1
      WHERE id = p_video_id;
    RETURN true;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_reaction(uuid) TO authenticated;


-- ─── XP triggers ───────────────────────────────────────────────────────────

-- +25 XP when a challenge video is submitted (any insert with is_challenge=true).
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
END;
$$;

DROP TRIGGER IF EXISTS challenge_video_submit_trigger ON public.community_videos;
CREATE TRIGGER challenge_video_submit_trigger
  AFTER INSERT ON public.community_videos
  FOR EACH ROW EXECUTE FUNCTION public.handle_challenge_video_submit();


-- +challenge.xp_reward XP + notification when a challenge video is approved.
-- BEFORE UPDATE so we can flip xp_awarded=true on the same row.
CREATE OR REPLACE FUNCTION public.handle_challenge_video_approval()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_reward integer;
BEGIN
  IF NEW.is_challenge = true
     AND NEW.status = 'approved'
     AND (OLD.status IS NULL OR OLD.status != 'approved')
     AND NEW.xp_awarded = false THEN
    SELECT xp_reward INTO v_reward
      FROM public.challenges
      WHERE skill_id = NEW.skill_id
        AND week_number = NEW.week_number
        AND week_year  = NEW.week_year
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
END;
$$;

DROP TRIGGER IF EXISTS challenge_video_approval_trigger ON public.community_videos;
CREATE TRIGGER challenge_video_approval_trigger
  BEFORE UPDATE OF status ON public.community_videos
  FOR EACH ROW EXECUTE FUNCTION public.handle_challenge_video_approval();


-- ─── finalize_challenge RPC + cron wrapper ─────────────────────────────────

-- Award top-3 XP bonus + notifications, set finalized_at.
-- Idempotent: short-circuits if challenge is already finalized.
CREATE OR REPLACE FUNCTION public.finalize_challenge(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_challenge record;
  v_row       record;
  v_rank      integer := 0;
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
        AND week_year  = v_challenge.week_year
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
        ELSE       '🥉 You placed #3!'
      END,
      'You earned a +' || v_challenge.xp_reward || ' XP bonus on "' || v_challenge.title || '"',
      jsonb_build_object('challenge_id', p_challenge_id, 'rank', v_rank, 'xp', v_challenge.xp_reward)
    );
  END LOOP;

  UPDATE public.challenges SET finalized_at = now() WHERE id = p_challenge_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.finalize_challenge(uuid) TO authenticated;


-- Wrapper for pg_cron: finalize all past unfinalized challenges.
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
END;
$$;


-- ─── New-challenge-drop notification ───────────────────────────────────────
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
      'challenge_id',  NEW.id,
      'skill_id',      NEW.skill_id,
      'week_number',   NEW.week_number,
      'week_year',     NEW.week_year
    )
  FROM public.profiles p
  WHERE p.is_banned IS DISTINCT FROM true;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS challenge_new_trigger ON public.challenges;
CREATE TRIGGER challenge_new_trigger
  AFTER INSERT ON public.challenges
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_challenge();


-- ════════════════════════════════════════════════════════════════════════════
-- STORAGE BUCKETS + POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Buckets themselves must be created in the dashboard FIRST (see header).
-- Policies below allow the right people to read/write.

-- ─── avatars bucket ────────────────────────────────────────────────────────
-- Path convention: <user_id>/avatar.<ext>
DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_self_write" ON storage.objects;
CREATE POLICY "avatars_self_write" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "avatars_self_update" ON storage.objects;
CREATE POLICY "avatars_self_update" ON storage.objects
  FOR UPDATE TO authenticated USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- ─── community-videos bucket ───────────────────────────────────────────────
-- Path convention: <user_id>/<skill_id>/<timestamp>.<ext>
DROP POLICY IF EXISTS "community_videos_public_read" ON storage.objects;
CREATE POLICY "community_videos_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'community-videos');

DROP POLICY IF EXISTS "community_videos_self_write" ON storage.objects;
CREATE POLICY "community_videos_self_write" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'community-videos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );


-- ════════════════════════════════════════════════════════════════════════════
-- REALTIME PUBLICATION
-- ════════════════════════════════════════════════════════════════════════════
-- The app uses supabase realtime streams on these tables. Some Supabase tiers
-- require enabling Replication via dashboard if these ALTER statements fail.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = 'challenges'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.challenges';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime' AND tablename = 'profiles'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles';
  END IF;
END $$;


-- ════════════════════════════════════════════════════════════════════════════
-- PG_CRON SCHEDULE
-- ════════════════════════════════════════════════════════════════════════════
-- Auto-finalize past unfinalized challenges every Monday at 00:30 UTC.
-- Skipped quietly if pg_cron isn't installed yet.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
    -- Unschedule any previous version, then re-add.
    PERFORM cron.unschedule(jobid)
      FROM cron.job WHERE jobname = 'finalize-past-challenges-weekly';
    PERFORM cron.schedule(
      'finalize-past-challenges-weekly',
      '30 0 * * 1',
      $cmd$SELECT public.finalize_past_challenges();$cmd$
    );
  ELSE
    RAISE NOTICE
      'pg_cron not installed — auto-finalize cron not scheduled. '
      'Enable pg_cron in Supabase dashboard (Database → Extensions) and rerun this DO block.';
  END IF;
END $$;


-- ════════════════════════════════════════════════════════════════════════════
-- DONE
-- ════════════════════════════════════════════════════════════════════════════
-- Quick sanity checks:
--   SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
--   SELECT * FROM cron.job;
--   SELECT * FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename;
--   SELECT proname FROM pg_proc WHERE pronamespace = 'public'::regnamespace
--     ORDER BY proname;
-- ════════════════════════════════════════════════════════════════════════════
