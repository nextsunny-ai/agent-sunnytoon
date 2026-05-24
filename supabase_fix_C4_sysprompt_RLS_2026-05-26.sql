-- ============================================================
-- ★★★★★ CRITICAL-4 정정 SQL (= 2026-05-26)
-- ============================================================
-- 사유: agent_personas.sys_prompt = 로그인 없이도 누구나 read 가능
--       → 12 페르소나 90KB 노하우 1줄 호출로 외부 유출 위험
--       https://pddasonkizwviwqzdhpu.supabase.co/rest/v1/agent_personas?select=sys_prompt&active=eq.true
--
-- 정정: auth.uid() IS NOT NULL 조건 추가 (= 로그인한 사용자만 read)
--       agent_companies / agent_company_personas / agent_projects 도 동일 정정
--
-- 실행: Supabase Dashboard → SQL Editor → 전체 붙여넣기 → Run
--       https://supabase.com/dashboard/project/pddasonkizwviwqzdhpu/sql/new
--
-- 검증: 본 SQL 끝의 SELECT 확인 쿼리 = 0 row (= 비로그인 차단 OK)
-- ============================================================

-- 1) agent_personas: 로그인 필수
DROP POLICY IF EXISTS "agent_personas_read_all" ON public.agent_personas;
CREATE POLICY "agent_personas_read_authed"
  ON public.agent_personas
  FOR SELECT
  USING (active = TRUE AND auth.uid() IS NOT NULL);

-- 2) agent_companies: 로그인 필수 (= 옛 read_all 정정)
DROP POLICY IF EXISTS "agent_companies_read_all" ON public.agent_companies;
CREATE POLICY "agent_companies_read_authed"
  ON public.agent_companies
  FOR SELECT
  USING (active = TRUE AND auth.uid() IS NOT NULL);

-- 3) agent_company_personas: 로그인 필수
DROP POLICY IF EXISTS "agent_company_personas_read_all" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_read_authed"
  ON public.agent_company_personas
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- 4) agent_projects: 로그인 필수 (= MEDIUM-4)
DROP POLICY IF EXISTS "agent_projects_read_all" ON public.agent_projects;
DROP POLICY IF EXISTS "agent_projects_select" ON public.agent_projects;
CREATE POLICY "agent_projects_read_authed"
  ON public.agent_projects
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================================
-- 검증 쿼리 (= 본 SQL 실행 후 = 결과 확인)
-- ============================================================

-- 활성 정책 목록 = 4개 모두 _authed 로 박혔는지 확인
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('agent_personas', 'agent_companies', 'agent_company_personas', 'agent_projects')
  AND cmd = 'SELECT'
ORDER BY tablename, policyname;

-- ============================================================
-- 외부 검증 (= 본 SQL 실행 후 = 별도 터미널)
-- ============================================================
-- curl -s "https://pddasonkizwviwqzdhpu.supabase.co/rest/v1/agent_personas?select=id,sys_prompt&active=eq.true" \
--      -H "apikey: sb_publishable_g_WkmPy-txtru1D93pl8iA_kddaB4GQ"
--
-- = 정정 전 = 12개 row 풀 sys_prompt 반환 (= 유출)
-- = 정정 후 = [] 빈 배열 또는 RLS 차단 메시지 (= OK)

-- 끝
