-- ====================================================================
-- IRON-PASS | Elite Gym & ITF Taekwon-Do Management App
-- Supabase Database Schema, Row-Level Security (RLS) & Realtime Setup
-- ====================================================================
-- Instructions:
-- 1. Create a free project at https://supabase.com
-- 2. In your Supabase dashboard, navigate to SQL Editor (left sidebar)
-- 3. Click "New query", paste this entire script, and click "Run"
-- 4. Go to Project Settings -> API to copy your Project URL & anon key
-- 5. Paste them into the IRON-PASS app under Settings -> Supabase Cloud
-- ====================================================================

-- 1. MEMBERS TABLE
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

-- Index for quick lookups & filtering
CREATE INDEX IF NOT EXISTS idx_members_category ON public.members(category);
CREATE INDEX IF NOT EXISTS idx_members_expiry ON public.members(membership_expiry_date);

-- 2. AUDIT LOG TABLE (Check-ins, renewals, registrations, denials)
CREATE TABLE IF NOT EXISTS public.audit_log (
    id TEXT PRIMARY KEY,
    member_id TEXT,
    member_name TEXT NOT NULL DEFAULT 'System',
    action TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    details TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON public.audit_log(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_member_id ON public.audit_log(member_id);

-- 3. ROLL CALL ATTENDANCE TABLE (Daily ITF roll call)
CREATE TABLE IF NOT EXISTS public.rollcall (
    date DATE PRIMARY KEY,
    present_ids JSONB DEFAULT '[]'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CLUB SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.settings (
    id TEXT PRIMARY KEY DEFAULT 'default',
    club_name TEXT DEFAULT 'IRON-PASS Elite Club',
    opening_hour INTEGER DEFAULT 6,
    currency TEXT DEFAULT 'ETB',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings row if missing
INSERT INTO public.settings (id, club_name, opening_hour, currency)
VALUES ('default', 'IRON-PASS Elite Club', 6, 'ETB')
ON CONFLICT (id) DO NOTHING;

-- 5. ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rollcall ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- 6. PUBLIC ACCESS POLICIES (Allow front-desk web kiosk / staff anon access)
DROP POLICY IF EXISTS "Allow public read members" ON public.members;
CREATE POLICY "Allow public read members" ON public.members FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert members" ON public.members;
CREATE POLICY "Allow public insert members" ON public.members FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow public update members" ON public.members;
CREATE POLICY "Allow public update members" ON public.members FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow public delete members" ON public.members;
CREATE POLICY "Allow public delete members" ON public.members FOR DELETE USING (true);

DROP POLICY IF EXISTS "Allow public read audit_log" ON public.audit_log;
CREATE POLICY "Allow public read audit_log" ON public.audit_log FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert audit_log" ON public.audit_log;
CREATE POLICY "Allow public insert audit_log" ON public.audit_log FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow public update audit_log" ON public.audit_log;
CREATE POLICY "Allow public update audit_log" ON public.audit_log FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow public delete audit_log" ON public.audit_log;
CREATE POLICY "Allow public delete audit_log" ON public.audit_log FOR DELETE USING (true);

DROP POLICY IF EXISTS "Allow public read rollcall" ON public.rollcall;
CREATE POLICY "Allow public read rollcall" ON public.rollcall FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert rollcall" ON public.rollcall;
CREATE POLICY "Allow public insert rollcall" ON public.rollcall FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow public update rollcall" ON public.rollcall;
CREATE POLICY "Allow public update rollcall" ON public.rollcall FOR UPDATE USING (true);
DROP POLICY IF EXISTS "Allow public delete rollcall" ON public.rollcall;
CREATE POLICY "Allow public delete rollcall" ON public.rollcall FOR DELETE USING (true);

DROP POLICY IF EXISTS "Allow public read settings" ON public.settings;
CREATE POLICY "Allow public read settings" ON public.settings FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow public insert settings" ON public.settings;
CREATE POLICY "Allow public insert settings" ON public.settings FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow public update settings" ON public.settings;
CREATE POLICY "Allow public update settings" ON public.settings FOR UPDATE USING (true);

-- 7. ENABLE REALTIME REPLICATION (Instant sync across devices)
DO $$
BEGIN
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.members; EXCEPTION WHEN duplicate_object THEN END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.audit_log; EXCEPTION WHEN duplicate_object THEN END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.rollcall; EXCEPTION WHEN duplicate_object THEN END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.settings; EXCEPTION WHEN duplicate_object THEN END;
END $$;

