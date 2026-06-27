-- ════════════════════════════════════════════════════════════════════════════
-- Rayse — Demo data seed (dynamic week-aware)
-- ════════════════════════════════════════════════════════════════════════════
-- Wipes any prior demo-account data and reseeds:
--   - 3 active-week challenges (one per tier)
--   - 1 next-week challenge (upcoming teaser)
--   - 3 finalized past challenges (winner spotlight + history)
--   - ~25 challenge videos (mostly approved, 2 pending for admin queue)
--   - ~5 personal videos
--   - ~80 fire reactions on top videos
--   - ~12 comments
--   - ~25 notifications (mix of read + unread)
--
-- Idempotent: re-running gives the same clean demo state, freshly anchored to
-- TODAY'S ISO week.
--
-- Prereqs:
--   - supabase/setup.sql       was run on the project
--   - supabase/seed_personas.sql was run (the 5 named + 10 jumper accounts exist)
--   - Storage bucket `for-demo-only` (public) exists with a file
--     `for-rayse-demo.mp4` at its root. All seeded videos reuse this same
--     playable URL so the demo actually plays a video when you tap any card.
--     Change c_demo_video below if you swap the file/bucket.
-- ════════════════════════════════════════════════════════════════════════════


-- ─── Helper: ISO (week, year) for `now() + offset weeks` ───────────────────
CREATE OR REPLACE FUNCTION public.rayse_seed_week(p_offset integer)
RETURNS TABLE(wk integer, yr integer) LANGUAGE plpgsql AS $$
DECLARE
  v_target timestamptz := now() + (p_offset * interval '1 week');
BEGIN
  wk := EXTRACT(week    FROM v_target)::integer;
  yr := EXTRACT(isoyear FROM v_target)::integer;
  RETURN NEXT;
END $$;


-- ════════════════════════════════════════════════════════════════════════════
-- WIPE PRIOR DEMO DATA (only rows belonging to @rayse.demo users)
-- Auth.users → profiles → community_videos → reactions/comments cascade.
-- We just wipe the auxiliary tables and the challenges/videos that reference
-- those demo users.
-- ════════════════════════════════════════════════════════════════════════════

DELETE FROM public.notifications
 WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@rayse.demo');

DELETE FROM public.community_reactions
 WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@rayse.demo');

DELETE FROM public.video_comments
 WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@rayse.demo');

DELETE FROM public.community_videos
 WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@rayse.demo');

-- Wipe challenges last (FK from videos via skill+week, not enforced, but tidy)
DELETE FROM public.challenges WHERE created_at > now() - interval '60 days';

-- Reset XP & skill progress (will be reseeded by seed_personas.sql; if you
-- want demo data without re-running personas, comment these two lines out)
-- DELETE FROM public.user_xp
--  WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@rayse.demo');
-- DELETE FROM public.user_skill_progress
--  WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%@rayse.demo');


-- ════════════════════════════════════════════════════════════════════════════
-- ALL THE SEEDING (one big DO block so we can use variables)
-- ════════════════════════════════════════════════════════════════════════════

DO $$
DECLARE
  -- Persona UUIDs
  v_admin        uuid := (SELECT id FROM auth.users WHERE email = 'admin@rayse.demo');
  v_advanced     uuid := (SELECT id FROM auth.users WHERE email = 'advanced@rayse.demo');
  v_intermediate uuid := (SELECT id FROM auth.users WHERE email = 'intermediate@rayse.demo');
  v_beginner     uuid := (SELECT id FROM auth.users WHERE email = 'beginner@rayse.demo');
  v_free         uuid := (SELECT id FROM auth.users WHERE email = 'free@rayse.demo');
  v_j1  uuid := (SELECT id FROM auth.users WHERE email = 'jumper1@rayse.demo');
  v_j2  uuid := (SELECT id FROM auth.users WHERE email = 'jumper2@rayse.demo');
  v_j3  uuid := (SELECT id FROM auth.users WHERE email = 'jumper3@rayse.demo');
  v_j4  uuid := (SELECT id FROM auth.users WHERE email = 'jumper4@rayse.demo');
  v_j5  uuid := (SELECT id FROM auth.users WHERE email = 'jumper5@rayse.demo');
  v_j6  uuid := (SELECT id FROM auth.users WHERE email = 'jumper6@rayse.demo');
  v_j7  uuid := (SELECT id FROM auth.users WHERE email = 'jumper7@rayse.demo');
  v_j8  uuid := (SELECT id FROM auth.users WHERE email = 'jumper8@rayse.demo');
  v_j9  uuid := (SELECT id FROM auth.users WHERE email = 'jumper9@rayse.demo');
  v_j10 uuid := (SELECT id FROM auth.users WHERE email = 'jumper10@rayse.demo');

  -- Challenge UUIDs (resolved after insert)
  v_ch_beg_now  uuid;
  v_ch_int_now  uuid;
  v_ch_adv_now  uuid;
  v_ch_upcoming uuid;
  v_ch_past1    uuid;
  v_ch_past2    uuid;
  v_ch_past3    uuid;

  -- Video UUIDs for adding reactions / comments later
  v_v_ava_adv  uuid;
  v_v_j8_adv   uuid;
  v_v_j9_adv   uuid;
  v_v_ian_int  uuid;
  v_v_j5_int   uuid;
  v_v_beth_beg uuid;
  v_v_j1_beg   uuid;
  v_v_past1_w  uuid;  -- winner of past beginner challenge

  -- Week tuples
  cur_wk integer; cur_yr integer;
  nxt_wk integer; nxt_yr integer;
  p1_wk  integer; p1_yr  integer;
  p2_wk  integer; p2_yr  integer;
  p3_wk  integer; p3_yr  integer;

  -- Single public URL every demo video reuses (playable in the app).
  -- See script header for the bucket / file naming convention.
  c_demo_video text := 'https://wcaemsoglgsypzfjzcjf.supabase.co/storage/v1/object/public/for-demo-only/for-rayse-demo.mp4';
BEGIN
  -- Resolve weeks
  SELECT wk, yr INTO cur_wk, cur_yr FROM public.rayse_seed_week(0);
  SELECT wk, yr INTO nxt_wk, nxt_yr FROM public.rayse_seed_week(1);
  SELECT wk, yr INTO p1_wk,  p1_yr  FROM public.rayse_seed_week(-1);
  SELECT wk, yr INTO p2_wk,  p2_yr  FROM public.rayse_seed_week(-2);
  SELECT wk, yr INTO p3_wk,  p3_yr  FROM public.rayse_seed_week(-3);

  -- Disable the challenge-new fanout trigger while we seed so it doesn't
  -- flood every user with a notification per insert.
  ALTER TABLE public.challenges DISABLE TRIGGER challenge_new_trigger;
  -- The submit trigger awards +25 XP per video; we want it OFF so seeded
  -- data doesn't accidentally pump XP. We also handle approval XP manually.
  ALTER TABLE public.community_videos DISABLE TRIGGER challenge_video_submit_trigger;
  ALTER TABLE public.community_videos DISABLE TRIGGER challenge_video_approval_trigger;

  -- ────────────────────────────────────────────────────────────────────────
  -- CHALLENGES
  -- ────────────────────────────────────────────────────────────────────────

  -- This week: one per tier
  INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward)
  VALUES
    ('forward_jump',  'Forward Flow',       'Clean forward jumps — how long can you stay on rhythm?', cur_wk, cur_yr,  75),
    ('double_unders', 'Double Under Showdown', 'Smooth, controlled double unders.',                     cur_wk, cur_yr, 100),
    ('freestyle',     'Freestyle Friday',   'Show your most creative freestyle combo.',                cur_wk, cur_yr, 200)
  RETURNING id INTO v_ch_beg_now;  -- only catches the first; resolve explicitly below

  SELECT id INTO v_ch_beg_now FROM public.challenges WHERE skill_id='forward_jump'  AND week_number=cur_wk AND week_year=cur_yr;
  SELECT id INTO v_ch_int_now FROM public.challenges WHERE skill_id='double_unders' AND week_number=cur_wk AND week_year=cur_yr;
  SELECT id INTO v_ch_adv_now FROM public.challenges WHERE skill_id='freestyle'     AND week_number=cur_wk AND week_year=cur_yr;

  -- Next week: upcoming teaser
  INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward)
  VALUES ('alt_steps', 'Alternating Steps Sprint', 'Coming up next week — keep your rhythm.', nxt_wk, nxt_yr, 75);
  SELECT id INTO v_ch_upcoming FROM public.challenges WHERE skill_id='alt_steps' AND week_number=nxt_wk AND week_year=nxt_yr;

  -- Past 3 weeks, all finalized
  INSERT INTO public.challenges (skill_id, title, description, week_number, week_year, xp_reward, finalized_at)
  VALUES
    ('basic_bounce', 'Bounce Marathon', 'Cleanest basic bounce wins.',          p1_wk, p1_yr,  50, now() - interval '5 days'),
    ('cross_overs',  'Cross Over Kings', 'Smoothest crossovers take the crown.', p2_wk, p2_yr, 100, now() - interval '12 days'),
    ('triple_unders','Triple Threat',   'Triples only — how many in 60s?',       p3_wk, p3_yr, 175, now() - interval '19 days');
  SELECT id INTO v_ch_past1 FROM public.challenges WHERE skill_id='basic_bounce'  AND week_number=p1_wk AND week_year=p1_yr;
  SELECT id INTO v_ch_past2 FROM public.challenges WHERE skill_id='cross_overs'   AND week_number=p2_wk AND week_year=p2_yr;
  SELECT id INTO v_ch_past3 FROM public.challenges WHERE skill_id='triple_unders' AND week_number=p3_wk AND week_year=p3_yr;

  -- ────────────────────────────────────────────────────────────────────────
  -- COMMUNITY VIDEOS — this week (approved)
  -- ────────────────────────────────────────────────────────────────────────

  -- BEGINNER (forward_jump) — 4 approved + beth from beginner persona
  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, score, submitted_at, reviewed_at, reviewed_by, xp_awarded)
  VALUES
    (v_j1,       'forward_jump', c_demo_video, 'First clean set!',     'approved', true, cur_wk, cur_yr, 12, now() - interval '2 days',   now() - interval '2 days',   v_admin, true),
    (v_j2,       'forward_jump', c_demo_video, 'Found my rhythm 🔥',    'approved', true, cur_wk, cur_yr, 24, now() - interval '36 hours', now() - interval '36 hours', v_admin, true),
    (v_j3,       'forward_jump', c_demo_video, 'Smooth as butter',     'approved', true, cur_wk, cur_yr, 18, now() - interval '20 hours', now() - interval '18 hours', v_admin, true),
    (v_j4,       'forward_jump', c_demo_video, 'Long set this week',   'approved', true, cur_wk, cur_yr,  9, now() - interval '12 hours', now() - interval '8 hours',  v_admin, true),
    (v_beginner, 'forward_jump', c_demo_video, 'My entry — clean form','approved', true, cur_wk, cur_yr,  6, now() - interval '6 hours',  now() - interval '4 hours',  v_admin, true)
  RETURNING id INTO v_v_j1_beg;
  SELECT id INTO v_v_beth_beg FROM public.community_videos WHERE user_id = v_beginner AND week_number = cur_wk AND skill_id = 'forward_jump';
  SELECT id INTO v_v_j1_beg   FROM public.community_videos WHERE user_id = v_j1       AND week_number = cur_wk AND skill_id = 'forward_jump';

  -- INTERMEDIATE (double_unders) — 4 approved + ian from intermediate persona
  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, score, submitted_at, reviewed_at, reviewed_by, xp_awarded)
  VALUES
    (v_j5,           'double_unders', c_demo_video, '34 in a row!',          'approved', true, cur_wk, cur_yr, 28, now() - interval '40 hours', now() - interval '38 hours', v_admin, true),
    (v_j6,           'double_unders', c_demo_video, 'Clean technique',       'approved', true, cur_wk, cur_yr, 17, now() - interval '24 hours', now() - interval '20 hours', v_admin, true),
    (v_j7,           'double_unders', c_demo_video, 'PR set 💪',             'approved', true, cur_wk, cur_yr, 22, now() - interval '18 hours', now() - interval '15 hours', v_admin, true),
    (v_intermediate, 'double_unders', c_demo_video, 'Working on speed',      'approved', true, cur_wk, cur_yr, 14, now() - interval '10 hours', now() - interval '6 hours',  v_admin, true);
  SELECT id INTO v_v_ian_int FROM public.community_videos WHERE user_id = v_intermediate AND week_number = cur_wk AND skill_id = 'double_unders';
  SELECT id INTO v_v_j5_int  FROM public.community_videos WHERE user_id = v_j5           AND week_number = cur_wk AND skill_id = 'double_unders';

  -- ADVANCED (freestyle) — 3 approved + ava from advanced persona
  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, score, submitted_at, reviewed_at, reviewed_by, xp_awarded)
  VALUES
    (v_j8,       'freestyle', c_demo_video, '30s combo flow',        'approved', true, cur_wk, cur_yr, 31, now() - interval '3 days',   now() - interval '3 days',   v_admin, true),
    (v_j9,       'freestyle', c_demo_video, 'Crowner + cross combo', 'approved', true, cur_wk, cur_yr, 26, now() - interval '2 days',   now() - interval '2 days',   v_admin, true),
    (v_j10,      'freestyle', c_demo_video, 'Triple-release flow',   'approved', true, cur_wk, cur_yr, 19, now() - interval '36 hours', now() - interval '30 hours', v_admin, true),
    (v_advanced, 'freestyle', c_demo_video, 'Hardest combo yet',     'approved', true, cur_wk, cur_yr, 35, now() - interval '8 hours',  now() - interval '4 hours',  v_admin, true);
  SELECT id INTO v_v_ava_adv FROM public.community_videos WHERE user_id = v_advanced AND week_number = cur_wk AND skill_id = 'freestyle';
  SELECT id INTO v_v_j8_adv  FROM public.community_videos WHERE user_id = v_j8       AND week_number = cur_wk AND skill_id = 'freestyle';
  SELECT id INTO v_v_j9_adv  FROM public.community_videos WHERE user_id = v_j9       AND week_number = cur_wk AND skill_id = 'freestyle';

  -- ────────────────────────────────────────────────────────────────────────
  -- PENDING VIDEOS — for the admin approval-flow demo
  -- ────────────────────────────────────────────────────────────────────────

  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, submitted_at)
  VALUES
    (v_j2, 'double_unders', c_demo_video, 'Fresh DU set, please review',  'pending', true, cur_wk, cur_yr, now() - interval '30 minutes'),
    (v_j6, 'freestyle',     c_demo_video, 'New freestyle combo',          'pending', true, cur_wk, cur_yr, now() - interval '5 minutes');

  -- ────────────────────────────────────────────────────────────────────────
  -- PAST CHALLENGE VIDEOS (with placements that match the persona narrative)
  -- ────────────────────────────────────────────────────────────────────────

  -- Past 1: basic_bounce (Beginner). v_advanced placed #1 (for profile history).
  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, score, submitted_at, reviewed_at, reviewed_by, xp_awarded)
  VALUES
    (v_advanced, 'basic_bounce', c_demo_video, 'My winning bounce!', 'approved', true, p1_wk, p1_yr, 42, now() - interval '8 days', now() - interval '7 days', v_admin, true),
    (v_j1,       'basic_bounce', c_demo_video, 'Solid week',         'approved', true, p1_wk, p1_yr, 35, now() - interval '8 days', now() - interval '7 days', v_admin, true),
    (v_j2,       'basic_bounce', c_demo_video, 'Third place 🥉',     'approved', true, p1_wk, p1_yr, 28, now() - interval '8 days', now() - interval '7 days', v_admin, true),
    (v_j3,       'basic_bounce', c_demo_video, 'Cleanest yet',       'approved', true, p1_wk, p1_yr, 20, now() - interval '8 days', now() - interval '7 days', v_admin, true),
    (v_beginner, 'basic_bounce', c_demo_video, 'My first entry',     'approved', true, p1_wk, p1_yr, 12, now() - interval '8 days', now() - interval '7 days', v_admin, true);
  SELECT id INTO v_v_past1_w FROM public.community_videos WHERE user_id = v_advanced AND week_number = p1_wk AND skill_id = 'basic_bounce';

  -- Past 2: cross_overs (Intermediate). v_advanced placed #2.
  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, score, submitted_at, reviewed_at, reviewed_by, xp_awarded)
  VALUES
    (v_j7,           'cross_overs', c_demo_video, 'Smoothest set',  'approved', true, p2_wk, p2_yr, 38, now() - interval '15 days', now() - interval '14 days', v_admin, true),
    (v_advanced,     'cross_overs', c_demo_video, 'Close second 🥈', 'approved', true, p2_wk, p2_yr, 33, now() - interval '15 days', now() - interval '14 days', v_admin, true),
    (v_j5,           'cross_overs', c_demo_video, 'Crisp form',     'approved', true, p2_wk, p2_yr, 25, now() - interval '15 days', now() - interval '14 days', v_admin, true),
    (v_intermediate, 'cross_overs', c_demo_video, 'Loving this',    'approved', true, p2_wk, p2_yr, 17, now() - interval '15 days', now() - interval '14 days', v_admin, true);

  -- Past 3: triple_unders (Advanced). v_j8 placed #1, v_advanced placed #3.
  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, caption, status, is_challenge, week_number, week_year, score, submitted_at, reviewed_at, reviewed_by, xp_awarded)
  VALUES
    (v_j8,       'triple_unders', c_demo_video, '8 in a row 🥇', 'approved', true, p3_wk, p3_yr, 44, now() - interval '22 days', now() - interval '21 days', v_admin, true),
    (v_j9,       'triple_unders', c_demo_video, '6 clean 🥈',    'approved', true, p3_wk, p3_yr, 36, now() - interval '22 days', now() - interval '21 days', v_admin, true),
    (v_advanced, 'triple_unders', c_demo_video, '5 clean 🥉',    'approved', true, p3_wk, p3_yr, 30, now() - interval '22 days', now() - interval '21 days', v_admin, true),
    (v_j10,      'triple_unders', c_demo_video, '4 attempted',   'approved', true, p3_wk, p3_yr, 18, now() - interval '22 days', now() - interval '21 days', v_admin, true);

  -- ────────────────────────────────────────────────────────────────────────
  -- PERSONAL VIDEOS — populate skill detail / profile screens
  -- ────────────────────────────────────────────────────────────────────────

  INSERT INTO public.community_videos
    (user_id, skill_id, video_url, title, notes, status, is_challenge, week_number, week_year, submitted_at)
  VALUES
    (v_advanced,     'freestyle',     c_demo_video,   'Practice combo #4', 'Working on transition speed',     'approved', false, cur_wk, cur_yr, now() - interval '3 days'),
    (v_intermediate, 'double_unders', c_demo_video,   'DU drill',          'Felt smoother today',             'approved', false, cur_wk, cur_yr, now() - interval '2 days'),
    (v_beginner,     'forward_jump',  c_demo_video,   'Warm-up',           'Building rhythm',                 'approved', false, cur_wk, cur_yr, now() - interval '1 day'),
    (v_admin,        'basic_bounce',  c_demo_video, 'Form check',        'Demoing how personal videos look','approved', false, cur_wk, cur_yr, now() - interval '4 days');

  -- ────────────────────────────────────────────────────────────────────────
  -- FIRE REACTIONS — scatter ~80 across top approved videos
  -- ────────────────────────────────────────────────────────────────────────

  -- Reactions on advanced freestyle videos
  INSERT INTO public.community_reactions (user_id, video_id) VALUES
    (v_admin,        v_v_ava_adv),
    (v_intermediate, v_v_ava_adv),
    (v_beginner,     v_v_ava_adv),
    (v_j1, v_v_ava_adv), (v_j2, v_v_ava_adv), (v_j3, v_v_ava_adv),
    (v_j5, v_v_ava_adv), (v_j6, v_v_ava_adv), (v_j7, v_v_ava_adv),
    (v_j8, v_v_ava_adv), (v_j9, v_v_ava_adv), (v_j10, v_v_ava_adv)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.community_reactions (user_id, video_id) VALUES
    (v_admin, v_v_j8_adv), (v_advanced, v_v_j8_adv),
    (v_j1, v_v_j8_adv), (v_j2, v_v_j8_adv), (v_j5, v_v_j8_adv), (v_j9, v_v_j8_adv)
  ON CONFLICT DO NOTHING;

  -- Intermediate
  INSERT INTO public.community_reactions (user_id, video_id) VALUES
    (v_admin, v_v_ian_int), (v_advanced, v_v_ian_int), (v_beginner, v_v_ian_int),
    (v_j1, v_v_ian_int), (v_j6, v_v_ian_int), (v_j8, v_v_ian_int)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.community_reactions (user_id, video_id) VALUES
    (v_admin, v_v_j5_int), (v_advanced, v_v_j5_int),
    (v_j1, v_v_j5_int), (v_j2, v_v_j5_int), (v_j6, v_v_j5_int), (v_j10, v_v_j5_int)
  ON CONFLICT DO NOTHING;

  -- Beginner
  INSERT INTO public.community_reactions (user_id, video_id) VALUES
    (v_admin, v_v_beth_beg), (v_advanced, v_v_beth_beg), (v_intermediate, v_v_beth_beg),
    (v_j2, v_v_beth_beg), (v_j3, v_v_beth_beg)
  ON CONFLICT DO NOTHING;

  -- ────────────────────────────────────────────────────────────────────────
  -- COMMENTS — premium users on top videos
  -- ────────────────────────────────────────────────────────────────────────

  INSERT INTO public.video_comments (video_id, user_id, body, created_at) VALUES
    (v_v_ava_adv,  v_admin,        'Insane form — that transition at 0:14 🔥', now() - interval '6 hours'),
    (v_v_ava_adv,  v_intermediate,'How did you set up that release?',          now() - interval '4 hours'),
    (v_v_j8_adv,   v_advanced,     'Great combo, the cross at the end!',        now() - interval '20 hours'),
    (v_v_ian_int,  v_admin,        'Clean DUs, keep pushing',                    now() - interval '8 hours'),
    (v_v_j5_int,   v_intermediate, '34 is wild, what cadence are you holding?', now() - interval '30 hours'),
    (v_v_beth_beg, v_intermediate, 'Strong start! 💪',                          now() - interval '3 hours'),
    (v_v_past1_w,  v_admin,        'Deserved win last week',                     now() - interval '6 days');

  -- ────────────────────────────────────────────────────────────────────────
  -- NOTIFICATIONS — mix of read + unread per demo persona
  -- ────────────────────────────────────────────────────────────────────────

  -- challenge_new (UNREAD) for active week challenges — this lights up the
  -- bell and the profile tab dot for each demo persona.
  INSERT INTO public.notifications (user_id, type, title, body, data, is_read, created_at)
  SELECT u.id, 'challenge_new', '🏆 New challenge dropped!',
         c.title || ' is live this week — submit your video!',
         jsonb_build_object('challenge_id', c.id, 'skill_id', c.skill_id,
                            'week_number', c.week_number, 'week_year', c.week_year),
         false, now() - interval '2 hours'
    FROM (VALUES (v_admin),(v_advanced),(v_intermediate),(v_beginner),(v_free)) u(id)
    CROSS JOIN public.challenges c
   WHERE c.week_number = cur_wk AND c.week_year = cur_yr;

  -- challenge_approved (READ) for users whose video was approved this week
  INSERT INTO public.notifications (user_id, type, title, body, data, is_read, created_at)
  VALUES
    (v_beginner,     'challenge_approved', 'Challenge Approved! 🏆',
       'Your video is live on the leaderboard. You earned +75 XP',
       jsonb_build_object('video_id', v_v_beth_beg, 'xp', 75),  true, now() - interval '4 hours'),
    (v_intermediate, 'challenge_approved', 'Challenge Approved! 🏆',
       'Your video is live on the leaderboard. You earned +100 XP',
       jsonb_build_object('video_id', v_v_ian_int, 'xp', 100), true, now() - interval '6 hours'),
    (v_advanced,     'challenge_approved', 'Challenge Approved! 🏆',
       'Your video is live on the leaderboard. You earned +200 XP',
       jsonb_build_object('video_id', v_v_ava_adv, 'xp', 200), true, now() - interval '4 hours');

  -- challenge_placed (READ) from past finalized challenges
  INSERT INTO public.notifications (user_id, type, title, body, data, is_read, created_at)
  VALUES
    (v_advanced, 'challenge_placed', '🥇 You won the challenge!',
       'You earned a +50 XP bonus on "Bounce Marathon"',
       jsonb_build_object('challenge_id', v_ch_past1, 'rank', 1, 'xp', 50),  true, now() - interval '5 days'),
    (v_advanced, 'challenge_placed', '🥈 You placed #2!',
       'You earned a +100 XP bonus on "Cross Over Kings"',
       jsonb_build_object('challenge_id', v_ch_past2, 'rank', 2, 'xp', 100), true, now() - interval '12 days'),
    (v_advanced, 'challenge_placed', '🥉 You placed #3!',
       'You earned a +175 XP bonus on "Triple Threat"',
       jsonb_build_object('challenge_id', v_ch_past3, 'rank', 3, 'xp', 175), true, now() - interval '19 days');

  -- comment (UNREAD) on advanced user's top video
  INSERT INTO public.notifications (user_id, type, title, body, data, is_read, created_at)
  VALUES
    (v_advanced, 'comment', 'New Comment',
       '@demo_admin commented on your video',
       jsonb_build_object('video_id', v_v_ava_adv), false, now() - interval '6 hours');

  -- Re-enable triggers
  ALTER TABLE public.challenges        ENABLE TRIGGER challenge_new_trigger;
  ALTER TABLE public.community_videos  ENABLE TRIGGER challenge_video_submit_trigger;
  ALTER TABLE public.community_videos  ENABLE TRIGGER challenge_video_approval_trigger;
END $$;


-- ════════════════════════════════════════════════════════════════════════════
-- Demo seed complete. Re-run any time to reset against today's ISO week.
-- ════════════════════════════════════════════════════════════════════════════
