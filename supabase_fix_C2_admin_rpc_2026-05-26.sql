-- ============================================================
-- ★★★ CRITICAL-2 정정 SQL (= 2026-05-26)
-- ============================================================
-- 사유: ADMIN_EMAIL = 'nextsunny@gmail.com' 평문이
--       index.html line 751, admin.html line 422·1028 클라이언트 JS에 노출.
--       → 피싱·스팸 타깃 + git 히스토리 영구 노출 + XSS 시 admin UI 강제 노출.
--
-- 정정 path:
--   (1) is_agent_admin() = JWT email 기반 (= 옛 supabase_RESTORE_ADMIN.sql 박혀있음)
--   (2) agent_is_admin_email(email) 신규 RPC = 다른 사용자 admin 체크용
--   (3) agent_list_users() = is_admin 필드 추가
--   (4) 클라이언트 HTML = ADMIN_EMAIL 평문 제거 → RPC 호출로 교체
--
-- 실행: Supabase Dashboard → SQL Editor → 본 SQL 전체 → Run
-- ============================================================

-- 1) is_agent_admin() = JWT 기반 (= 이미 박힘, 안전 재정의)
CREATE OR REPLACE FUNCTION public.is_agent_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT (auth.jwt() ->> 'email') = 'nextsunny@gmail.com';
$$;

GRANT EXECUTE ON FUNCTION public.is_agent_admin() TO authenticated, anon;

-- 2) agent_is_admin_email(_email) = 다른 사용자 admin 체크용 (= admin만 호출)
CREATE OR REPLACE FUNCTION public.agent_is_admin_email(_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- admin만 호출 가능 (= 다른 사용자가 admin email 목록 inference 차단)
  IF NOT public.is_agent_admin() THEN
    RAISE EXCEPTION 'Admin only' USING ERRCODE = '42501';
  END IF;

  RETURN LOWER(COALESCE(_email, '')) = 'nextsunny@gmail.com';
END;
$$;

GRANT EXECUTE ON FUNCTION public.agent_is_admin_email(TEXT) TO authenticated;

-- 3) agent_list_users() = is_admin 필드 추가
DROP FUNCTION IF EXISTS public.agent_list_users();

CREATE OR REPLACE FUNCTION public.agent_list_users()
RETURNS TABLE (
  user_id UUID,
  email TEXT,
  created_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ,
  preferred_company TEXT,
  plan TEXT,
  is_admin BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- admin만 호출 가능
  IF NOT public.is_agent_admin() THEN
    RAISE EXCEPTION 'Admin only' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    u.id AS user_id,
    u.email::TEXT,
    u.created_at,
    u.last_sign_in_at,
    (u.raw_user_meta_data->>'preferred_company')::TEXT AS preferred_company,
    COALESCE(s.plan, 'free')::TEXT AS plan,
    (LOWER(COALESCE(u.email, '')) = 'nextsunny@gmail.com') AS is_admin
  FROM auth.users u
  LEFT JOIN public.agent_subscriptions s ON s.user_id = u.id
  ORDER BY u.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.agent_list_users() TO authenticated;

-- ============================================================
-- 검증 (= 본 SQL 실행 후)
-- ============================================================

-- (a) 함수 3개 박혔는지
SELECT routine_name, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('is_agent_admin', 'agent_is_admin_email', 'agent_list_users')
ORDER BY routine_name;

-- (b) 본인 (대표님) 로그인 상태 = is_agent_admin() = TRUE 박힘 검증
SELECT public.is_agent_admin() AS my_admin_status;

-- (c) agent_list_users() = is_admin 컬럼 있는지 (= 첫 row만)
SELECT email, plan, is_admin FROM public.agent_list_users() LIMIT 5;

-- 끝
