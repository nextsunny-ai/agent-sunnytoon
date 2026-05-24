-- ============================================================
-- Agent Pro 1.1 — Backend Hardening
-- 파일: supabase_v1.1_backend_hardening_2026-05-26.sql
-- 실행: Supabase 콘솔 → SQL Editor → 전체 붙여넣기 → Run
-- 전제: supabase_schema.sql + supabase_subscription_trigger.sql
--       + supabase_fix_rls.sql 이미 적용 완료 상태
-- 갱신: 2026-05-26
-- ============================================================

-- ============================================================
-- 1. CHECK 제약 (데이터 무결성)
-- ============================================================

-- 1-A. agent_subscriptions.plan = 허용 값 5개
ALTER TABLE public.agent_subscriptions
  DROP CONSTRAINT IF EXISTS agent_subscriptions_plan_check;
ALTER TABLE public.agent_subscriptions
  ADD CONSTRAINT agent_subscriptions_plan_check
  CHECK (plan IN ('free', 'pro', 'studio', 'lifetime', 'banned'));

-- 1-B. agent_projects.status = 허용 값 4개
--      (agent_projects 테이블 미존재 시 에러 = 무시하고 넘기려면 DO $$ BEGIN ... EXCEPTION WHEN undefined_table 사용)
DO $$
BEGIN
  ALTER TABLE public.agent_projects
    DROP CONSTRAINT IF EXISTS agent_projects_status_check;
  ALTER TABLE public.agent_projects
    ADD CONSTRAINT agent_projects_status_check
    CHECK (status IN ('active', 'draft', 'archived', 'done'));
EXCEPTION
  WHEN undefined_table THEN
    RAISE NOTICE 'agent_projects 테이블 미존재 — status CHECK 스킵';
END;
$$;

-- ============================================================
-- 2. agent_messages 테이블 신설
--    (= saveMessageToDb silent fail 차단)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_messages (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_slug TEXT        NOT NULL,
  persona_id   TEXT        NOT NULL,
  role         TEXT        NOT NULL CHECK (role IN ('user', 'agent')),
  content      TEXT        NOT NULL,
  tokens_in    INTEGER,
  tokens_out   INTEGER,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_messages_user
  ON public.agent_messages(user_id);

CREATE INDEX IF NOT EXISTS idx_agent_messages_persona
  ON public.agent_messages(user_id, persona_id, created_at DESC);

ALTER TABLE public.agent_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agent_messages_own_rw" ON public.agent_messages;
CREATE POLICY "agent_messages_own_rw" ON public.agent_messages
  FOR ALL
  USING  (user_id = (SELECT auth.uid()) OR public.is_agent_admin())
  WITH CHECK (user_id = (SELECT auth.uid()) OR public.is_agent_admin());

-- ============================================================
-- 3. agent_learnings 테이블 신설
--    (= detectAndCaptureLearning silent fail 차단)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.agent_learnings (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  persona_id    TEXT        NOT NULL,
  category      TEXT,
  summary       TEXT        NOT NULL,
  source_msg_id UUID        REFERENCES public.agent_messages(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agent_learnings_user
  ON public.agent_learnings(user_id, persona_id);

ALTER TABLE public.agent_learnings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agent_learnings_own_rw" ON public.agent_learnings;
CREATE POLICY "agent_learnings_own_rw" ON public.agent_learnings
  FOR ALL
  USING  (user_id = (SELECT auth.uid()) OR public.is_agent_admin())
  WITH CHECK (user_id = (SELECT auth.uid()) OR public.is_agent_admin());

-- ============================================================
-- 4. 복합 인덱스 (RLS 성능 + 외부 100명 부담 대비)
-- ============================================================

-- is_agent_admin / is_agent_member_of = (user_id, role) 조회
CREATE INDEX IF NOT EXISTS idx_agent_memberships_user_role
  ON public.agent_memberships(user_id, role);

-- agent_company_personas = persona_id 단독 필터 자주 발생
CREATE INDEX IF NOT EXISTS idx_agent_company_personas_persona
  ON public.agent_company_personas(persona_id);

-- agent_subscriptions = admin 사용자 목록 plan 필터
CREATE INDEX IF NOT EXISTS idx_agent_subscriptions_plan
  ON public.agent_subscriptions(plan);

-- ============================================================
-- 5. owner 역할 추가 (Week 8~12 외부 회사 자율 운영 대비)
-- ============================================================

-- 5-A. agent_memberships.role = admin / owner / member 3단
ALTER TABLE public.agent_memberships
  DROP CONSTRAINT IF EXISTS agent_memberships_role_check;
ALTER TABLE public.agent_memberships
  ADD CONSTRAINT agent_memberships_role_check
  CHECK (role IN ('admin', 'owner', 'member'));

-- 5-B. owner 헬퍼 함수
CREATE OR REPLACE FUNCTION public.is_agent_owner_of(_company_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.agent_memberships
    WHERE user_id = auth.uid()
      AND company_id = _company_id
      AND role IN ('owner', 'admin')
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_agent_owner_of(UUID) TO authenticated;

-- 5-C. owner = 본인 회사 페르소나 카피본 UPDATE 가능
DROP POLICY IF EXISTS "agent_company_personas_owner_update" ON public.agent_company_personas;
CREATE POLICY "agent_company_personas_owner_update" ON public.agent_company_personas
  FOR UPDATE
  USING  (public.is_agent_owner_of(company_id))
  WITH CHECK (public.is_agent_owner_of(company_id));

-- ============================================================
-- 6. 검증 쿼리 (실행 후 결과 확인)
-- ============================================================

-- CHECK 제약 확인 (= 3행 이상: plan_check, status_check, role_check)
SELECT conname, conrelid::regclass AS "table"
FROM pg_constraint
WHERE conrelid IN (
  'public.agent_subscriptions'::regclass,
  'public.agent_memberships'::regclass
)
  AND contype = 'c'
ORDER BY conrelid::regclass::text, conname;

-- 인덱스 확인 (= agent_* 테이블 인덱스 전체)
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename LIKE 'agent_%'
ORDER BY tablename, indexname;

-- 신설 테이블 확인 (= 2행: agent_learnings, agent_messages)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('agent_messages', 'agent_learnings')
ORDER BY table_name;

-- 끝
