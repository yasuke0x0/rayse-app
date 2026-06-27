-- ════════════════════════════════════════════════════════════════════════════
-- Rayse — Demo personas seed
-- ════════════════════════════════════════════════════════════════════════════
-- Creates 5 named demo accounts + 10 fake community jumpers.
-- Every account uses email pattern @rayse.ch and password '212324'
-- (matching the dev password prefilled in login_screen.dart).
--
-- Idempotent: re-running drops & recreates every @rayse.ch account.
--
-- Run order:
--   1. supabase/setup.sql   (once on a fresh project)
--   2. supabase/seed_personas.sql   (once, or when you want to wipe demos)
--   3. supabase/seed_demo_data.sql  (before each demo to refresh data)
-- ════════════════════════════════════════════════════════════════════════════


-- Wipe every existing demo account (cascades to profile + everything tied to it).
DELETE FROM auth.users WHERE email LIKE '%@rayse.ch';

-- Wipe legacy @rayse.demo accounts (this domain was used earlier in the
-- project; their profile rows still hold the demo usernames and would
-- collide with the username unique constraint on a fresh seed run).
DELETE FROM auth.users WHERE email LIKE '%@rayse.demo';

-- Belt-and-suspenders: wipe any profile rows that lost their auth user
-- somehow (FK cascade may not be installed on the live DB).
DELETE FROM public.profiles WHERE id NOT IN (SELECT id FROM auth.users);

-- The community_videos.reviewed_by FK on the live DB may be RESTRICT
-- instead of SET NULL. NULL out any reference that points at a profile
-- we're about to delete so the DELETE doesn't trip the FK.
UPDATE public.community_videos
   SET reviewed_by = NULL
 WHERE reviewed_by IN (
   SELECT id FROM public.profiles
    WHERE id NOT IN (SELECT id FROM auth.users)
       OR username IN (
         'demo_admin','ava_pro','ian_mid','beth_beg','finn_free',
         'sam1','jordan2','riley3','casey4','morgan5',
         'taylor6','pat7','quinn8','cameron9','drew10'
       )
 );

-- Final safety: free up any profile row still holding one of the demo
-- usernames so the rayse_seed_user UPDATE can claim it.
DELETE FROM public.profiles WHERE username IN (
  'demo_admin','ava_pro','ian_mid','beth_beg','finn_free',
  'sam1','jordan2','riley3','casey4','morgan5',
  'taylor6','pat7','quinn8','cameron9','drew10'
);


-- ─── Helper: create a demo auth user + return its UUID ─────────────────────
CREATE OR REPLACE FUNCTION public.rayse_seed_user(
  p_email      text,
  p_password   text,
  p_first      text,
  p_last       text,
  p_username   text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_user_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users (
    instance_id, id, aud, role,
    email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, created_at, updated_at,
    confirmation_token, recovery_token,
    email_change_token_new, email_change, email_change_token_current
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
    p_email,
    extensions.crypt(p_password, extensions.gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    false, now(), now(),
    '', '', '', '', ''
  );

  -- handle_new_user trigger has already inserted a profiles row.
  -- Patch it with the persona's real names and chosen username.
  UPDATE public.profiles
     SET first_name = p_first,
         last_name  = p_last,
         username   = p_username
   WHERE id = v_user_id;

  RETURN v_user_id;
END $$;


-- ─── Helper: set premium/creator flags ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.rayse_seed_role(
  p_user_id   uuid,
  p_premium   boolean,
  p_creator   boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
     SET is_premium = p_premium,
         is_creator = p_creator
   WHERE id = p_user_id;
END $$;


-- ─── Helper: master a list of skills and set total XP ──────────────────────
CREATE OR REPLACE FUNCTION public.rayse_seed_progress(
  p_user_id   uuid,
  p_skill_ids text[],
  p_total_xp  integer
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_skill text;
BEGIN
  FOREACH v_skill IN ARRAY p_skill_ids LOOP
    INSERT INTO public.user_skill_progress
      (user_id, skill_id, sessions_completed, status, updated_at)
    VALUES
      (p_user_id, v_skill, 3, 'mastered', now())
    ON CONFLICT (user_id, skill_id) DO UPDATE
      SET sessions_completed = EXCLUDED.sessions_completed,
          status             = EXCLUDED.status,
          updated_at         = EXCLUDED.updated_at;
  END LOOP;

  INSERT INTO public.user_xp (user_id, total_xp, updated_at)
  VALUES (p_user_id, p_total_xp, now())
  ON CONFLICT (user_id) DO UPDATE
    SET total_xp   = EXCLUDED.total_xp,
        updated_at = EXCLUDED.updated_at;
END $$;


-- ════════════════════════════════════════════════════════════════════════════
-- CREATE THE 5 NAMED PERSONAS
-- ════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_admin        uuid;
  v_advanced     uuid;
  v_intermediate uuid;
  v_beginner     uuid;
  v_free         uuid;

  c_tier01 text[] := ARRAY['basic_bounce','forward_jump','backward_jump','alt_steps'];
  c_tier2  text[] := ARRAY['double_unders','cross_overs','side_swing'];
  c_tier34 text[] := ARRAY['triple_unders','cross_double','releases','freestyle'];
  c_allskills text[] := ARRAY[
    'basic_bounce','forward_jump','backward_jump','alt_steps',
    'double_unders','cross_overs','side_swing',
    'triple_unders','cross_double','releases','freestyle'
  ];
BEGIN
  -- admin@rayse.ch — premium + creator, fully mastered
  v_admin := public.rayse_seed_user('admin@rayse.ch',        '212324', 'Demo', 'Admin',        'demo_admin');
  PERFORM public.rayse_seed_role(v_admin,        true, true);
  PERFORM public.rayse_seed_progress(v_admin,    c_allskills, 1500);

  -- advanced@rayse.ch — premium, fully mastered (no admin)
  v_advanced := public.rayse_seed_user('advanced@rayse.ch',  '212324', 'Ava',  'Advanced',     'ava_pro');
  PERFORM public.rayse_seed_role(v_advanced,     true, false);
  PERFORM public.rayse_seed_progress(v_advanced, c_allskills, 1475);

  -- intermediate@rayse.ch — premium, tier 0-2 mastered
  v_intermediate := public.rayse_seed_user('intermediate@rayse.ch', '212324', 'Ian', 'Intermediate', 'ian_mid');
  PERFORM public.rayse_seed_role(v_intermediate, true, false);
  PERFORM public.rayse_seed_progress(v_intermediate, c_tier01 || c_tier2, 675);

  -- beginner@rayse.ch — premium, tier 0-1 mastered
  v_beginner := public.rayse_seed_user('beginner@rayse.ch',  '212324', 'Beth', 'Beginner',     'beth_beg');
  PERFORM public.rayse_seed_role(v_beginner,     true, false);
  PERFORM public.rayse_seed_progress(v_beginner, c_tier01, 275);

  -- free@rayse.ch — free, only basic_bounce mastered
  v_free := public.rayse_seed_user('free@rayse.ch',          '212324', 'Finn', 'Free',         'finn_free');
  PERFORM public.rayse_seed_role(v_free,         false, false);
  PERFORM public.rayse_seed_progress(v_free,     ARRAY['basic_bounce'], 50);
END $$;


-- ════════════════════════════════════════════════════════════════════════════
-- CREATE 10 FAKE COMMUNITY JUMPERS (populate leaderboards)
-- ════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  v_id     uuid;
  v_email  text;
  v_first  text;
  v_user   text;
  v_tier   integer;
  c_tier01    text[] := ARRAY['basic_bounce','forward_jump','backward_jump','alt_steps'];
  c_through2  text[] := ARRAY['basic_bounce','forward_jump','backward_jump','alt_steps',
                              'double_unders','cross_overs','side_swing'];
  c_all       text[] := ARRAY['basic_bounce','forward_jump','backward_jump','alt_steps',
                              'double_unders','cross_overs','side_swing',
                              'triple_unders','cross_double','releases','freestyle'];
  c_firstnames text[] := ARRAY['Sam','Jordan','Riley','Casey','Morgan','Taylor','Pat','Quinn','Cameron','Drew'];
BEGIN
  FOR i IN 1..10 LOOP
    v_email := 'jumper' || i || '@rayse.ch';
    v_first := c_firstnames[i];
    v_user  := LOWER(v_first) || i;
    v_id    := public.rayse_seed_user(v_email, '212324', v_first, 'J' || i, v_user);

    -- Mix of tiers: 4 beginners, 3 intermediates, 3 advanced
    PERFORM public.rayse_seed_role(v_id, true, false);
    IF i <= 4 THEN
      v_tier := 1;
      PERFORM public.rayse_seed_progress(v_id, c_tier01,   200 + i * 25);
    ELSIF i <= 7 THEN
      v_tier := 2;
      PERFORM public.rayse_seed_progress(v_id, c_through2, 600 + i * 50);
    ELSE
      v_tier := 3;
      PERFORM public.rayse_seed_progress(v_id, c_all,     1300 + i * 25);
    END IF;
  END LOOP;
END $$;


-- Helper functions are kept around so seed_demo_data.sql can reuse them
-- (rayse_seed_progress in particular is handy if you ever extend personas).
-- If you want to clean them up, run:
--   DROP FUNCTION public.rayse_seed_user(text, text, text, text, text);
--   DROP FUNCTION public.rayse_seed_role(uuid, boolean, boolean);
--   DROP FUNCTION public.rayse_seed_progress(uuid, text[], integer);
