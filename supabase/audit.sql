-- ════════════════════════════════════════════════════════════════════════════
-- Rayse — Supabase live-DB audit
-- ════════════════════════════════════════════════════════════════════════════
-- Run this in your Supabase SQL editor on the LIVE project. Copy the entire
-- result (one big table with section/name/detail/extra columns) back to the
-- developer; they will diff it against `setup.sql` and reconcile gaps.
--
-- This is read-only. Safe to run any time.
-- ════════════════════════════════════════════════════════════════════════════

WITH
-- Tables in the `public` schema
tables_ AS (
  SELECT
    'TABLE'::text          AS section,
    table_name              AS name,
    ''::text                AS detail,
    ''::text                AS extra
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
),

-- Columns of those tables (type, nullability, default)
columns_ AS (
  SELECT
    'COLUMN'                                  AS section,
    c.table_name || '.' || c.column_name      AS name,
    c.data_type
      || COALESCE(' (' || c.character_maximum_length || ')', '')
      || (CASE WHEN c.is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END)
                                              AS detail,
    COALESCE(c.column_default, '')            AS extra
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
),

-- Primary / unique / foreign-key constraints
constraints_ AS (
  SELECT
    'CONSTRAINT'                              AS section,
    tc.table_name || '.' || tc.constraint_name AS name,
    tc.constraint_type                         AS detail,
    COALESCE(
      string_agg(kcu.column_name, ',' ORDER BY kcu.ordinal_position),
      ''
    )                                          AS extra
  FROM information_schema.table_constraints tc
  LEFT JOIN information_schema.key_column_usage kcu
    ON  tc.constraint_name = kcu.constraint_name
    AND tc.table_schema    = kcu.table_schema
  WHERE tc.table_schema = 'public'
    AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE', 'FOREIGN KEY', 'CHECK')
  GROUP BY tc.table_name, tc.constraint_name, tc.constraint_type
),

-- Indexes (excluding those auto-created for PK/UNIQUE constraints)
indexes_ AS (
  SELECT
    'INDEX'                          AS section,
    schemaname || '.' || indexname    AS name,
    tablename                         AS detail,
    indexdef                          AS extra
  FROM pg_indexes
  WHERE schemaname = 'public'
),

-- RLS on/off per table
rls_ AS (
  SELECT
    'RLS'                             AS section,
    n.nspname || '.' || c.relname     AS name,
    CASE WHEN c.relrowsecurity THEN 'ENABLED' ELSE 'DISABLED' END AS detail,
    ''                                AS extra
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public'
    AND c.relkind = 'r'
),

-- RLS policies (public + storage)
policies_ AS (
  SELECT
    'POLICY'                          AS section,
    schemaname || '.' || tablename || '.' || policyname AS name,
    cmd                               AS detail,
    'USING(' || COALESCE(qual, '')
      || ') CHECK(' || COALESCE(with_check, '') || ')' AS extra
  FROM pg_policies
  WHERE schemaname IN ('public', 'storage')
),

-- Functions in the public schema
functions_ AS (
  SELECT
    'FUNCTION'                                                 AS section,
    n.nspname || '.' || p.proname                              AS name,
    pg_get_function_result(p.oid)                              AS detail,
    pg_get_function_arguments(p.oid)
      || CASE WHEN p.prosecdef THEN ' [SECURITY DEFINER]' ELSE '' END AS extra
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
),

-- Triggers attached to public/auth tables
triggers_ AS (
  SELECT
    'TRIGGER'                                  AS section,
    t.tgname                                   AS name,
    n.nspname || '.' || c.relname              AS detail,
    pg_get_triggerdef(t.oid)                   AS extra
  FROM pg_trigger t
  JOIN pg_class     c ON t.tgrelid = c.oid
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE NOT t.tgisinternal
    AND n.nspname IN ('public', 'auth')
),

-- Installed extensions (filter to the ones we care about)
extensions_ AS (
  SELECT
    'EXTENSION'           AS section,
    extname               AS name,
    extversion            AS detail,
    ''                    AS extra
  FROM pg_extension
  WHERE extname IN ('pgcrypto', 'pg_cron', 'pg_net', 'uuid-ossp')
),

-- Storage buckets
buckets_ AS (
  SELECT
    'BUCKET'                                    AS section,
    id                                          AS name,
    CASE WHEN public THEN 'PUBLIC' ELSE 'PRIVATE' END AS detail,
    COALESCE(file_size_limit::text, '')         AS extra
  FROM storage.buckets
),

-- Realtime publication membership
publication_ AS (
  SELECT
    'PUBLICATION'                                AS section,
    pubname || '.' || schemaname || '.' || tablename AS name,
    ''                                            AS detail,
    ''                                            AS extra
  FROM pg_publication_tables
  WHERE pubname = 'supabase_realtime'
),

-- pg_cron jobs (will be empty if extension isn't installed)
cron_ AS (
  SELECT
    'CRON'                AS section,
    jobname               AS name,
    schedule              AS detail,
    command               AS extra
  FROM cron.job
)

SELECT * FROM tables_
UNION ALL SELECT * FROM columns_
UNION ALL SELECT * FROM constraints_
UNION ALL SELECT * FROM indexes_
UNION ALL SELECT * FROM rls_
UNION ALL SELECT * FROM policies_
UNION ALL SELECT * FROM functions_
UNION ALL SELECT * FROM triggers_
UNION ALL SELECT * FROM extensions_
UNION ALL SELECT * FROM buckets_
UNION ALL SELECT * FROM publication_
UNION ALL SELECT * FROM cron_
ORDER BY section, name, detail;
