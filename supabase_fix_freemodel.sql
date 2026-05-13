-- ============================================================
-- 자유 가입 모델 (= 스토리메이커 동일) RLS 정정 (2026-05-12)
-- - 누구나 가입 OK
-- - 회사·페르소나 정보 = 누구나 read OK (= URL 분기용)
-- - BYOK = 본인 API 키 = 진짜 통제
-- - ADMIN = admin@example.com 이메일 = 회사·페르소나 편집
-- ============================================================

-- 1. is_agent_admin() = 이메일 기준 정정 (= membership 기준 옛 함수 → JWT 이메일)
CREATE OR REPLACE FUNCTION public.is_agent_admin()
RETURNS BOOLEAN AS $$
  SELECT (auth.jwt() ->> 'email') = 'admin@example.com';
$$ LANGUAGE sql STABLE;

-- is_agent_member_of() = 자유 가입에선 X = 제거
DROP FUNCTION IF EXISTS public.is_agent_member_of(UUID);

-- 2. agent_companies = 누구나 read (= 자유 가입)
DROP POLICY IF EXISTS "agent_companies_read_own" ON public.agent_companies;
DROP POLICY IF EXISTS "agent_companies_read_all" ON public.agent_companies;
CREATE POLICY "agent_companies_read_all" ON public.agent_companies FOR SELECT USING (active = TRUE);

-- 3. agent_company_personas = 누구나 read
DROP POLICY IF EXISTS "agent_company_personas_read_own" ON public.agent_company_personas;
DROP POLICY IF EXISTS "agent_company_personas_read_all" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_read_all" ON public.agent_company_personas FOR SELECT USING (TRUE);

-- 4. agent_personas = 누구나 read (= 기존)
-- 5. agent_memberships = 사용 X (= 미래 결제 plan용 보존)
DROP POLICY IF EXISTS "agent_memberships_read_own" ON public.agent_memberships;
CREATE POLICY "agent_memberships_read_own" ON public.agent_memberships FOR SELECT USING (user_id = auth.uid() OR public.is_agent_admin());

-- 6. admin@example.com 자동 admin 트리거 = 더 이상 필요 X (= 이메일 기준 = 즉시)
DROP TRIGGER IF EXISTS on_auth_user_created_agent ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_agent_user();

-- 끝
