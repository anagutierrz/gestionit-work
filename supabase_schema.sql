-- ============================================================
-- GESTIÓN IT PORTAL — Supabase Schema
-- Ejecutar en: Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. TABLA DE PERFILES DE USUARIO (extiende auth.users de Supabase)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'manager', 'viewer')),
  avatar_initials TEXT,
  department TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE
);

-- 2. TABLA DE LEADS
CREATE TABLE public.leads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_name TEXT NOT NULL,
  contact_name TEXT NOT NULL,
  contact_email TEXT,
  contact_phone TEXT,
  cargo TEXT CHECK (cargo IN ('CFO', 'CISO', 'IT Manager', 'CEO', 'CTO', 'Otro')),
  solution TEXT CHECK (solution IN ('CloudSpend', 'Sophos', 'ManageEngine', 'Multiple')),
  stage TEXT NOT NULL DEFAULT 'lead' CHECK (stage IN (
    'lead', 'contactado', 'discovery', 'diagnostico',
    'propuesta', 'negociacion', 'cerrado_ganado', 'cerrado_perdido'
  )),
  deal_value DECIMAL(12,2),
  probability INTEGER DEFAULT 10 CHECK (probability BETWEEN 0 AND 100),
  notes TEXT,
  assigned_to UUID REFERENCES public.profiles(id),
  source TEXT CHECK (source IN ('LinkedIn', 'Google Ads', 'Email', 'Referido', 'Directo', 'Evento', 'Otro')),
  industry TEXT,
  employees_count INTEGER,
  next_action TEXT,
  next_action_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  closed_at TIMESTAMPTZ,
  lost_reason TEXT
);

-- 3. TABLA DE ACTIVIDADES / HISTORIAL
CREATE TABLE public.activities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lead_id UUID REFERENCES public.leads(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id),
  type TEXT CHECK (type IN ('call', 'email', 'meeting', 'note', 'stage_change', 'proposal')),
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABLA DE MÉTRICAS MENSUALES (para dashboard)
CREATE TABLE public.monthly_metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  month DATE NOT NULL,
  leads_generated INTEGER DEFAULT 0,
  mqls INTEGER DEFAULT 0,
  sqls INTEGER DEFAULT 0,
  proposals_sent INTEGER DEFAULT 0,
  deals_closed INTEGER DEFAULT 0,
  revenue_closed DECIMAL(12,2) DEFAULT 0,
  pipeline_value DECIMAL(12,2) DEFAULT 0,
  cpl DECIMAL(8,2),
  marketing_spend DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) — Seguridad por fila
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_metrics ENABLE ROW LEVEL SECURITY;

-- Políticas para PROFILES
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can insert profiles"
  ON public.profiles FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Políticas para LEADS
CREATE POLICY "Authenticated users can view leads"
  ON public.leads FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Managers and admins can insert leads"
  ON public.leads FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'manager'))
  );

CREATE POLICY "Managers and admins can update leads"
  ON public.leads FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('admin', 'manager'))
  );

CREATE POLICY "Only admins can delete leads"
  ON public.leads FOR DELETE
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Políticas para ACTIVITIES
CREATE POLICY "Authenticated users can view activities"
  ON public.activities FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert activities"
  ON public.activities FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Políticas para MONTHLY_METRICS
CREATE POLICY "Authenticated users can view metrics"
  ON public.monthly_metrics FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage metrics"
  ON public.monthly_metrics FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================
-- FUNCIÓN: Auto-crear perfil al registrar usuario
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_initials)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    UPPER(LEFT(COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), 1) ||
          COALESCE(SPLIT_PART(NEW.raw_user_meta_data->>'full_name', ' ', 2), '')[1:1])
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger para updated_at en leads
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER leads_updated_at
  BEFORE UPDATE ON public.leads
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================================
-- DATOS DE EJEMPLO (opcional — ejecutar después del schema)
-- ============================================================
-- Insertar métricas de ejemplo:
INSERT INTO public.monthly_metrics (month, leads_generated, mqls, sqls, proposals_sent, deals_closed, revenue_closed, pipeline_value, cpl, marketing_spend)
VALUES
  ('2025-01-01', 180, 63, 31, 14, 4, 48000, 210000, 47, 8460),
  ('2025-02-01', 210, 73, 36, 16, 5, 62500, 245000, 43, 9030),
  ('2025-03-01', 245, 85, 42, 19, 6, 78000, 290000, 41, 10045),
  ('2025-04-01', 290, 101, 50, 22, 7, 91000, 340000, 38, 11020);
