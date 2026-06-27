-- ════════════════════════════════════════════════════════════════════════════
-- Rayse — Supabase schema
-- ════════════════════════════════════════════════════════════════════════════
-- Setup instructions and verification queries: see ./SETUP.md
-- Runnable top-to-bottom on a fresh project. Idempotent (safe to re-run).
-- Reflects live production schema as of 2026-06-27.
-- ════════════════════════════════════════════════════════════════════════════


-- ─── EXTENSIONS ─────────────────────────────────────────────────────────────
-- pg_cron must be enabled separately from the dashboard (see SETUP.md).
-- Supabase convention: extensions live in the `extensions` schema, not public.
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto    WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


-- ════════════════════════════════════════════════════════════════════════════
-- TABLES (created in FK dependency order)
-- ════════════════════════════════════════════════════════════════════════════

-- ─── profiles ──────────────────────────────────────────────────────────────
-- One row per auth.users row, auto-created by handle_new_user trigger.
CREATE TABLE IF NOT EXISTS public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text,
  username    text,
  first_name  text NOT NULL DEFAULT '',
  last_name   text NOT NULL DEFAULT '',
  avatar_url  text,
  is_premium  boolean DEFAULT false,
  is_creator  boolean NOT NULL DEFAULT false,
  is_banned   boolean NOT NULL DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

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
-- Has its own surrogate id PK, with a UNIQUE constraint on (user_id, skill_id).
CREATE TABLE IF NOT EXISTS public.user_skill_progress (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  skill_id            text NOT NULL,
  sessions_completed  integer NOT NULL DEFAULT 0,
  status              text NOT NULL DEFAULT 'locked',
  updated_at          timestamptz DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
      WHERE conname = 'user_skill_progress_user_id_skill_id_key'
  ) THEN
    ALTER TABLE public.user_skill_progress
      ADD CONSTRAINT user_skill_progress_user_id_skill_id_key
        UNIQUE (user_id, skill_id);
  END IF;
END $$;


-- ─── user_xp ───────────────────────────────────────────────────────────────
-- One row per user holding cumulative XP.
CREATE TABLE IF NOT EXISTS public.user_xp (
  user_id    uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  total_xp   integer NOT NULL DEFAULT 0,
  updated_at timestamptz DEFAULT now()
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
  created_at    timestamptz DEFAULT now(),
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
  status        text NOT NULL DEFAULT 'pending',
  is_challenge  boolean NOT NULL DEFAULT false,
  week_number   integer NOT NULL,
  week_year     integer NOT NULL,
  score         integer NOT NULL DEFAULT 0,
  xp_awarded    boolean NOT NULL DEFAULT false,
  reviewed_by   uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  reviewed_at   timestamptz,
  submitted_at  timestamptz DEFAULT now()
);


-- ─── community_reactions ───────────────────────────────────────────────────
-- One row per (user, video) pair representing a 🔥 reaction.
-- Score on community_videos is the count of these rows for that video.
CREATE TABLE IF NOT EXISTS public.community_reactions (
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  video_id   uuid NOT NULL REFERENCES public.community_videos(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, video_id)
);


-- ─── video_comments ────────────────────────────────────────────────────────
-- Comments on challenge videos. The extra named FK
-- (video_comments_user_id_profiles_fkey) is what PostgREST uses in the
-- `profiles!video_comments_user_id_profiles_fkey(username)` join syntax.
CREATE TABLE IF NOT EXISTS public.video_comments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id   uuid NOT NULL REFERENCES public.community_videos(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body       text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
      WHERE conname = 'video_comments_user_id_profiles_fkey'
  ) THEN
    ALTER TABLE public.video_comments
      ADD CONSTRAINT video_comments_user_id_profiles_fkey
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
      WHERE conname = 'video_comments_body_check'
  ) THEN
    ALTER TABLE public.video_comments
      ADD CONSTRAINT video_comments_body_check
        CHECK (length(body) > 0);
  END IF;
END $$;


-- ─── notifications ─────────────────────────────────────────────────────────
-- In-app notifications. Type values currently used:
--   'comment', 'challenge_new', 'challenge_approved', 'challenge_placed'
CREATE TABLE IF NOT EXISTS public.notifications (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type       text NOT NULL DEFAULT 'comment',
  title      text NOT NULL,
  body       text NOT NULL,
  data       jsonb DEFAULT '{}'::jsonb,
  is_read    boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);


-- ════════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ════════════════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON public.notifications (user_id, is_read) WHERE is_read = false;

CREATE INDEX IF NOT EXISTS idx_video_comments_video_id
  ON public.video_comments (video_id);
CREATE INDEX IF NOT EXISTS idx_video_comments_created_at
  ON public.video_comments (created_at);

CREATE INDEX IF NOT EXISTS community_videos_user_idx
  ON public.community_videos (user_id, submitted_at DESC);
CREATE INDEX IF NOT EXISTS community_videos_status_idx
  ON public.community_videos (status, submitted_at DESC);
CREATE INDEX IF NOT EXISTS community_videos_challenge_week_idx
  ON public.community_videos (is_challenge, skill_id, week_number, week_year, score DESC);

CREATE INDEX IF NOT EXISTS challenges_week_idx
  ON public.challenges (week_year DESC, week_number DESC);


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
DROP POLICY IF EXISTS "Profiles viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins update profiles" ON public.profiles;
CREATE POLICY "Admins update profiles" ON public.profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.is_creator = true
    )
  );


-- ─── user_skill_progress policies ──────────────────────────────────────────
DROP POLICY IF EXISTS "Users can manage own skill progress" ON public.user_skill_progress;
CREATE POLICY "Users can manage own skill progress" ON public.user_skill_progress
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "skill_progress_creator_read" ON public.user_skill_progress;
CREATE POLICY "skill_progress_creator_read" ON public.user_skill_progress
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── user_xp policies ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can manage own xp" ON public.user_xp;
CREATE POLICY "Users can manage own xp" ON public.user_xp
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_xp_creator_read" ON public.user_xp;
CREATE POLICY "user_xp_creator_read" ON public.user_xp
  FOR SELECT TO authenticated USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── challenges policies ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "Challenges are viewable by everyone" ON public.challenges;
CREATE POLICY "Challenges are viewable by everyone" ON public.challenges
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Creators can insert challenges" ON public.challenges;
CREATE POLICY "Creators can insert challenges" ON public.challenges
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

DROP POLICY IF EXISTS "Creators can update challenges" ON public.challenges;
CREATE POLICY "Creators can update challenges" ON public.challenges
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

DROP POLICY IF EXISTS "Creators can delete challenges" ON public.challenges;
CREATE POLICY "Creators can delete challenges" ON public.challenges
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── community_videos policies ─────────────────────────────────────────────
-- SELECT: own videos, approved challenge videos, or admin.
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

DROP POLICY IF EXISTS "Users can insert own videos" ON public.community_videos;
CREATE POLICY "Users can insert own videos" ON public.community_videos
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE: owner OR admin (combined policy).
DROP POLICY IF EXISTS "Creators can update any video" ON public.community_videos;
CREATE POLICY "Creators can update any video" ON public.community_videos
  FOR UPDATE
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );

-- Redundant secondary UPDATE policy that exists in live (kept for parity).
DROP POLICY IF EXISTS "Admins update videos" ON public.community_videos;
CREATE POLICY "Admins update videos" ON public.community_videos
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── community_reactions policies ──────────────────────────────────────────
DROP POLICY IF EXISTS "Read reactions" ON public.community_reactions;
CREATE POLICY "Read reactions" ON public.community_reactions
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Manage own reactions" ON public.community_reactions;
CREATE POLICY "Manage own reactions" ON public.community_reactions
  FOR ALL USING (auth.uid() = user_id);


-- ─── video_comments policies ───────────────────────────────────────────────
DROP POLICY IF EXISTS "Anyone can read comments" ON public.video_comments;
CREATE POLICY "Anyone can read comments" ON public.video_comments
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Premium users can insert comments" ON public.video_comments;
CREATE POLICY "Premium users can insert comments" ON public.video_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND (is_premium = true OR is_creator = true)
    )
  );

DROP POLICY IF EXISTS "Users can delete own comments" ON public.video_comments;
CREATE POLICY "Users can delete own comments" ON public.video_comments
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can delete any comment" ON public.video_comments;
CREATE POLICY "Admins can delete any comment" ON public.video_comments
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_creator = true
    )
  );


-- ─── notifications policies ────────────────────────────────────────────────
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
CREATE POLICY "Users can read own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Open INSERT policy: needed because the comment flow inserts a notification
-- for the video owner (a different user). All other inserts come from
-- SECURITY DEFINER triggers.
DROP POLICY IF EXISTS "Authenticated users can insert notificatio" ON public.notifications;
CREATE POLICY "Authenticated users can insert notificatio" ON public.notifications
  FOR INSERT WITH CHECK (true);


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
-- Locked once the matching challenge is finalized (so leaderboard ranks
-- match the XP/badges that were awarded at finalize time).
CREATE OR REPLACE FUNCTION public.toggle_reaction(p_video_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id      uuid := auth.uid();
  v_found        boolean;
  v_is_challenge boolean;
  v_skill_id     text;
  v_wk           integer;
  v_yr           integer;
  v_finalized    timestamptz;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Look up the video's challenge identity and reject if the challenge is finalized.
  SELECT is_challenge, skill_id, week_number, week_year
    INTO v_is_challenge, v_skill_id, v_wk, v_yr
    FROM public.community_videos
   WHERE id = p_video_id;

  IF v_is_challenge THEN
    SELECT finalized_at INTO v_finalized
      FROM public.challenges
     WHERE skill_id = v_skill_id
       AND week_number = v_wk
       AND week_year   = v_yr
     LIMIT 1;
    IF v_finalized IS NOT NULL THEN
      RAISE EXCEPTION 'Challenge finalized — reactions are locked'
        USING ERRCODE = 'P0001';
    END IF;
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
-- STORAGE BUCKET POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Buckets `avatars` and `community-videos` must be created in the dashboard
-- (public). See SETUP.md.

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
DROP POLICY IF EXISTS "Anyone can view community videos" ON storage.objects;
CREATE POLICY "Anyone can view community videos" ON storage.objects
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
-- Per-table toggles in Database → Publications → supabase_realtime may also
-- need to be flipped on (see SETUP.md).

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

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) THEN
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
-- End of schema. See ./SETUP.md for verification queries and admin bootstrap.
-- ════════════════════════════════════════════════════════════════════════════
