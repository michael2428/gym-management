-- ====================================================================
-- WOLISO GYM & ITF | Multi-Account Privacy, Isolation & Security Schema
-- ====================================================================
-- Instructions:
-- 1. Open your Supabase Dashboard at https://supabase.com
-- 2. Click 'SQL Editor' in the left menu -> 'New query'
-- 3. Paste this entire script and click 'RUN'
-- ====================================================================

-- 1. CREATE TABLES (If not already created)
CREATE TABLE IF NOT EXISTS public.members (
    id TEXT PRIMARY KEY,
    full_name TEXT NOT NULL,
    photo TEXT,
    category TEXT NOT NULL DEFAULT 'GYM' CHECK (category IN ('GYM', 'ITF')),
    age INTEGER DEFAULT 18,
    phone TEXT,
    guardian_name TEXT DEFAULT '',
    belt_rank TEXT DEFAULT '',
    membership_start_date DATE NOT NULL,
    membership_expiry_date DATE NOT NULL,
    monthly_fee NUMERIC(10,2) DEFAULT 0,
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_check_in TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.audit_log (
    id TEXT PRIMARY KEY,
    member_id TEXT,
    member_name TEXT NOT NULL DEFAULT 'System',
    action TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    details TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.rollcall (
    date TEXT PRIMARY KEY,
    present_ids JSONB DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    club_name TEXT DEFAULT 'WOLISO GYM & ITF',
    opening_hour INTEGER DEFAULT 6,
    currency TEXT DEFAULT 'ETB',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. ADD USER_ID COLUMN (Isolates data per logged-in Gmail/Email account)
ALTER TABLE public.members ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.audit_log ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.rollcall ADD COLUMN IF NOT EXISTS user_id TEXT;
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS user_id TEXT;

-- 3. CREATE PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_members_user_id ON public.members(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_user_id ON public.audit_log(user_id);

-- 4. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rollcall ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- 5. DROP LEGACY PUBLIC POLICIES
DROP POLICY IF EXISTS "Allow public read members" ON public.members;
DROP POLICY IF EXISTS "Allow public insert members" ON public.members;
DROP POLICY IF EXISTS "Allow public update members" ON public.members;
DROP POLICY IF EXISTS "Allow public delete members" ON public.members;
DROP POLICY IF EXISTS "Allow public read audit_log" ON public.audit_log;
DROP POLICY IF EXISTS "Allow public insert audit_log" ON public.audit_log;
DROP POLICY IF EXISTS "Allow public update audit_log" ON public.audit_log;
DROP POLICY IF EXISTS "Allow public delete audit_log" ON public.audit_log;
DROP POLICY IF EXISTS "Allow public read rollcall" ON public.rollcall;
DROP POLICY IF EXISTS "Allow public insert rollcall" ON public.rollcall;
DROP POLICY IF EXISTS "Allow public update rollcall" ON public.rollcall;
DROP POLICY IF EXISTS "Allow public delete rollcall" ON public.rollcall;

-- 6. CREATE STRICT PER-ACCOUNT ISOLATION POLICIES
DROP POLICY IF EXISTS "Users access own members" ON public.members;
CREATE POLICY "Users access own members" ON public.members
FOR ALL TO authenticated
USING (auth.uid()::text = user_id OR user_id IS NULL)
WITH CHECK (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users access own audit" ON public.audit_log;
CREATE POLICY "Users access own audit" ON public.audit_log
FOR ALL TO authenticated
USING (auth.uid()::text = user_id OR user_id IS NULL)
WITH CHECK (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users access own rollcall" ON public.rollcall;
CREATE POLICY "Users access own rollcall" ON public.rollcall
FOR ALL TO authenticated
USING (auth.uid()::text = user_id OR user_id IS NULL)
WITH CHECK (auth.uid()::text = user_id);

-- 7. REALTIME REPLICATION (Instant sync per account)
DO $$
BEGIN
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.members; EXCEPTION WHEN duplicate_object THEN END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_log; EXCEPTION WHEN duplicate_object THEN END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.rollcall; EXCEPTION WHEN duplicate_object THEN END;
END $$;