-- ============================================================
-- RLS 무한 재귀 fix (2026-05-12)
-- agent_memberships SELECT 정책이 자기 자신 참조 = 재귀 사고
-- → SECURITY DEFINER 함수로 우회
-- ============================================================

-- 1. Helper 함수 (= RLS 우회, 재귀 방지)
CREATE OR REPLACE FUNCTION public.is_agent_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agent_memberships
    WHERE user_id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_agent_member_of(_company_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agent_memberships
    WHERE user_id = auth.uid() AND company_id = _company_id
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public;

-- 2. agent_memberships 정책 정정
DROP POLICY IF EXISTS "agent_memberships_read_own" ON public.agent_memberships;
CREATE POLICY "agent_memberships_read_own" ON public.agent_memberships FOR SELECT USING (
  user_id = auth.uid() OR public.is_agent_admin()
);

DROP POLICY IF EXISTS "agent_memberships_admin_write" ON public.agent_memberships;
CREATE POLICY "agent_memberships_admin_write" ON public.agent_memberships
  FOR ALL USING (public.is_agent_admin())
  WITH CHECK (public.is_agent_admin());

-- 3. agent_companies 정책 정정
DROP POLICY IF EXISTS "agent_companies_read_own" ON public.agent_companies;
CREATE POLICY "agent_companies_read_own" ON public.agent_companies FOR SELECT USING (
  active = TRUE AND (public.is_agent_admin() OR public.is_agent_member_of(id))
);

DROP POLICY IF EXISTS "agent_companies_admin_write" ON public.agent_companies;
CREATE POLICY "agent_companies_admin_write" ON public.agent_companies
  FOR ALL USING (public.is_agent_admin())
  WITH CHECK (public.is_agent_admin());

-- 4. agent_company_personas 정책 정정
DROP POLICY IF EXISTS "agent_company_personas_read_own" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_read_own" ON public.agent_company_personas FOR SELECT USING (
  public.is_agent_admin() OR public.is_agent_member_of(company_id)
);

DROP POLICY IF EXISTS "agent_company_personas_admin_write" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_admin_write" ON public.agent_company_personas
  FOR ALL USING (public.is_agent_admin())
  WITH CHECK (public.is_agent_admin());

-- 5. agent_personas 정책 정정 (read는 그대로, write만 함수 사용)
DROP POLICY IF EXISTS "agent_personas_admin_write" ON public.agent_personas;
CREATE POLICY "agent_personas_admin_write" ON public.agent_personas
  FOR ALL USING (public.is_agent_admin())
  WITH CHECK (public.is_agent_admin());

-- 6. agent_subscriptions 정책 정정
DROP POLICY IF EXISTS "agent_subscriptions_read_own" ON public.agent_subscriptions;
CREATE POLICY "agent_subscriptions_read_own" ON public.agent_subscriptions FOR SELECT USING (
  user_id = auth.uid() OR public.is_agent_admin()
);

-- 끝
