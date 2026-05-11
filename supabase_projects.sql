-- ============================================================
-- agent_projects 테이블 (= Recent Projects) — 2026-05-12
-- 회사별 진행 중·완료·일시정지 프로젝트 관리
-- ============================================================

CREATE TABLE IF NOT EXISTS public.agent_projects (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    UUID REFERENCES public.agent_companies(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  subtitle      TEXT,
  status        TEXT NOT NULL DEFAULT 'active',  -- 'active' / 'completed' / 'paused'
  url           TEXT,
  thumbnail_url TEXT,
  sort_order    INTEGER DEFAULT 100,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_projects_company ON public.agent_projects(company_id);
CREATE INDEX IF NOT EXISTS idx_agent_projects_status ON public.agent_projects(status);

ALTER TABLE public.agent_projects ENABLE ROW LEVEL SECURITY;

-- 읽기 = 누구나 (= 자유 가입 모델)
DROP POLICY IF EXISTS "agent_projects_read_all" ON public.agent_projects;
CREATE POLICY "agent_projects_read_all" ON public.agent_projects FOR SELECT USING (TRUE);

-- 쓰기 = admin만
DROP POLICY IF EXISTS "agent_projects_admin_write" ON public.agent_projects;
CREATE POLICY "agent_projects_admin_write" ON public.agent_projects
  FOR ALL USING (public.is_agent_admin())
  WITH CHECK (public.is_agent_admin());

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION public.update_agent_project_timestamp()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_agent_project_update ON public.agent_projects;
CREATE TRIGGER on_agent_project_update
  BEFORE UPDATE ON public.agent_projects
  FOR EACH ROW EXECUTE FUNCTION public.update_agent_project_timestamp();

-- 끝
